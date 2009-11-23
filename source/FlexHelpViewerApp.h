//
//  FlexHelpViewerApp.h
//  FlexHelpViewer
//
//  Created by Marc Bauer on 09.05.08.
//  Copyright 2008 nesiumdotcom. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "FlexDocsParser.h"
#import "AppDelegate.h"
#import "SignatureNode.h"
#import "ClassNode.h"
#import "FunctionNode.h"
#import "NSManagedObjectContext+Extensions.h"

@interface FlexHelpViewerApp : NSObject{
	IBOutlet NSWindow *m_importWindow;
	IBOutlet NSWindow *m_mainWindow;
	IBOutlet NSProgressIndicator *m_progressIndicator;
	IBOutlet NSTextField *m_progressLabel;

	IBOutlet NSTreeController *m_treeController;
	IBOutlet NSArrayController *m_contentsController;
	IBOutlet NSArrayController *m_signatureController;
	IBOutlet WebView *m_webView;
	IBOutlet NSTableView *m_classListTableView;
	
	IBOutlet NSSearchField *m_searchField;
	IBOutlet NSSegmentedCell *m_backForwardSegmentedCell;
	
	AppDelegate *m_appDelegate;
	FlexDocsParser *m_parser;
	NSMutableArray *m_history;
	NSUInteger m_historyIndex;
	AbstractNode *m_selectedNode;
}
- (IBAction)updateFilter:(id)sender;
- (IBAction)navigateInHistory:(id)sender;

- (void)setStatusMessage:(NSString *)message;
- (void)setProgressIsIndeterminate:(BOOL)bFlag;
- (void)setProgress:(double)progress;
- (void)setMaxProgressValue:(double)value;
- (void)parsingComplete;
- (void)loadPageForClassNode:(ClassNode *)aNode;
- (void)selectAndLoadClassNode:(ClassNode *)aNode;
- (void)recordHistoryItem:(ClassNode *)aNode;
- (void)updateBackForwardControl;
@end