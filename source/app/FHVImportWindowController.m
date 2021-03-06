//
//  FHVImportWindowController.m
//
//  Created by Marc Bauer on 02.02.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import "FHVImportWindowController.h"
#import "FHVDocParser.h"

@interface FHVImportWindowController (Private)
- (void)_updateToolbarSelection:(BOOL)animated;
- (void)_updateVisibleView:(BOOL)animated;
- (void)_parseDocsAtURL:(NSURL *)anURL withName:(NSString *)aName;
- (void)_selectController:(FHVAbstractImportPickerViewController *)aController 
	animated:(BOOL)animated;
- (void)_applySelectedViewControllerAttributes;
@end

#define kFHVImportWindowBottomBarHeight 40.0f

@implementation FHVImportWindowController

#pragma mark -
#pragma mark Initialization & Deallocation

- (id)initWithWindowNibName:(NSString *)windowNibName model:(FHVDocSetModel *)model{
	if (self = [super initWithWindowNibName:windowNibName]){
		m_importConnection = nil;
		m_model = model;
		m_parser = nil;
		m_pickerControllers = nil;
		m_selectedController = nil;
	}
	return self;
}

- (void)dealloc{
	[m_pickerControllers release];
	m_selectedController = nil;
	[super dealloc];
}



#pragma mark -
#pragma mark NSWindowController methods

- (void)windowDidLoad{
	m_pickerControllers = [[NSArray alloc] initWithObjects: 
		m_localPickerController, 
		m_remotePickerController, 
		m_presetsPickerController, 
		nil];
	for (FHVAbstractImportPickerViewController *controller in m_pickerControllers){
		[controller addObserver:self forKeyPath:@"valid" options:0 context:NULL];
		[controller addObserver:self forKeyPath:@"busy" options:0 context:NULL];
	}
	[self _updateToolbarSelection:NO];
}



#pragma mark -
#pragma mark IB Actions

- (IBAction)startImport:(id)sender{
	[self _parseDocsAtURL:[m_selectedController URL] withName:[m_selectedController docSetName]];
	[NSApp endSheet:self.window];
	[[self window] orderOut:self];
	[NSApp beginSheet:m_progressWindow 
		modalForWindow:[NSApp mainWindow] 
		modalDelegate:[NSApp delegate] 
		didEndSelector:NULL 
		contextInfo:NULL];
}

- (IBAction)cancel:(id)sender{
	if (m_parser){
		[self setStatusMessage:@"Cancelling ..."];
		[self setProgressIsIndeterminate:YES];
		[m_parser cancel];
		[sender setEnabled:NO];
		return;
	}
	[NSApp endSheet:self.window];
	[[self window] orderOut:self];
}

- (IBAction)toolbarItem_clicked:(NSToolbarItem *)sender{
	[self _updateVisibleView:YES];
}



#pragma mark -
#pragma mark Public methods

- (void)reset{
	if (!self.isWindowLoaded)
		return;
		
	for (FHVAbstractImportPickerViewController *controller in m_pickerControllers){
		[controller reset];
	}
	[m_cancelButton setEnabled:YES];
	[self setStatusMessage:@"Starting import ..."];
	[self setProgress:0.0];
	[self _updateToolbarSelection:NO];
}



#pragma mark -
#pragma mark KVO Notifications

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change 
	context:(void *)context{
	if (object != m_selectedController)
		return;
	[self _applySelectedViewControllerAttributes];
}



#pragma mark -
#pragma mark Private methods

- (void)_updateToolbarSelection:(BOOL)animated{
	NSString *clipboardContents = [[NSPasteboard generalPasteboard] 
		stringForType:NSStringPboardType];
	if ([clipboardContents nsm_isURL]){
		[m_remotePickerController setURLString:clipboardContents];
		[[self.window toolbar] setSelectedItemIdentifier:@"remote"];
	}else{
		if (![[self.window toolbar] selectedItemIdentifier])
			[[self.window toolbar] setSelectedItemIdentifier:@"local"];
	}
	[self _updateVisibleView:animated];
}

- (void)_updateVisibleView:(BOOL)animated{
	FHVAbstractImportPickerViewController *controller = nil;
	NSString *identifier = [[self.window toolbar] selectedItemIdentifier];
	if ([identifier isEqualToString:@"local"]){
		controller = m_localPickerController;
	}else if ([identifier isEqualToString:@"remote"]){
		controller = m_remotePickerController;
	}else if ([identifier isEqualToString:@"presets"]){
		controller = m_presetsPickerController;
	}
	[self _selectController:controller animated:animated];
}

- (void)_applySelectedViewControllerAttributes{
	if (m_selectedController.busy)
		[m_activityIndicator startAnimation:self];
	else
		[m_activityIndicator stopAnimation:self];
	[m_startImportButton setEnabled:m_selectedController.valid];
}

- (void)_parseDocsAtURL:(NSURL *)anURL withName:(NSString *)aName{
	m_importConnection = [[NSConnection alloc] init];
	[m_importConnection setRootObject:self];
	[m_importConnection registerName:@"com.nesium.FlexHelpViewer"];
	m_parser = [[FHVDocParser alloc] initWithURL:anURL 
		docSetName:aName];
	[NSThread detachNewThreadSelector:@selector(parse) toTarget:m_parser withObject:nil];
}

- (void)_selectController:(FHVAbstractImportPickerViewController *)aController 
	animated:(BOOL)animated{
	if (m_selectedController == aController)
		return;
	
	[m_selectedController.view removeFromSuperview];
	m_selectedController = aController;
	[self _applySelectedViewControllerAttributes];
	
	NSSize contentSize = [[self.window contentView] frame].size;
	contentSize.height = NSHeight(aController.view.frame) + kFHVImportWindowBottomBarHeight + 54.0f;
	[self.window nsm_resizeToFitContentSize:contentSize animated:animated];
	
	NSRect viewFrame = aController.view.frame;
	viewFrame.origin.y = kFHVImportWindowBottomBarHeight;
	viewFrame.size.width = NSWidth(self.window.frame);
	aController.view.frame = viewFrame;
	[self.window.contentView addSubview:aController.view positioned:NSWindowBelow 
		relativeTo:m_titleView];
	if (animated){
		[aController.view setAlphaValue:0.0f];
		[aController.view.animator setAlphaValue:1.0f];
	}
}



#pragma mark -
#pragma mark NSConnection proxy methods called by FlexDocsParser

- (void)setStatusMessage:(NSString *)message{
	if (m_parser.isCancelled) return;
	[m_statusLabel setStringValue:message];
}

- (void)setProgressIsIndeterminate:(BOOL)bFlag{
	if (m_parser.isCancelled) return;
	[m_progressIndicator setIndeterminate:bFlag];
	if (bFlag) [m_progressIndicator startAnimation:self];
}

- (void)setMaxProgressValue:(double)value{
	[m_progressIndicator setMaxValue:value];
}

- (void)setProgress:(double)progress{
	[m_progressIndicator setDoubleValue:progress];
}

- (void)parsingComplete:(NSError *)error{
	[NSApp endSheet:m_progressWindow];
	[m_progressWindow orderOut:self];
	[m_importConnection registerName:nil];
	[m_importConnection setRootObject:nil];
	[[m_importConnection receivePort] invalidate];
	[m_importConnection invalidate];
	[m_importConnection release];
	m_importConnection = nil;
	if (error){
		NSRunAlertPanel(@"Error creating DocSet", [error localizedDescription], 
			@"OK", nil, nil);
	}else{
		if (!m_parser.isCancelled)
			[m_model reloadDocSets];
	}
	[m_parser release];
	m_parser = nil;
}
@end