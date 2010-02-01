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
#import "FlexDocsParser.h"
#import "Constants.h"


@interface FHVAppDelegate : NSObject{
	FHVDocSetModel *m_docSetModel;
	FHVMainWindowController *m_mainWindowController;
	IBOutlet NSWindow *m_importWindow;
	IBOutlet NSWindow *m_newDocSetSheet;
	IBOutlet NSProgressIndicator *m_progressIndicator;
	IBOutlet NSTextField *m_progressLabel;
	NSConnection *m_initialLoadConnection;
	BOOL m_docSetModelReady;
}
- (NSString *)applicationSupportFolder;
@end