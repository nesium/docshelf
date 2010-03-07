//
//  FHVImportWindowController.m
//  EarthDocs
//
//  Created by Marc Bauer on 02.02.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import "FHVImportWindowController.h"
#import "FlexDocsParser.h"

@interface FHVImportWindowController (Private)
- (void)_updateToolbarSelection:(BOOL)animated;
- (void)_updateVisibleView:(BOOL)animated;
- (void)_parseDocsAtPath:(NSString *)aPath;
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
//	[self _parseDocsAtPath:m_sourcePath];
}

- (IBAction)cancel:(id)sender{
	if (m_parser){
		[self setStatusMessage:@"Cancelling ..."];
		[self setProgressIsIndeterminate:YES];
		[m_parser cancel];
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
		[m_progressIndicator startAnimation:self];
	else
		[m_progressIndicator stopAnimation:self];
	[m_startImportButton setEnabled:m_selectedController.valid];
}

- (void)_parseDocsAtPath:(NSString *)aPath{
	m_importConnection = [[NSConnection alloc] init];
	[m_importConnection setRootObject:self];
	[m_importConnection registerName:@"com.nesium.FlexHelpViewer"];
//	m_parser = [[FlexDocsParser alloc] initWithPath:aPath 
//		docSetName:m_nameTextField.stringValue];
//	[NSThread detachNewThreadSelector:@selector(parse) toTarget:m_parser withObject:nil];
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
//	NSRect cancelButtonFrame = m_cancelButton.frame;
//	NSRect startButtonFrame = m_startImportButton.frame;
//	if (startButtonVisible){
//		cancelButtonFrame.origin.x = NSMinX(startButtonFrame) - NSWidth(cancelButtonFrame) - 10.0f;
//	}else{
//		cancelButtonFrame.origin.x = NSMaxX(startButtonFrame) - NSWidth(cancelButtonFrame);
//	}
//	[m_startImportButton setHidden:!startButtonVisible];
//	if (animated)
//		[[m_cancelButton animator] setFrame:cancelButtonFrame];
//	else
//		m_cancelButton.frame = cancelButtonFrame;
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
	[NSApp endSheet:self.window];
	[[self window] orderOut:self];
	[m_importConnection registerName:nil];
	[m_importConnection setRootObject:nil];
	[[m_importConnection receivePort] invalidate];
	[m_importConnection invalidate];
	[m_importConnection release];
	m_importConnection = nil;
	if (error){
		NSRunAlertPanel(@"Error creating DocSet", @"The selected folder does not contain ASDoc files.", 
			@"OK", nil, nil);
	}else{
		if (!m_parser.isCancelled)
			[m_model reloadDocSets];
	}
	[m_parser release];
	m_parser = nil;
}
@end