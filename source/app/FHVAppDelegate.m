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

- (NSString *)applicationSupportFolder{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, 
		NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
    return [basePath stringByAppendingPathComponent:@"FlexHelpViewer"];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification{
	m_docSetModel = [[FHVDocSetModel alloc] initWithDocSetPath:[[self applicationSupportFolder] 
		stringByAppendingPathComponent:@"DocSets"]];
	m_mainWindowController = nil;
	[self _showMainWindow];
}

- (void)_showMainWindow{
	if (!m_mainWindowController)
		m_mainWindowController = [[FHVMainWindowController alloc] initWithWindowNibName:@"MainWindow" 
			docSetModel:m_docSetModel];
	[m_mainWindowController.window makeKeyAndOrderFront:self];
}
@end