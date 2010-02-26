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
- (void)_setSourcePath:(NSString *)aPath;
- (void)_updateImportButton;
- (void)_attachPickerView;
- (void)_attachProgressView;
- (void)_parseDocsAtPath:(NSString *)aPath;
- (void)_attachView:(NSView *)aView startButtonVisible:(BOOL)startButtonVisible 
	animated:(BOOL)animated;
@end

#define kFHVImportWindowBottomBarHeight 40.0f

@implementation FHVImportWindowController

- (id)initWithWindowNibName:(NSString *)windowNibName model:(FHVDocSetModel *)model{
	if (self = [super initWithWindowNibName:windowNibName]){
		m_sourcePath = nil;
		m_importConnection = nil;
		m_model = model;
	}
	return self;
}

- (void)windowDidLoad{
	[self _setSourcePath:nil];
	[m_nameTextField sendActionOn:NSAnyEventMask];
	[self _attachPickerView];
}

- (IBAction)chooseDirectory:(id)sender{
	NSOpenPanel *op = [NSOpenPanel openPanel];
	[op setAllowsMultipleSelection:NO];
	[op setCanChooseFiles:NO];
	[op setCanChooseDirectories:YES];
	[op beginSheetModalForWindow:self.window 
		completionHandler:^(NSInteger result){
			if (result == NSFileHandlingPanelCancelButton) return;
			[self _setSourcePath:[[[op URLs] objectAtIndex:0] path]];
		}];
}

- (IBAction)startImport:(id)sender{
	[self _parseDocsAtPath:m_sourcePath];
	[self _attachProgressView];
}

- (IBAction)cancel:(id)sender{
	[NSApp endSheet:self.window];
	[[self window] orderOut:self];
}

- (void)controlTextDidChange:(NSNotification *)aNotification{
	[self _updateImportButton];
}

- (void)reset{
	if (!self.isWindowLoaded)
		return;
	m_nameTextField.stringValue = @"";
	[self _setSourcePath:nil];
	[self _attachPickerView];
}



#pragma mark -
#pragma mark Private methods

- (void)_setSourcePath:(NSString *)aPath{
	[aPath retain];
	[m_sourcePath release];
	m_sourcePath = aPath;
	if (!aPath){
		[m_selectedFolderTextField setStringValue:@"No selection"];
		[m_selectedFolderTextField setTextColor:[NSColor lightGrayColor]];
		[m_selectedFolderTextField setToolTip:nil];
	}else{
		[m_selectedFolderTextField setStringValue:[NSString stringWithFormat:@"%@ - %@", 
			[m_sourcePath lastPathComponent], [m_sourcePath stringByDeletingLastPathComponent]]];
		[m_selectedFolderTextField setToolTip:m_sourcePath];
		[m_selectedFolderTextField setTextColor:[NSColor blackColor]];
	}
	[self _updateImportButton];
}

- (void)_parseDocsAtPath:(NSString *)aPath{
	m_importConnection = [[NSConnection alloc] init];
	[m_importConnection setRootObject:self];
	[m_importConnection registerName:@"com.nesium.FlexHelpViewer"];
	FlexDocsParser *parser = [[FlexDocsParser alloc] initWithPath:aPath 
		docSetName:m_nameTextField.stringValue];
	[NSThread detachNewThreadSelector:@selector(parse) toTarget:parser withObject:nil];
}

- (void)_updateImportButton{
	BOOL bFlag = m_sourcePath != nil && [[m_nameTextField stringValue] length] > 0;
	[m_startImportButton setEnabled:bFlag];
}

- (void)_attachPickerView{
	[self _attachView:m_pickerView startButtonVisible:YES animated:NO];
}

- (void)_attachProgressView{
	[self _attachView:m_progressView startButtonVisible:NO animated:YES];
}

- (void)_attachView:(NSView *)aView startButtonVisible:(BOOL)startButtonVisible 
	animated:(BOOL)animated{
	[m_progressView removeFromSuperview];
	[m_pickerView removeFromSuperview];
	
	NSSize contentSize = [[self.window contentView] frame].size;
	contentSize.height = NSHeight(aView.frame) + kFHVImportWindowBottomBarHeight;
	[self.window nsm_resizeToFitContentSize:contentSize animated:animated];
	
	NSRect viewFrame = aView.frame;
	viewFrame.origin.y = kFHVImportWindowBottomBarHeight;
	viewFrame.size.width = NSWidth(self.window.frame);
	aView.frame = viewFrame;
	[self.window.contentView addSubview:aView];
	if (animated){
		[aView setAlphaValue:0.0f];
		[aView.animator setAlphaValue:1.0f];
	}
	
	NSRect cancelButtonFrame = m_cancelButton.frame;
	NSRect startButtonFrame = m_startImportButton.frame;
	if (startButtonVisible){
		cancelButtonFrame.origin.x = NSMinX(startButtonFrame) - NSWidth(cancelButtonFrame);
	}else{
		cancelButtonFrame.origin.x = NSMaxX(startButtonFrame) - NSWidth(cancelButtonFrame);
	}
	[m_startImportButton setHidden:!startButtonVisible];
	if (animated)
		[[m_cancelButton animator] setFrame:cancelButtonFrame];
	else
		m_cancelButton.frame = cancelButtonFrame;
}



#pragma mark -
#pragma mark NSConnection proxy methods called by FlexDocsParser

- (void)setStatusMessage:(NSString *)message{
	[m_statusLabel setStringValue:message];
}

- (void)setProgressIsIndeterminate:(BOOL)bFlag{
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
	
	if (error){
		[NSApp presentError:error];
	}else{
		[m_model reloadDocSets];
	}
}
@end