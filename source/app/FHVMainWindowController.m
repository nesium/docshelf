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
- (void)_reloadOutlineView:(NSOutlineView *)anOutlineView;
- (void)_setDetailOutlineViewVisible:(BOOL)bFlag;
- (void)_serializeTreeState;
- (void)_restoreTreeState;
- (void)_serializeSplitViewPositions;
- (void)_restoreSplitViewPositions;
- (void)_updateFilterBar;
- (void)_recordHistoryItem:(NSURL *)anURL;
- (void)_updateBackForwardControl;
@end


@implementation FHVMainWindowController

#pragma mark -
#pragma mark Initialization & Deallocation

- (id)initWithWindowNibName:(NSString *)windowNibName docSetModel:(FHVDocSetModel *)docSetModel{
	if (self = [super initWithWindowNibName:windowNibName]){
		m_docSetModel = docSetModel;
		m_restoredAnchor = nil;
		m_history = [[NSMutableArray alloc] init];
		m_historyIndex = 0;
		[[NSNotificationCenter defaultCenter] 
			addObserver:self 
			selector:@selector(applicationWillTerminate:) 
			name:NSApplicationWillTerminateNotification 
			object:nil];
	}
	return self;
}

- (void)dealloc{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[m_docSetModel removeObserver:self forKeyPath:@"currentData"];
	[m_docSetModel removeObserver:self forKeyPath:@"selectionData"];
	[m_docSetModel removeObserver:self forKeyPath:@"detailData"];
	[m_docSetModel removeObserver:self forKeyPath:@"docSets"];
	[m_docSetModel removeObserver:self forKeyPath:@"selectionURL"];
	[m_innerSplitView release];
	[m_history release];
	[super dealloc];
}



#pragma mark -
#pragma mark Protected methods

- (void)windowDidLoad{
	// we remove the inner splitview from its parent eventually, so retain it for safety reasons
	[m_innerSplitView retain];
	[m_outlineView setIntercellSpacing:(NSSize){3, 0}];
	[m_selectionOutlineView setIntercellSpacing:(NSSize){3, 0}];
	
	[m_docSetModel addObserver:self forKeyPath:@"detailData" options:0 context:(void *)3];
	[m_docSetModel addObserver:self forKeyPath:@"detailSelectionAnchor" options:0 context:(void *)4];
	[m_docSetModel addObserver:self forKeyPath:@"docSets" options:0 context:(void *)5];
	m_detailSelectionAnchorBound = YES;
	[m_webView setResourceLoadDelegate:self];
	[m_webView setPolicyDelegate:self];
	[m_webView setFrameLoadDelegate:self];
	[m_webView setUIDelegate:self];
	[m_searchField setNextKeyView:m_outlineView];
	m_filterBar.startingColor = [NSColor colorWithCalibratedRed:0.816 green:0.816 blue:0.816 alpha:1.0];
	m_filterBar.endingColor = [NSColor colorWithCalibratedRed:0.912 green:0.912 blue:0.912 alpha:1.0];
	m_filterBar.borderColor = [NSColor colorWithCalibratedRed:0.665 green:0.665 blue:0.665 alpha:1.0];
	[self _updateFilterBar];
	
	[m_outlineView bind:@"content" toObject:m_docSetModel.firstLevelController 
		withKeyPath:@"arrangedObjects" options:nil];
	[[m_outlineView outlineTableColumn] bind:@"value" toObject:m_docSetModel.firstLevelController 
		withKeyPath:@"arrangedObjects.name" options:nil];
	[m_outlineView bind:@"selectionIndexPaths" toObject:m_docSetModel.firstLevelController 
		withKeyPath:@"selectionIndexPaths" options:nil];
	[m_outlineView setDelegate:self];
	[m_docSetModel.firstLevelController addObserver:self forKeyPath:@"content" options:0 
		context:(void *)1];
	
	[m_selectionOutlineView bind:@"content" toObject:m_docSetModel.secondLevelController 
		withKeyPath:@"arrangedObjects" options:nil];
	[[m_selectionOutlineView outlineTableColumn] bind:@"value" 
		toObject:m_docSetModel.secondLevelController withKeyPath:@"arrangedObjects.name" 
		options:nil];
	[m_selectionOutlineView bind:@"selectionIndexPaths" toObject:m_docSetModel.secondLevelController 
		withKeyPath:@"selectionIndexPaths" options:nil];
	[m_selectionOutlineView setDelegate:self];
	[m_docSetModel.secondLevelController addObserver:self forKeyPath:@"content" options:0 
		context:(void *)2];
		
	[self _restoreSplitViewPositions];
	[self _restoreTreeState];
	if ([[m_docSetModel.secondLevelController content] count] == 0)
		[self _setDetailOutlineViewVisible:NO];
	[m_docSetModel addObserver:self forKeyPath:@"selectionURL" options:0 context:(void *)6];
	if (m_docSetModel.selectionURL)
		[self _recordHistoryItem:m_docSetModel.selectionURL];
	else{
		[m_backForwardSegmentedCell setEnabled:NO forSegment:0];
		[m_backForwardSegmentedCell setEnabled:NO forSegment:1];
	}
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
		[self _setFilterBarVisible:NO];
		[m_docSetModel setSearchTerm:nil];
		return;
	}
	if (!m_docSetModel.inSearchMode){
		[self _serializeTreeState];
		[self _setFilterBarVisible:YES];
	}
	[m_docSetModel setSearchTerm:[m_searchField stringValue]];
}

- (IBAction)navigateInHistory:(id)sender{
	if ([(NSSegmentedControl *)sender selectedSegment] == 0){
		m_historyIndex--;
	}else{
		m_historyIndex++;
	}
	[m_docSetModel removeObserver:self forKeyPath:@"selectionURL"];
	[m_docSetModel selectItemWithURLInAnyDocSet:[m_history objectAtIndex:m_historyIndex]];
	[m_docSetModel addObserver:self forKeyPath:@"selectionURL" options:0 context:(void *)6];
	[self _updateBackForwardControl];
}



#pragma mark -
#pragma mark WindowDelegate methods

- (void)windowDidBecomeKey:(NSNotification *)notification{
	[self focusGlobalSearchField:nil];
}



#pragma mark -
#pragma mark Notifications

- (void)applicationWillTerminate:(NSNotification *)notification{
	[self _serializeTreeState];
	[self _serializeSplitViewPositions];
}



#pragma mark -
#pragma mark KVO Notifications

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object 
	change:(NSDictionary *)change context:(void *)context{
	if ((int)context == 1){
		[m_outlineView setIndentationPerLevel:m_docSetModel.inSearchMode ? 0 : 10];
		if (m_docSetModel.inSearchMode) [m_outlineView expandItem:nil expandChildren:YES];
		else [self _restoreTreeState];
	}else if ((int)context == 2){
		[self _setDetailOutlineViewVisible:[[m_docSetModel.secondLevelController content] count] > 0];
		[m_selectionOutlineView expandItem:nil expandChildren:YES];
	}else if ((int)context == 3){
		if (m_detailSelectionAnchorBound){
			[m_docSetModel removeObserver:self forKeyPath:@"detailSelectionAnchor"];
			m_detailSelectionAnchorBound = NO;
		}
		[[m_webView mainFrame] loadHTMLString:m_docSetModel.detailData  
			baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath]]];
	}else if ((int)context == 4){
		if (m_docSetModel.detailSelectionAnchor)
			[self _jumpToAnchor:m_docSetModel.detailSelectionAnchor];
	}else if ((int)context == 5){
		NSAssert([[NSThread currentThread] isMainThread], @"Not on main thread");
		[self _updateFilterBar];
	}else if ((int)context == 6){
		[self _recordHistoryItem:m_docSetModel.selectionURL];
	}
}



#pragma mark -
#pragma mark NSOutlineViewDelegate Protocol

static HeadlineCell *g_headlineCell = nil;

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell 
	forTableColumn:(NSTableColumn *)tableColumn item:(id)item{
	BOOL itemWantsHeaderCell = [self _itemWantsHeaderCell:[item representedObject]];
	if ([[[item representedObject] objectForKey:@"inherited"] boolValue] || itemWantsHeaderCell){
		NSInteger row = [outlineView rowForItem:item];
		[(HeadlineCell *)cell setDrawsTopBorder:(row > 0 && 
			![self _itemWantsHeaderCell:[[outlineView itemAtRow:row - 1] representedObject]])];
		[cell setTextColor:[NSColor colorWithCalibratedRed:0.459 green:0.459 blue:0.459 alpha:1.0]];
	}else{
		[cell setTextColor:[NSColor blackColor]];
	}
	if (!itemWantsHeaderCell){
		[cell setImage:[m_docSetModel imageForItem:[item representedObject]]];
	}
}

- (NSCell *)outlineView:(NSOutlineView *)outlineView 
	dataCellForTableColumn:(NSTableColumn *)tableColumn item:(id)item{
	if (![self _itemWantsHeaderCell:[item representedObject]])
		return [tableColumn dataCell];
	if (g_headlineCell == nil){
		g_headlineCell = [[HeadlineCell alloc] init];
		[g_headlineCell setFont:[NSFont boldSystemFontOfSize:11.0]];
		[g_headlineCell setLineBreakMode:NSLineBreakByTruncatingTail];
	}
	return g_headlineCell;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item{
	return ![self _itemWantsHeaderCell:[item representedObject]];
}

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item{
	return [self _itemWantsHeaderCell:[item representedObject]] ? 20.0 : 19.0;
}

- (void)outlineViewArrowLeftKeyWasPressed:(NSOutlineView *)outlineView{
	if (outlineView == m_selectionOutlineView){
		[[self window] makeFirstResponder:m_outlineView];
	}
}

- (void)outlineViewArrowRightKeyWasPressed:(NSOutlineView *)outlineView{
	// make sure that the detailoutlineview is visible
	if (outlineView == m_outlineView && [m_innerSplitView superview] != nil){
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

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldExpandItem:(id)item{
	[m_docSetModel loadChildrenOfPackage:[item representedObject]];
	return YES;
}



#pragma mark -
#pragma mark WebResourceLoadDelegate Prototcol

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
	if ([[[request URL] scheme] isEqualToString:@"fhelpv"]){
		[m_docSetModel selectItemWithURLInCurrentDocSet:[request URL]];
		[listener ignore];
		return;
	}else if ([[[request URL] scheme] hasPrefix:@"http"]){
		[[NSWorkspace sharedWorkspace] openURL:[request URL]];
		[listener ignore];
		return;
	}
	[listener use];
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame{
	NSString *anchor = nil;
	if (m_restoredAnchor){
		anchor = [[m_restoredAnchor copy] autorelease];
		[m_restoredAnchor release];
		m_restoredAnchor = nil;
	}
	if (!anchor){
		anchor = m_docSetModel.detailSelectionAnchor;
	}
	if (anchor){
		[self _jumpToAnchor:anchor];
	}
	[m_docSetModel addObserver:self forKeyPath:@"detailSelectionAnchor" options:0 context:(void *)4];
	m_detailSelectionAnchorBound = YES;
}



#pragma mark -
#pragma mark WebUIDelegate methods

- (NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element 
	defaultMenuItems:(NSArray *)defaultMenuItems{
	NSMutableArray *items = [NSMutableArray array];
	for (NSMenuItem *item in defaultMenuItems){
		if ([item tag] == WebMenuItemTagReload)
			continue;
		[items addObject:item];
	}
	return [[items copy] autorelease];
}



#pragma mark -
#pragma mark FilterbarDelegate methods

- (NSArray *)filterbar:(Filterbar *)filterBar itemIdentifiersForGroup:(NSString *)groupIdentifier{
	if ([groupIdentifier isEqualToString:@"matchingMode"]){
		return [NSArray arrayWithObjects:@"Contains", @"Prefix", @"Exact", nil];
	}else if ([groupIdentifier isEqualToString:@"docSetsList"]){
		NSMutableArray *indexes = [NSMutableArray array];
		for (FHVDocSet *docSet in m_docSetModel.docSets){
			[indexes addObject:[[NSNumber numberWithInt:docSet.index] stringValue]];
		}
		return indexes;
	}
	return nil;
}

- (NSString *)filterbar:(Filterbar *)filterBar labelForItemIdentifier:(NSString *)itemIdentifier 
	groupIdentifier:(NSString *)groupIdentifier{
	if ([groupIdentifier isEqualToString:@"docSetsList"]){
		for (FHVDocSet *docSet in m_docSetModel.docSets)
			if (docSet.index == [itemIdentifier intValue]){
				return docSet.name;
			}
		return @"ERROR";
	}
	return itemIdentifier;
}

- (void)filterbar:(Filterbar *)filterBar selectedStateChanged:(BOOL)selected 
	fromItem:(NSString *)itemIdentifier groupIdentifier:(NSString *)groupIdentifier{
	if ([groupIdentifier isEqualToString:@"matchingMode"]){
		if (selected) m_docSetModel.searchMode = [self _searchModeForIdentifier:itemIdentifier];
	}else if ([groupIdentifier isEqualToString:@"docSetsList"]){
		[m_docSetModel setDocSetWithIndex:[itemIdentifier intValue] inSearchIncluded:selected];
	}
}

- (BOOL)filterbar:(Filterbar *)filterBar hasMultipleSelection:(NSString *)groupIdentifier{
	if ([groupIdentifier isEqualToString:@"docSetsList"]){
		return YES;
	}
	return NO;
}



#pragma mark -
#pragma mark Private methods

- (void)_jumpToAnchor:(NSString *)anchor{
	WebScriptObject *window = [m_webView windowScriptObject];
	[window evaluateWebScript:[NSString stringWithFormat:@"location.href='#%@';", anchor]];
}

- (BOOL)_itemWantsHeaderCell:(NSDictionary *)item{
	return [[item objectForKey:@"root"] boolValue];
}

- (void)_setFilterBarVisible:(BOOL)bFlag{
	if (bFlag == ([m_filterBar superview] != nil))
		return;
	NSRect contentViewBounds = [[self.window contentView] bounds];
	NSRect filterBarBounds = [m_filterBar bounds];
	if (bFlag){
		[m_outerSplitView setFrame:(NSRect){-1, 0, NSWidth(contentViewBounds) + 1, 
			NSHeight(contentViewBounds) - NSHeight(filterBarBounds)}];
		[m_filterBar setFrame:(NSRect){0, NSHeight(contentViewBounds) - NSHeight(filterBarBounds), 
			NSWidth(contentViewBounds), NSHeight(filterBarBounds)}];
		[[self.window contentView] addSubview:m_filterBar];
	}else{
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

- (void)_setDetailOutlineViewVisible:(BOOL)bFlag{
	if ((bFlag && [m_webView superview] != m_outerSplitView) || 
		(!bFlag && ![m_innerSplitView superview])){
		return;
	}
	if (!bFlag){
		[self _serializeSplitViewPositions];
		m_webView.frame = m_innerSplitView.frame;
		[m_innerSplitView removeFromSuperview];
		[m_outerSplitView addSubview:m_webView];
		[self _restoreSplitViewPositions];
	}else{
		[self _serializeSplitViewPositions];
		m_innerSplitView.frame = m_webView.frame;
		[m_webView removeFromSuperview];
		[m_outerSplitView addSubview:m_innerSplitView];
		[m_innerSplitView addSubview:m_webView];
		[self _restoreSplitViewPositions];
	}
}

- (void)_updateFilterBar{
	[m_filterBar clearItems];
	[m_filterBar addGroup:@"matchingMode"];
	[m_filterBar addSeparator];
	[m_filterBar addGroup:@"docSetsList"];
	[m_filterBar selectItem:[self _identifierForSearchMode:m_docSetModel.searchMode] 
		inGroup:@"matchingMode" selected:YES];
	NSMutableArray *docSetsListSelection = [NSMutableArray array];
	for (FHVDocSet *docSet in m_docSetModel.docSets){
		if (docSet.inSearchIncluded) 
			[docSetsListSelection addObject:[[NSNumber numberWithInt:docSet.index] stringValue]];
	}
	[m_filterBar selectItems:docSetsListSelection inGroup:@"docSetsList" selected:YES];
}

- (void)_serializeSplitViewPositions{
	// detailoutlineview is visible
	if ([m_innerSplitView superview]){
		[[NSUserDefaults standardUserDefaults] setObject:NSStringFromRect(m_webView.frame) 
			forKey:@"FHVWebViewFrame"];
		NDCLog(@"save %@", NSStringFromRect(m_webView.frame));
		[[NSUserDefaults standardUserDefaults] setObject:NSStringFromRect(m_innerSplitView.frame) 
			forKey:@"FHVInnerSplitViewFrame"];
	}else{
		[[NSUserDefaults standardUserDefaults] setObject:NSStringFromRect(m_webView.frame) 
			forKey:@"FHVInnerSplitViewFrame"];
	}
}

- (void)_restoreSplitViewPositions{
	NSString *innerSplitViewFrame = [[NSUserDefaults standardUserDefaults] 
		objectForKey:@"FHVInnerSplitViewFrame"];
	NSString *webViewFrame = [[NSUserDefaults standardUserDefaults] 
		objectForKey:@"FHVWebViewFrame"];
	NDCLog(@"%@", webViewFrame);
	// first launch
	if (!innerSplitViewFrame)
		return;
	[m_outerSplitView setPosition:(NSWidth(m_outerSplitView.frame) - 
		NSWidth(NSRectFromString(innerSplitViewFrame)) - [m_outerSplitView dividerThickness]) 
		ofDividerAtIndex:0];
	if ([m_webView superview] == m_innerSplitView){
		[m_innerSplitView setPosition:(NSWidth(m_innerSplitView.frame) - 
		 	NSWidth(NSRectFromString(webViewFrame)) - [m_innerSplitView dividerThickness]) 
			ofDividerAtIndex:0];
	}
}

- (void)_serializeTreeState{
	if (m_docSetModel.inSearchMode)
		return;

	NSInteger count = [m_outlineView numberOfRows];
	NSMutableDictionary *tree = [NSMutableDictionary dictionary];
	for (NSInteger i = 0; i < count; i++){
		id item = [m_outlineView itemAtRow:i];
		NSInteger level = [m_outlineView levelForRow:i];
		if (![m_outlineView isItemExpanded:item] || level == -1 || level > 2)
			continue;
		item = [item representedObject];
		if (level == 0){
			NSString *docSetId = [m_docSetModel docSetForItem:item].docSetId;
			[tree setObject:[NSMutableArray array] forKey:docSetId];
		}else{
			id parentItem = [m_docSetModel docSetItemForItem:item];
			NSString *docSetId = [m_docSetModel docSetForItem:item].docSetId;
			NSInteger index = [[parentItem objectForKey:@"children"] indexOfObject:item];
			NSMutableArray *arr = [tree objectForKey:docSetId];
			[arr addObject:[NSNumber numberWithInt:index]];
		}
	}
	
	NSMutableArray *selection = [NSMutableArray array];
	if ([[m_docSetModel.firstLevelController selectedObjects] count]){
		id selectedItem = [[m_docSetModel.firstLevelController selectedObjects] objectAtIndex:0];
		NSString *docSetId = [m_docSetModel docSetForItem:selectedItem].docSetId;
		[selection addObject:docSetId];
		[selection addObject:[[m_docSetModel.firstLevelController selectionIndexPath] allIndexes]];
		
		if ([[m_docSetModel.secondLevelController selectedObjects] count]){
			selectedItem = [[m_docSetModel.secondLevelController selectedObjects] objectAtIndex:0];
			[selection addObject:[[m_docSetModel.secondLevelController selectionIndexPath] 
				allIndexes]];
		}
	}
	
	[[NSUserDefaults standardUserDefaults] setObject:tree forKey:@"FHVTreeState"];
	[[NSUserDefaults standardUserDefaults] setObject:selection forKey:@"FHVSelection"];
}

- (void)_restoreTreeState{
	NSDictionary *tree = [[NSUserDefaults standardUserDefaults] objectForKey:@"FHVTreeState"];
	for (NSString *key in tree){
		id item = [m_docSetModel docSetItemForDocSetId:key];
		[m_outlineView expandItem:[m_docSetModel.firstLevelController nodeForObject:item]];
		NSArray *children = [item objectForKey:@"children"];
		NSArray *arr = [tree objectForKey:key];
		for (NSNumber *index in arr){
			[m_outlineView expandItem:[m_docSetModel.firstLevelController nodeForObject:
				[children objectAtIndex:[index intValue]]]];
		}
	}
	
	NSArray *selection = [[NSUserDefaults standardUserDefaults] objectForKey:@"FHVSelection"];
	if (![selection count])
		return;
	
	id item = [m_docSetModel docSetItemForDocSetId:[selection objectAtIndex:0]];
	if (!item) return; // docset could be deleted
	[m_docSetModel.firstLevelController setSelectionIndexPath:
		[NSIndexPath indexPathWithIndexes:[selection objectAtIndex:1]]];
	
	if ([selection count] < 3)
		return;
	[m_docSetModel.secondLevelController setSelectionIndexPath:
		[NSIndexPath indexPathWithIndexes:[selection objectAtIndex:2]]];
}

- (void)_recordHistoryItem:(NSURL *)anURL{
	if ([m_history count] && m_historyIndex < [m_history count] - 1){
		[m_history removeObjectsInRange:(NSRange){m_historyIndex + 1, 
			[m_history count] - m_historyIndex - 1}];
	}
	if (![[m_history lastObject] isEqual:anURL]){
		[m_history addObject:anURL];
		m_historyIndex = [m_history count] - 1;
	}
	[self _updateBackForwardControl];
}

- (void)_updateBackForwardControl{
	[m_backForwardSegmentedCell setEnabled:(m_historyIndex > 0) forSegment:0];
	[m_backForwardSegmentedCell setEnabled:([m_history count] && m_historyIndex < [m_history count] - 1) 
		forSegment:1];
}
@end