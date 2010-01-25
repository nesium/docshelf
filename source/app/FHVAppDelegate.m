//
//  AppDelegate.m
//  FlexHelpViewer
//
//  Created by Marc Bauer on 17.05.08.
//  Copyright 2008 nesiumdotcom. All rights reserved.
//

#import "FHVAppDelegate.h"

@interface FHVAppDelegate (Private)
- (void)_showMainWindow;
@end


@implementation FHVAppDelegate

+ (void)initialize{
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	[dict setObject:[NSNumber numberWithInt:kFHVDocSetSearchModePrefix] forKey:@"FHVDocSetSearchMode"];
	[dict setObject:[NSNumber numberWithBool:YES] forKey:@"FHVDocSetShowsInheritedSignatures"];
	[[NSUserDefaults standardUserDefaults] registerDefaults:dict];
}

- (id)init{
	if (self = [super init]){
		m_mainWindowController = nil;
		m_initialLoadConnection = [[NSConnection alloc] init];
		[m_initialLoadConnection registerName:@"com.nesium.FlexDocs.InitialLoadConnection"];
		[m_initialLoadConnection setRootObject:self];
		m_docSetModelReady = NO;
		m_docSetModel = [[FHVDocSetModel alloc] initWithDocSetPath:[[self applicationSupportFolder] 
			stringByAppendingPathComponent:@"DocSets"]];
		[[NSNotificationCenter defaultCenter] 
			addObserver:self 
			selector:@selector(_docSetModel_initialLoadDone:) 
			name:@"FHVDocSetModelInitialLoadDone" 
			object:m_docSetModel];
		[m_docSetModel loadDocSets];
	}
	return self;
}

- (NSString *)applicationSupportFolder{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, 
		NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
    return [basePath stringByAppendingPathComponent:@"FlexHelpViewer"];
}

- (IBAction)addDocSet:(id)sender{
	NSOpenPanel *op = [NSOpenPanel openPanel];
	[op setAllowsMultipleSelection:NO];
	[op setCanChooseFiles:NO];
	[op setCanChooseDirectories:YES];
	[op beginSheetModalForWindow:m_mainWindowController.window 
		completionHandler:^(NSInteger result){
			if (result == NSFileHandlingPanelCancelButton) return;
			[self _parseDocsAtPath:[[[op URLs] objectAtIndex:0] path]];
		}];
}

- (IBAction)toggleInheritedSignaturesVisibility:(id)sender{
	m_docSetModel.showsInheritedSignatures = !m_docSetModel.showsInheritedSignatures;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification{
	if (!m_docSetModelReady){
		[m_importWindow center];
		[m_importWindow makeKeyAndOrderFront:self];
	}
}

- (void)_showMainWindow{
	if (!m_mainWindowController)
		m_mainWindowController = [[FHVMainWindowController alloc] initWithWindowNibName:@"MainWindow" 
			docSetModel:m_docSetModel];
	[m_mainWindowController.window makeKeyAndOrderFront:self];
}

- (void)_parseDocsAtPath:(NSString *)aPath{
	NSConnection *conn = [NSConnection defaultConnection];
	[conn setRootObject:self];
	[conn registerName:@"com.nesium.FlexHelpViewer"];
	[m_importWindow makeKeyAndOrderFront:self];
	[m_importWindow center];
	FlexDocsParser *parser = [[FlexDocsParser alloc] initWithPath:aPath];
	[NSThread detachNewThreadSelector:@selector(parse) toTarget:parser withObject:nil];
}



#pragma mark -
#pragma mark NSConnection proxy methods called by FlexDocsParser

- (void)setStatusMessage:(NSString *)message{
	[m_progressLabel setStringValue:message];
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

- (void)parsingComplete{
	[m_importWindow orderOut:self];
}



#pragma mark -
#pragma mark Notifications

- (void)_docSetModel_initialLoadDone:(NSNotification *)notification{
	m_docSetModelReady = YES;
	[m_importWindow orderOut:self];
	[m_initialLoadConnection release];
	[self _showMainWindow];
}
@end