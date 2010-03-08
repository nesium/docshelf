//
//  AppDelegate.h
//  FlexHelpViewer
//
//  Created by Marc Bauer on 17.05.08.
//  Copyright 2008 nesiumdotcom. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FHVDocSetModel.h"
#import "FHVMainWindowController.h"
#import "FHVImportWindowController.h"
#import "FHVUpdatePreferencesViewController.h"
#import "NSMPreferencesWindowController.h"
#import "FHVConstants.h"


@interface FHVAppDelegate : NSObject{
	FHVDocSetModel *m_docSetModel;
	FHVMainWindowController *m_mainWindowController;
	FHVImportWindowController *m_importWindowController;
	NSMPreferencesWindowController *m_prefsWindowController;
}
- (IBAction)addDocSet:(id)sender;
- (IBAction)showPreferences:(id)sender;
@end