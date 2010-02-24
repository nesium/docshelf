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
@end

#define kFHVImportWindowBottomBarHeight 40.0f

@implementation FHVImportWindowController

- (id)initWithWindowNibName:(NSString *)windowNibName{
	if (self = [super initWithWindowNibName:windowNibName]){
		m_sourcePath = nil;
		m_importConnection = nil;
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
	NSRect frame = m_pickerView.frame;
	frame.origin.y = kFHVImportWindowBottomBarHeight;
	m_pickerView.frame = frame;
	[self.window.contentView addSubview:m_pickerView];
}

- (void)_attachProgressView{
	[m_pickerView removeFromSuperview];

	NSRect windowFrame = self.window.frame;
	CGFloat chromeHeight = NSHeight(windowFrame) - NSHeight([[self.window contentView] frame]);
	CGFloat newHeight = NSHeight(m_progressView.frame) + chromeHeight + 
		kFHVImportWindowBottomBarHeight;
	windowFrame.origin.y -= newHeight - NSHeight(windowFrame);
	windowFrame.size.height = newHeight;
	[[self.window animator] setFrame:windowFrame display:YES];
	
	NSRect viewFrame = m_progressView.frame;
	viewFrame.origin.y = kFHVImportWindowBottomBarHeight;
	viewFrame.size.width = NSWidth(windowFrame);
	m_progressView.frame = viewFrame;
	[m_progressView setAlphaValue:0.0f];
	[self.window.contentView addSubview:m_progressView];
	[m_progressView.animator setAlphaValue:1.0f];
	
	NSRect cancelButtonFrame = m_cancelButton.frame;
	NSRect startButtonFrame = m_startImportButton.frame;
	cancelButtonFrame.origin.x = NSMaxX(startButtonFrame) - NSWidth(cancelButtonFrame);
	[m_startImportButton setHidden:YES];
	[[m_cancelButton animator] setFrame:cancelButtonFrame];
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
	}
}
@end