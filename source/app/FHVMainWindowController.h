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
#import "Filterbar.h"
#import "FHVConstants.h"
#import "NSIndexPath+NSMAdditions.h"


@interface FHVMainWindowController : NSWindowController <NSOutlineViewDelegate>{
	IBOutlet NSOutlineView *m_outlineView;
	IBOutlet NSOutlineView *m_selectionOutlineView;
	IBOutlet WebView *m_webView;
	IBOutlet NSSearchField *m_searchField;
	IBOutlet Filterbar *m_filterBar;
	IBOutlet NSSplitView *m_outerSplitView;
	IBOutlet NSSplitView *m_innerSplitView;
	IBOutlet NSSegmentedCell *m_backForwardSegmentedCell;
	IBOutlet NSView *m_noDocSetsView;
	IBOutlet NSButton *m_addDocSetButton;
	
	BOOL m_detailSelectionAnchorBound;
	NSTimeInterval m_lastOutlineViewUpdateTime;
	FHVDocSetModel *m_docSetModel;
	NSString *m_restoredAnchor;
	NSUInteger m_historyIndex;
	NSMutableArray *m_history;
}
- (id)initWithWindowNibName:(NSString *)windowNibName docSetModel:(FHVDocSetModel *)docSetModel;
- (IBAction)updateFilter:(id)sender;
- (IBAction)navigateInHistory:(id)sender;
- (void)saveTreeState;
@end