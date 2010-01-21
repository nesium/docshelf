//
//  MainWindowController.m
//  FlexHelpViewer
//
//  Created by Marc Bauer on 19.01.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import "FHVMainWindowController.h"

@interface FHVMainWindowController (NSOutlineViewDataSourceProtocol)
- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item;
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item;
- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item;
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn 
	byItem:(id)item;
@end

@interface FHVMainWindowController (Private)
- (void)_jumpToAnchor:(NSString *)anchor;
@end


@implementation FHVMainWindowController

#pragma mark -
#pragma mark Initialization & Deallocation

- (id)initWithWindowNibName:(NSString *)windowNibName docSetModel:(FHVDocSetModel *)docSetModel{
	if (self = [super initWithWindowNibName:windowNibName]){
		m_docSetModel = docSetModel;
	}
	return self;
}

- (void)dealloc{
	[m_docSetModel removeObserver:self forKeyPath:@"currentData"];
	[m_docSetModel removeObserver:self forKeyPath:@"selectionData"];
	[super dealloc];
}



#pragma mark -
#pragma mark Protected methods

- (void)windowDidLoad{
	[m_docSetModel addObserver:self forKeyPath:@"currentData" options:0 context:(void *)1];
	[m_docSetModel addObserver:self forKeyPath:@"selectionData" options:0 context:(void *)2];
	[m_docSetModel addObserver:self forKeyPath:@"detailData" options:0 context:(void *)3];
	[m_outlineView expandItem:nil expandChildren:YES];
	[m_webView setResourceLoadDelegate:self];
	[m_webView setPolicyDelegate:self];
	[m_searchField setNextKeyView:m_outlineView];
}



#pragma mark -
#pragma mark First Responder methods

- (void)focusGlobalSearchField:(id)sender{
	[self.window makeFirstResponder:m_searchField];
}



#pragma mark -
#pragma mark IB Actions

- (IBAction)updateFilter:(id)sender{
	if (![[m_searchField stringValue] length]){
		[m_docSetModel setFilterString:nil];
		return;
	}
	[m_docSetModel setFilterString:[NSString stringWithFormat:@"%%%@%%", 
		[m_searchField stringValue]]];
}



#pragma mark -
#pragma WindowDelegate methods

- (void)windowDidBecomeKey:(NSNotification *)notification{
	[self focusGlobalSearchField:nil];
}



#pragma mark -
#pragma mark KVO Notifications

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object 
	change:(NSDictionary *)change context:(void *)context{
	if ((int)context == 1){
		[self performSelector:@selector(_reloadOutlineView:) withObject:m_outlineView afterDelay:0.0];
	}else if ((int)context == 2){
		[self performSelector:@selector(_reloadOutlineView:) withObject:m_selectionOutlineView 
			afterDelay:0.0];
	}else if ((int)context == 3){
		[[m_webView mainFrame] loadHTMLString:m_docSetModel.detailData  
			baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath]]];
	}
}



#pragma mark -
#pragma mark NSOutlineViewDataSource Protocol

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item{
	if (item == nil){
		return outlineView == m_outlineView 
			? [m_docSetModel.currentData objectAtIndex:index] 
			: [m_docSetModel.selectionData objectAtIndex:index];
	}
	return [[item objectForKey:@"children"] objectAtIndex:index];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item{
	return [self outlineView:outlineView numberOfChildrenOfItem:item] > 0;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item{
	if (item == nil){
		return outlineView == m_outlineView 
			? [m_docSetModel.currentData count] 
			: [m_docSetModel.selectionData count];
	}
	return [[item objectForKey:@"children"] count];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn 
	byItem:(id)item{
	if (m_docSetModel.inSearchMode && outlineView == m_outlineView){
		if ([[item objectForKey:@"itemType"] intValue] == kItemTypeSignature){
			return [NSString stringWithFormat:@"%@ (%@)", [item objectForKey:@"name"], 
				[item objectForKey:@"parentName"]];
		}
	}
	return [item objectForKey:@"name"];
}



#pragma mark -
#pragma mark NSOutlineViewDelegate Protocol

static HeadlineCell *g_headlineCell = nil;

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell 
	forTableColumn:(NSTableColumn *)tableColumn item:(id)item{
	if ([[item objectForKey:@"inherited"] boolValue] || [cell isMemberOfClass:[HeadlineCell class]]){
		[cell setTextColor:[NSColor colorWithCalibratedRed:0.455 green:0.455 
			blue:0.455 alpha:1.000]];
	}else{
		[cell setTextColor:[NSColor blackColor]];
	}
}

- (NSCell *)outlineView:(NSOutlineView *)outlineView 
	dataCellForTableColumn:(NSTableColumn *)tableColumn item:(id)item{
	if ([[item objectForKey:@"children"] count] < 1)
		return [tableColumn dataCell];
	
	if (g_headlineCell == nil){
		g_headlineCell = [[HeadlineCell alloc] init];
		[g_headlineCell setFont: [NSFont boldSystemFontOfSize: 11.0]];
	}
	return g_headlineCell;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item{
	return [[item objectForKey:@"children"] count] < 1;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification{
	if ([notification object] == m_outlineView){
		[m_docSetModel selectFirstLevelItem:[m_outlineView itemAtRow:[m_outlineView selectedRow]]];
	}else if ([notification object] == m_selectionOutlineView){
		[self _jumpToAnchor:[m_docSetModel anchorForItem:[m_selectionOutlineView 
			itemAtRow:[m_selectionOutlineView selectedRow]]]];
	}
}



#pragma mark -
#pragma WebResourceLoadDelegate Prototcol

- (NSURLRequest *)webView:(WebView *)sender resource:(id)identifier 
	willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse 
	fromDataSource:(WebDataSource *)dataSource{
	NSString *filename = [[[request URL] resourceSpecifier] lastPathComponent];
	NSString *pathExtension = [filename pathExtension];
	NSArray *imageExtensions = [NSArray arrayWithObjects:@"gif", @"jpg", @"png", nil];
	if ([filename isEqualToString:@"inherit-arrow.gif"]){
		return [NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] 
			pathForResource:@"inherit-arrow" ofType:@"gif"]]];
	}
	if ([[request URL] isFileURL] && [filename length] == 40 && 
		[imageExtensions containsObject:pathExtension]){
		NSURL *imageURL = [m_docSetModel URLForImageWithName:[[[request URL] resourceSpecifier] 
			lastPathComponent]];
		return [NSURLRequest requestWithURL:imageURL];
	}
	return request;
}

- (void)webView:(WebView *)webView decidePolicyForNavigationAction:(NSDictionary *)actionInformation 
	request:(NSURLRequest *)request frame:(WebFrame *)frame 
	decisionListener:(id <WebPolicyDecisionListener>)listener{
	NSLog(@"%@", [request URL]);
	[listener use];
}



#pragma mark -
#pragma mark Private methods

- (void)_jumpToAnchor:(NSString *)anchor{
	WebScriptObject *window = [m_webView windowScriptObject];
	[window evaluateWebScript:[NSString stringWithFormat:@"location.href='#%@';", anchor]];
}

- (void)_reloadOutlineView:(NSOutlineView *)anOutlineView{
	[anOutlineView reloadData];
	[anOutlineView expandItem:nil expandChildren:YES];
}
@end