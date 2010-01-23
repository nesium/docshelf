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
- (BOOL)_itemWantsHeaderCell:(NSDictionary *)item;
- (void)_updateSelectionOutlineViewSelectionIfNeeded;
- (void)_setFilterBarVisible:(BOOL)bFlag;
- (NSString *)_identifierForSearchMode:(FHVDocSetSearchMode)mode;
- (FHVDocSetSearchMode)_searchModeForIdentifier:(NSString *)identifier;
@end


@implementation FHVMainWindowController

#pragma mark -
#pragma mark Initialization & Deallocation

- (id)initWithWindowNibName:(NSString *)windowNibName docSetModel:(FHVDocSetModel *)docSetModel{
	if (self = [super initWithWindowNibName:windowNibName]){
		m_docSetModel = docSetModel;
		m_outlineViewUpdateDelayed = NO;
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
	[m_webView setFrameLoadDelegate:self];
	[m_searchField setNextKeyView:m_outlineView];
	
	m_filterBar.startingColor = [NSColor colorWithCalibratedRed:0.816 green:0.816 blue:0.816 alpha:1.0];
	m_filterBar.endingColor = [NSColor colorWithCalibratedRed:0.912 green:0.912 blue:0.912 alpha:1.0];
	m_filterBar.borderColor = [NSColor colorWithCalibratedRed:0.665 green:0.665 blue:0.665 alpha:1.0];
	[m_filterBar addGroup:@"matchingMode"];
	[m_filterBar addSeparator];
	[m_filterBar selectItem:[self _identifierForSearchMode:m_docSetModel.searchMode] 
		inGroup:@"matchingMode" selected:YES];
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
		[m_docSetModel setSearchTerm:nil];
		return;
	}
	[m_docSetModel setSearchTerm:[m_searchField stringValue]];
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
		if (m_outlineViewUpdateDelayed) return;
		[self performSelector:@selector(_reloadOutlineView:) withObject:m_outlineView afterDelay:1.0/20.0];
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
	BOOL itemWantsHeaderCell = [self _itemWantsHeaderCell:item];
	if ([[item objectForKey:@"inherited"] boolValue] || itemWantsHeaderCell){
		[cell setTextColor:[NSColor colorWithCalibratedRed:0.459 green:0.459 blue:0.459 alpha:1.0]];
	}else{
		[cell setTextColor:[NSColor blackColor]];
	}
	if (!itemWantsHeaderCell){
		[cell setImage:[m_docSetModel imageForItem:item]];
	}
}

- (NSCell *)outlineView:(NSOutlineView *)outlineView 
	dataCellForTableColumn:(NSTableColumn *)tableColumn item:(id)item{
	if (![self _itemWantsHeaderCell:item])
		return [tableColumn dataCell];
	if (g_headlineCell == nil){
		g_headlineCell = [[HeadlineCell alloc] init];
		[g_headlineCell setFont:[NSFont boldSystemFontOfSize:11.0]];
		[g_headlineCell setLineBreakMode:NSLineBreakByTruncatingTail];
	}
	return g_headlineCell;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item{
	return ![self _itemWantsHeaderCell:item];
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification{
	if ([notification object] == m_outlineView){
		NSArray *oldSelectionData = [m_docSetModel.selectionData retain];
		[m_docSetModel selectFirstLevelItem:[m_outlineView itemAtRow:[m_outlineView selectedRow]]];
		if (m_docSetModel.selectionData == oldSelectionData){
			[self _updateSelectionOutlineViewSelectionIfNeeded];
		}
		[oldSelectionData release];
	}else if ([notification object] == m_selectionOutlineView){
		[self _jumpToAnchor:[m_docSetModel anchorForItem:[m_selectionOutlineView 
			itemAtRow:[m_selectionOutlineView selectedRow]]]];
	}
}

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item{
	return [self _itemWantsHeaderCell:item] ? 20.0 : 17.0;
}

- (void)outlineViewArrowLeftKeyWasPressed:(NSOutlineView *)outlineView{
	if (outlineView == m_selectionOutlineView){
		[[self window] makeFirstResponder:m_outlineView];
	}
}

- (void)outlineViewArrowRightKeyWasPressed:(NSOutlineView *)outlineView{
	if (outlineView == m_outlineView){
		[[self window] makeFirstResponder:m_selectionOutlineView];
	}
}

- (void)outlineViewDidBecomeFirstResponder:(NSOutlineView *)outlineView{
	if ([outlineView selectedRow] != -1)
		return;
	for (int i = 0; i < [outlineView numberOfRows]; i++){
		if ([self outlineView:outlineView shouldSelectItem:[outlineView itemAtRow:i]]){
			[outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:i] byExtendingSelection:NO];
			return;
		}
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

- (void)webView:(WebView *)sender didClearWindowObject:(WebScriptObject *)windowObject 
	forFrame:(WebFrame *)frame{
	NSLog(@"anchor: %@", m_docSetModel.detailSelectionAnchor);
	if (m_docSetModel.detailSelectionAnchor){
		[self _jumpToAnchor:m_docSetModel.detailSelectionAnchor];
	}
}



#pragma mark -
#pragma mark FilterbarDelegate methods

- (NSArray *)filterbar:(Filterbar *)filterBar itemIdentifiersForGroup:(NSString *)groupIdentifier{
	if ([groupIdentifier isEqualToString:@"matchingMode"]){
		return [NSArray arrayWithObjects:@"Contains", @"Prefix", @"Exact", nil];
	}
	return nil;
}

- (NSString *)filterbar:(Filterbar *)filterBar labelForItemIdentifier:(NSString *)itemIdentifier 
	groupIdentifier:(NSString *)groupIdentifier{
	return itemIdentifier;
}

- (void)filterbar:(Filterbar *)filterBar selectedStateChanged:(BOOL)selected 
	fromItem:(NSString *)itemIdentifier groupIdentifier:(NSString *)groupIdentifier{
	if (selected) m_docSetModel.searchMode = [self _searchModeForIdentifier:itemIdentifier];
}



#pragma mark -
#pragma mark Private methods

- (void)_jumpToAnchor:(NSString *)anchor{
	WebScriptObject *window = [m_webView windowScriptObject];
	[window evaluateWebScript:[NSString stringWithFormat:@"location.href='#%@';", anchor]];
}

- (void)_reloadOutlineView:(NSOutlineView *)anOutlineView{
	if (anOutlineView == m_selectionOutlineView)
		[anOutlineView deselectAll:nil];
	else
		m_outlineViewUpdateDelayed = NO;
	[anOutlineView reloadData];
	[anOutlineView expandItem:nil expandChildren:YES];
	if (anOutlineView == m_selectionOutlineView)
		[self _updateSelectionOutlineViewSelectionIfNeeded];
	else
		[self _setFilterBarVisible:m_docSetModel.inSearchMode];
}

- (BOOL)_itemWantsHeaderCell:(NSDictionary *)item{
	return [item objectForKey:@"children"] != nil || 
		[[item objectForKey:@"itemType"] intValue] == kItemTypePackage;
}

- (void)_updateSelectionOutlineViewSelectionIfNeeded{
	if (m_docSetModel.detailSelectionIndex != -1){
		[m_selectionOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:
			m_docSetModel.detailSelectionIndex] byExtendingSelection:NO];
		[m_selectionOutlineView scrollRowToVisible:m_docSetModel.detailSelectionIndex];
	}
}

- (void)_setFilterBarVisible:(BOOL)bFlag{
	if (bFlag == ([m_filterBar superview] != nil))
		return;
	NSRect contentViewBounds = [[self.window contentView] bounds];
	NSRect filterBarBounds = [m_filterBar bounds];
	if (bFlag){
		NSLog(@"add filter bar");
		[m_outerSplitView setFrame:(NSRect){-1, 0, NSWidth(contentViewBounds) + 1, 
			NSHeight(contentViewBounds) - NSHeight(filterBarBounds) + 1}];
		[m_filterBar setFrame:(NSRect){0, NSHeight(contentViewBounds) - NSHeight(filterBarBounds), 
			NSWidth(contentViewBounds), NSHeight(filterBarBounds)}];
		[[self.window contentView] addSubview:m_filterBar];
	}else{
		NSLog(@"remove filterbar");
		[m_filterBar removeFromSuperview];
		[m_outerSplitView setFrame:NSInsetRect(contentViewBounds, -1, -1)];
	}
}

- (NSString *)_identifierForSearchMode:(FHVDocSetSearchMode)mode{
	if (mode == kFHVDocSetSearchModeContains)
		return @"Contains";
	else if (mode == kFHVDocSetSearchModePrefix)
		return @"Prefix";
	else
		return @"Exact";
}

- (FHVDocSetSearchMode)_searchModeForIdentifier:(NSString *)identifier{
	if ([identifier isEqualToString:@"Contains"])
		return kFHVDocSetSearchModeContains;
	else if ([identifier isEqualToString:@"Prefix"])
		return kFHVDocSetSearchModePrefix;
	else
		return kFHVDocSetSearchModeExact;
}
@end