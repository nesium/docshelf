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
		m_importWindowController = nil;
		m_docSetModel = [[FHVDocSetModel alloc] initWithDocSetPath:[[self applicationSupportFolder] 
			stringByAppendingPathComponent:@"DocSets"]];
		[m_docSetModel loadDocSets];
		[self _showMainWindow];
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
	if (!m_importWindowController){
		m_importWindowController = [[FHVImportWindowController alloc] 
			initWithWindowNibName:@"ImportWindow"];
	}
	[NSApp beginSheet:m_importWindowController.window 
		modalForWindow:m_mainWindowController.window 
		modalDelegate:self 
		didEndSelector:NULL 
		contextInfo:NULL];
}

- (IBAction)toggleInheritedSignaturesVisibility:(id)sender{
	m_docSetModel.showsInheritedSignatures = !m_docSetModel.showsInheritedSignatures;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification{
}

- (void)_showMainWindow{
	if (!m_mainWindowController)
		m_mainWindowController = [[FHVMainWindowController alloc] initWithWindowNibName:@"MainWindow" 
			docSetModel:m_docSetModel];
	[m_mainWindowController.window makeKeyAndOrderFront:self];
}
@end