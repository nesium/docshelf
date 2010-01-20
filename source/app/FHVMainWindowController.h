//
//  MainWindowController.h
//  FlexHelpViewer
//
//  Created by Marc Bauer on 19.01.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FHVDocSetModel.h"
#import "HeadlineCell.h"


@interface FHVMainWindowController : NSWindowController{
	IBOutlet NSOutlineView *m_outlineView;
	FHVDocSetModel *m_docSetModel;
}
- (id)initWithWindowNibName:(NSString *)windowNibName docSetModel:(FHVDocSetModel *)docSetModel;
@end