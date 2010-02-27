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
- (void)_serializeTreeState;
- (void)_restoreTreeState;
@end


@implementation FHVMainWindowController

#pragma mark -
#pragma mark Initialization & Deallocation

- (id)initWithWindowNibName:(NSString *)windowNibName docSetModel:(FHVDocSetModel *)docSetModel{
	if (self = [super initWithWindowNibName:windowNibName]){
		m_docSetModel = docSetModel;
		m_restoredAnchor = nil;
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
	[super dealloc];
}



#pragma mark -
#pragma mark Protected methods

- (void)windowDidLoad{
	NDCLog(@"WINDOW DID LOAD");
	[m_outlineView setIntercellSpacing:(NSSize){3, 0}];
	[m_selectionOutlineView setIntercellSpacing:(NSSize){3, 0}];
	
	[m_docSetModel addObserver:self forKeyPath:@"detailData" options:0 context:(void *)3];
	[m_docSetModel addObserver:self forKeyPath:@"detailSelectionAnchor" options:0 context:(void *)4];
	[m_webView setResourceLoadDelegate:self];
	[m_webView setPolicyDelegate:self];
	[m_webView setFrameLoadDelegate:self];
	[m_searchField setNextKeyView:m_outlineView];
	
	m_filterBar.startingColor = [NSColor colorWithCalibratedRed:0.816 green:0.816 blue:0.816 alpha:1.0];
	m_filterBar.endingColor = [NSColor colorWithCalibratedRed:0.912 green:0.912 blue:0.912 alpha:1.0];
	m_filterBar.borderColor = [NSColor colorWithCalibratedRed:0.665 green:0.665 blue:0.665 alpha:1.0];
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
//	[self _restoreTreeState];
	
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
#pragma mark WindowDelegate methods

- (void)windowDidBecomeKey:(NSNotification *)notification{
	[self focusGlobalSearchField:nil];
}



#pragma mark -
#pragma mark Notifications

- (void)applicationWillTerminate:(NSNotification *)notification{
	//[self _serializeTreeState];
}



#pragma mark -
#pragma mark KVO Notifications

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object 
	change:(NSDictionary *)change context:(void *)context{
	if ((int)context == 1){
		[m_outlineView setIndentationPerLevel:m_docSetModel.inSearchMode ? 0 : 10];
		if (m_docSetModel.inSearchMode) [m_outlineView expandItem:nil expandChildren:YES];
	}else if ((int)context == 2){
		[m_selectionOutlineView expandItem:nil expandChildren:YES];	
	}else if ((int)context == 3){
		[m_docSetModel removeObserver:self forKeyPath:@"detailSelectionAnchor"];
		[[m_webView mainFrame] loadHTMLString:m_docSetModel.detailData  
			baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath]]];
	}else if ((int)context == 4){
		[self _jumpToAnchor:m_docSetModel.detailSelectionAnchor];
	}
}



#pragma mark -
#pragma mark NSOutlineViewDelegate Protocol

static HeadlineCell *g_headlineCell = nil;

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell 
	forTableColumn:(NSTableColumn *)tableColumn item:(id)item{
	BOOL itemWantsHeaderCell = [self _itemWantsHeaderCell:[item representedObject]];
	if ([[[item representedObject] objectForKey:@"inherited"] boolValue] || itemWantsHeaderCell){
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
	[listener use];
}

- (void)webView:(WebView *)sender didClearWindowObject:(WebScriptObject *)windowObject 
	forFrame:(WebFrame *)frame{
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
}



#pragma mark -
#pragma mark FilterbarDelegate methods

- (NSArray *)filterbar:(Filterbar *)filterBar itemIdentifiersForGroup:(NSString *)groupIdentifier{
	if ([groupIdentifier isEqualToString:@"matchingMode"]){
		return [NSArray arrayWithObjects:@"Contains", @"Prefix", @"Exact", nil];
	}else if ([groupIdentifier isEqualToString:@"docSetsList"]){
		NSMutableArray *indexes = [NSMutableArray array];
		for (FHVDocSet *docSet in m_docSetModel.docSets)
			[indexes addObject:[[NSNumber numberWithInt:docSet.index] stringValue]];
		return indexes;
	}
	return nil;
}

- (NSString *)filterbar:(Filterbar *)filterBar labelForItemIdentifier:(NSString *)itemIdentifier 
	groupIdentifier:(NSString *)groupIdentifier{
	if ([groupIdentifier isEqualToString:@"docSetsList"]){
		for (FHVDocSet *docSet in m_docSetModel.docSets)
			if (docSet.index == [itemIdentifier intValue])
				return docSet.name;
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
			NSHeight(contentViewBounds) - NSHeight(filterBarBounds) + 1}];
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

- (void)_serializeTreeState{
	NSInteger count = [m_outlineView numberOfRows];
	NSMutableDictionary *tree = [NSMutableDictionary dictionary];
	for (NSInteger i = 0; i < count; i++){
		id item = [m_outlineView itemAtRow:i];
		NSInteger level = [m_outlineView levelForRow:i];
		if (![m_outlineView isItemExpanded:item] || level == -1 || level > 2)
			continue;
		if (level == 0){
			NSString *docSetId = [m_docSetModel docSetForItem:item].docSetId;
			[tree setObject:[NSMutableArray array] forKey:docSetId];
		}else {
			id parentItem = [m_docSetModel docSetItemForItem:item];
			NSString *docSetId = [m_docSetModel docSetForItem:item].docSetId;
			NSInteger index = [[parentItem objectForKey:@"children"] indexOfObject:item];
			NSMutableArray *arr = [tree objectForKey:docSetId];
			[arr addObject:[NSNumber numberWithInt:index]];
		}
	}
	
	NSArray *selection = [NSArray arrayWithObjects:
		[NSNumber numberWithInt:[m_outlineView selectedRow]], 
		[NSNumber numberWithInt:[m_selectionOutlineView selectedRow]], 
		nil];
	
	[[NSUserDefaults standardUserDefaults] setObject:tree forKey:@"FHVTreeState"];
	[[NSUserDefaults standardUserDefaults] setObject:selection forKey:@"FHVSelection"];
}

- (void)_restoreTreeState{
	NSDictionary *tree = [[NSUserDefaults standardUserDefaults] objectForKey:@"FHVTreeState"];
	for (NSString *key in tree){
		id item = [m_docSetModel docSetItemForDocSetId:key];
		[m_outlineView expandItem:item];
		NSArray *children = [item objectForKey:@"children"];
		NSArray *arr = [tree objectForKey:key];
		for (NSNumber *index in arr){
			[m_outlineView expandItem:[children objectAtIndex:[index intValue]]];
		}
	}
	NSArray *selection = [[NSUserDefaults standardUserDefaults] objectForKey:@"FHVSelection"];
	NSInteger firstLevelSelection = [[selection objectAtIndex:0] intValue];
	if (selection == nil || firstLevelSelection == -1) return;
	[m_outlineView setDelegate:nil];
	[m_outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:firstLevelSelection] 
		byExtendingSelection:NO];
	[m_outlineView scrollRowToVisible:firstLevelSelection];
	[m_outlineView setDelegate:self];
	[m_docSetModel selectFirstLevelItem:[m_outlineView itemAtRow:firstLevelSelection]];
	
	NSInteger secondLevelSelection = [[selection objectAtIndex:1] intValue];
	if (secondLevelSelection == -1) return;
	[m_selectionOutlineView reloadData];
	[m_selectionOutlineView expandItem:nil expandChildren:YES];
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[m_selectionOutlineView setDelegate:nil];
	[m_selectionOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:secondLevelSelection] 
		byExtendingSelection:NO];
	[m_selectionOutlineView scrollRowToVisible:secondLevelSelection];
	[m_selectionOutlineView setDelegate:self];
	m_restoredAnchor = [[m_docSetModel anchorForItem:[m_selectionOutlineView 
		itemAtRow:secondLevelSelection]] retain];
}
@end