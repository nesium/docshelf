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

#pragma mark -
#pragma mark Initialization & Deallocation

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
		m_docSetModel = [[FHVDocSetModel alloc] initWithDocSetPath:FHVDocSetsFolder()];
		[m_docSetModel loadDocSets];
		[self _showMainWindow];
	}
	return self;
}

- (void)awakeFromNib{
	NSArray *items = [[[[NSApp mainMenu] itemAtIndex:0] submenu] itemArray];
	for (NSMenuItem *item in items){
		[item setTitle:[[item title] stringByReplacingOccurrencesOfString:@"NewApplication" 
			withString:[[[NSBundle mainBundle] infoDictionary] 
				objectForKey:(NSString *)kCFBundleNameKey]]];
	}
}



#pragma mark -
#pragma mark IBActions

- (IBAction)addDocSet:(id)sender{
	if (!m_importWindowController){
		m_importWindowController = [[FHVImportWindowController alloc] 
			initWithWindowNibName:@"ImportWindow" model:m_docSetModel];
	}
	[m_importWindowController reset];
	[NSApp beginSheet:m_importWindowController.window 
		modalForWindow:m_mainWindowController.window 
		modalDelegate:self 
		didEndSelector:NULL 
		contextInfo:NULL];
}

- (IBAction)toggleInheritedSignaturesVisibility:(id)sender{
	m_docSetModel.showsInheritedSignatures = !m_docSetModel.showsInheritedSignatures;
}

- (IBAction)showPreferences:(id)sender{
	if (!m_prefsWindowController){
		NSWindow *window = [[NSWindow alloc] initWithContentRect:(NSRect){0, 0, 100, 100} 
			styleMask:(NSTitledWindowMask | NSClosableWindowMask) 
			backing:NSBackingStoreBuffered defer:YES];
		m_prefsWindowController = [[NSMPreferencesWindowController alloc] initWithWindow:window];
		m_prefsWindowController.toolbarIdentifier = @"FHVPreferencesToolbar";
		m_prefsWindowController.windowAutosaveName = @"FHVPreferencesWindowOrigin";
		FHVUpdatePreferencesViewController *updatePrefsController = 
			[[FHVUpdatePreferencesViewController alloc] initWithNibName:@"UpdatePreferences" 
				bundle:nil];
		[m_prefsWindowController addPrefPaneWithController:updatePrefsController 
			icon:[NSImage imageNamed:@"reload.tiff"]];
		[window release];
	}
	[m_prefsWindowController showWindow:self];
}

- (IBAction)reportBug:(id)sender{
	[[NSWorkspace sharedWorkspace] openURL:
		[NSURL URLWithString:@"http://bugs.nesium.net/projects/earthdoc/issues/new"]];
}



#pragma mark -
#pragma mark NSApplicationDelegate methods

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification{
	if(getenv("NSZombieEnabled") || getenv("NSAutoreleaseFreedObjectCheckEnabled")){
		NDCLog(@"NSZombieEnabled/NSAutoreleaseFreedObjectCheckEnabled enabled!");
	}
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication{
	return YES;
}



#pragma mark -
#pragma mark Private methods

- (void)_showMainWindow{
	if (!m_mainWindowController)
		m_mainWindowController = [[FHVMainWindowController alloc] initWithWindowNibName:@"MainWindow" 
			docSetModel:m_docSetModel];
	[m_mainWindowController.window makeKeyAndOrderFront:self];
}
@end