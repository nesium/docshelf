//
//  MainWindowController.h
//  FlexHelpViewer
//
//  Created by Marc Bauer on 19.01.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "FHVDocSetModel.h"
#import "HeadlineCell.h"


@interface FHVMainWindowController : NSWindowController{
	IBOutlet NSOutlineView *m_outlineView;
	IBOutlet NSOutlineView *m_selectionOutlineView;
	IBOutlet WebView *m_webView;
	IBOutlet NSSearchField *m_searchField;
	FHVDocSetModel *m_docSetModel;
}
- (id)initWithWindowNibName:(NSString *)windowNibName docSetModel:(FHVDocSetModel *)docSetModel;
- (IBAction)updateFilter:(id)sender;
@end