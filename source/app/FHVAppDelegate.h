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


@interface FHVAppDelegate : NSObject{
	FHVDocSetModel *m_docSetModel;
	FHVMainWindowController *m_mainWindowController;
}
- (NSString *)applicationSupportFolder;
@end