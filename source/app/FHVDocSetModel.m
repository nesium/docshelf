//
//  FHVDocSetModel.m
//  FlexHelpViewer
//
//  Created by Marc Bauer on 19.01.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import "FHVDocSetModel.h"


@interface FHVDocSetModel (Private)
- (void)_loadDocSets;
- (NSString *)_classHTMLStringWithClassNode:(NSDictionary *)classNode 
	signatures:(NSArray *)signatures;
- (NSString *)_globalFunctionHTMLWithNode:(NSDictionary *)node;
- (NSString *)_globalConstantHTMLWithNode:(NSDictionary *)node;
- (void)_setHTMLBody:(NSString *)body usingTemplate:(NSString *)templateName;
@end


static BOOL g_initialLoad = YES;

@implementation FHVDocSetModel

@synthesize detailData=m_detailData, 
			showsInheritedSignatures=m_showsInheritedSignatures, 
			inSearchMode=m_inSearchMode, 
			detailSelectionIndex=m_detailSelectionIndex, 
			detailSelectionAnchor=m_detailSelectionAnchor, 
			searchMode=m_searchMode, 
			docSets=m_docSets, 
			firstLevelController=m_firstLevelController, 
			secondLevelController=m_secondLevelController;

#pragma mark -
#pragma mark Initialization & Deallocation

- (id)initWithDocSetPath:(NSString *)path{
	if (self = [super init]){
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		m_path = [path copy];
		m_docSets = nil;
		m_detailData = nil;
		m_selectedItem = nil;
		m_showsInheritedSignatures = [[defaults objectForKey:@"FHVDocSetShowsInheritedSignatures"] 
			boolValue];
		m_inSearchMode = NO;
		m_searchResults = nil;
		m_lastSearchTerm = nil;
		m_detailSelectionIndex = -1;
		m_detailSelectionAnchor = nil;
		m_searchMode = [[defaults objectForKey:@"FHVDocSetSearchMode"] intValue];
		[self _loadDocSets];
		m_searchWorkerConnection = [[NSConnection alloc] init];
		[m_searchWorkerConnection setRootObject:self];
		[m_searchWorkerConnection registerName:@"com.nesium.FlexHelpViewer.searchWorkerConnection"];
		m_searchWorker = [[FHVSearchWorker alloc] initWithDocSets:m_docSets];
		
		m_firstLevelController = [[NSTreeController alloc] init];
		[m_firstLevelController setChildrenKeyPath:@"children"];
		[m_firstLevelController setLeafKeyPath:@"leaf"];
		[m_firstLevelController setAvoidsEmptySelection:NO];
		[m_firstLevelController addObserver:self forKeyPath:@"selectionIndexPaths" 
			options:0 context:NULL];
		m_secondLevelController = [[NSTreeController alloc] init];
		[m_secondLevelController setChildrenKeyPath:@"children"];
		[m_secondLevelController setAvoidsEmptySelection:NO];
		[m_secondLevelController addObserver:self forKeyPath:@"selectionIndexPaths" 
			options:0 context:NULL];
	}
	return self;
}

- (void)dealloc{
	[m_mainData release];
	[m_searchResults release];
	[m_searchWorker release];
	[m_searchWorkerConnection release];
	[m_path release];
	[m_docSets release];
	[super dealloc];
}



#pragma mark -
#pragma mark Public methods

- (void)loadDocSets{
	NSArray *docSets = m_docSets;
	NSMutableArray *allDocSets = [NSMutableArray array];
	for (FHVDocSet *docSet in docSets){
		NSMutableArray *docSetPackages = [[docSet allPackages] mutableCopy];
		NSDictionary *docSetItem = [NSDictionary dictionaryWithObjectsAndKeys: 
			docSet.name, @"name", 
			docSetPackages, @"children", 
			[NSNumber numberWithBool:NO], @"leaf", 
			[NSNumber numberWithInt:docSet.index], @"docSetId", 
			[NSNumber numberWithBool:YES], @"root", 
			nil];
		[allDocSets addObject:docSetItem];
		[docSetPackages release];
	}
	[m_mainData release];
	m_mainData = [allDocSets retain];
	[m_firstLevelController setContent:m_mainData];
	if (g_initialLoad){
		g_initialLoad = NO;
		[m_searchWorker start];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"FHVDocSetModelInitialLoadDone" 
			object:self];
	}
}

- (void)reloadDocSets{
	[m_firstLevelController setContent:nil];
	[self willChangeValueForKey:@"docSets"];
	[m_docSets release];
	m_docSets = nil;
	[self didChangeValueForKey:@"docSets"];
	[m_mainData release];
	m_mainData = nil;

	[self selectFirstLevelItem:nil];

	[self _loadDocSets];
	[self loadDocSets];
	[m_searchWorker setDocSets:m_docSets];
}

- (void)selectFirstLevelItem:(id)item{
	m_detailSelectionIndex = -1;
	
	NSNumber *itemType = [item objectForKey:@"itemType"];
	if (!itemType || [itemType intValue] == kItemTypePackage){
		return;
	}
	
	// @TODO handle the case where item could be a package, or where the parent of the item could 
	// be a package
	NSNumber *idToSelect = nil;
	FHVDocSet *docSet = [self docSetForItem:item];
	// a signature was selected from the search results
	if ([itemType intValue] == kItemTypeSignature){
		FHVSignatureParentType sigParentType = [[item objectForKey:@"parentType"] intValue];
		FHVSignatureType sigType = [[item objectForKey:@"type"] intValue];
		// global signatures
		if (sigParentType == kSigParentTypePackage){
			if (sigType == kSigTypeFunction){
				[self _setHTMLBody:[self _globalFunctionHTMLWithNode:[docSet 
					signatureWithId:[item objectForKey:@"dbId"]]] usingTemplate:@"class"];
			}else if (sigType == kSigTypeConstant){
				[self _setHTMLBody:[self _globalConstantHTMLWithNode:[docSet 
					signatureWithId:[item objectForKey:@"dbId"]]] usingTemplate:@"class"];
			}	
			[item retain];
			[m_selectedItem release];
			m_selectedItem = item;
			[m_secondLevelController setContent:nil];
			return;
		}else{
			idToSelect = [item objectForKey:@"dbId"];
			item = [docSet classWithId:[item objectForKey:@"parentDbId"]];
		}	
	// the visibility of inherited signatures was toggled and we want to preserve the selection
	}else if (item == m_selectedItem){
		if ([[m_secondLevelController selectedObjects] count] > 0){
			NSDictionary *selectedItem = [[m_secondLevelController selectedObjects] objectAtIndex:0];
			idToSelect = [selectedItem objectForKey:@"dbId"];
		}
	}
	
	[item retain];
	[m_selectedItem release];
	m_selectedItem = item;
	
	NSNumber *selectedId = [item objectForKey:@"dbId"];
	NSArray *sigs = [docSet signaturesWithParentId:selectedId 
		includeInherited:m_showsInheritedSignatures];
	NSMutableArray *methods = nil;
	NSMutableArray *properties = nil;
	NSMutableArray *constants = nil;
	NSMutableArray *events = nil;
	NSMutableArray *constructor = nil;
	for (NSDictionary *sig in sigs){
		NSNumber *type = [sig objectForKey:@"type"];
		if ([type intValue] == kSigTypeFunction && 
			[[sig objectForKey:@"name"] isEqualToString:[item objectForKey:@"name"]]){
			if (!constructor) constructor = [NSMutableArray array];
			[constructor addObject:sig];
			continue;
		}
		switch ([type intValue]){
			case kSigTypeFunction:
				if (!methods) methods = [NSMutableArray array];
				[methods addObject:sig];
				break;
			case kSigTypeVariable:
				if (!properties) properties = [NSMutableArray array];
				[properties addObject:sig];
				break;
			case kSigTypeConstant:
				if (!constants) constants = [NSMutableArray array];
				[constants addObject:sig];
				break;
			case kSigTypeEvent:
				if (!events) events = [NSMutableArray array];
				[events addObject:sig];
				break;
		}
	}
	NSMutableArray *mergedSigs = [NSMutableArray array];
	if (constructor){
		[mergedSigs addObject:[NSDictionary dictionaryWithObjectsAndKeys: 
			@"Constructor", @"name", 
			[NSNumber numberWithBool:YES], @"root", 
			constructor, @"children", 
			nil]];
	}
	if (constants){
		[mergedSigs addObject:[NSDictionary dictionaryWithObjectsAndKeys: 
			@"Constants", @"name", 
			[NSNumber numberWithBool:YES], @"root", 
			constants, @"children", 
			nil]];
	}
	if (properties){
		[mergedSigs addObject:[NSDictionary dictionaryWithObjectsAndKeys: 
			@"Properties", @"name", 
			[NSNumber numberWithBool:YES], @"root", 
			properties, @"children", 
			nil]];
	}
	if (methods){
		[mergedSigs addObject:[NSDictionary dictionaryWithObjectsAndKeys: 
			@"Methods", @"name", 
			[NSNumber numberWithBool:YES], @"root", 
			methods, @"children", 
			nil]];
	}
	if (events){
		[mergedSigs addObject:[NSDictionary dictionaryWithObjectsAndKeys: 
			@"Events", @"name", 
			[NSNumber numberWithBool:YES], @"root", 
			events, @"children", 
			nil]];
	}
	
	[m_secondLevelController setContent:mergedSigs];
	
	[self _setHTMLBody:[self _classHTMLStringWithClassNode:[docSet classWithId:selectedId] 
		signatures:mergedSigs] usingTemplate:@"class"];
	
	if (idToSelect){
		NSDictionary *itemToSelect = nil;
		for (NSDictionary *sig in sigs){
			if ([[sig objectForKey:@"dbId"] isEqualToNumber:idToSelect]){
				itemToSelect = sig;
				break;
			}
		}
		[m_secondLevelController setSelectedObject:itemToSelect];
	}
}

- (NSURL *)URLForImageWithName:(NSString *)imageName{
	FHVDocSet *docSet = [self docSetForItem:m_selectedItem];
	return [NSURL fileURLWithPath:[[docSet imagePath] stringByAppendingPathComponent:imageName]];
}

- (NSString *)anchorForItem:(id)item{
	NSString *ident = [item objectForKey:@"ident"];
	NSRange hashRange = [ident rangeOfString:@"#" options:NSBackwardsSearch];
	if (hashRange.location == NSNotFound || hashRange.location == [ident length] - 1) 
		return nil;
	return [ident substringFromIndex:(hashRange.location + 1)];
}

- (void)setShowsInheritedSignatures:(BOOL)bFlag{
	if (m_showsInheritedSignatures == bFlag) return;
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:bFlag] 
		forKey:@"FHVDocSetShowsInheritedSignatures"];
	m_showsInheritedSignatures = bFlag;
	[self selectFirstLevelItem:m_selectedItem];
}

- (void)setSearchTerm:(NSString *)filter{
	if (filter == m_lastSearchTerm || [m_lastSearchTerm isEqualToString:filter])
		return;
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[m_searchWorker cancelSearch];
	[m_lastSearchTerm release];
	m_lastSearchTerm = [filter copy];
	
	if (filter == nil){
		m_inSearchMode = NO;
		[m_firstLevelController setContent:m_mainData];
		[m_searchResults release];
		m_searchResults = nil;
		return;
	}
	
	m_inSearchMode = YES;
	[self performSelector:@selector(_performSearchWithTerm:) withObject:filter 
		afterDelay:0.2];
}

- (void)setSearchMode:(FHVDocSetSearchMode)mode{
	if (m_searchMode == mode) return;
	m_searchMode = mode;
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:mode] 
		forKey:@"FHVDocSetSearchMode"];
	if (!m_inSearchMode) return;
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[self performSelector:@selector(_performSearchWithTerm:) withObject:m_lastSearchTerm 
		afterDelay:0.2];
}

- (void)setDocSetWithIndex:(NSUInteger)index inSearchIncluded:(BOOL)bFlag{
	FHVDocSet *docSet = [m_docSets objectAtIndex:index];
	if (docSet.inSearchIncluded == bFlag)
		return;
	docSet.inSearchIncluded = bFlag;
	if (!m_inSearchMode) return;
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[self performSelector:@selector(_performSearchWithTerm:) withObject:m_lastSearchTerm 
		afterDelay:0.2];
}

- (NSImage *)imageForItem:(id)item{
	NSString *imageName = @"method";
	FHVItemType itemType = [[item objectForKey:@"itemType"] intValue];
	if (itemType == kItemTypePackage){
		imageName = @"package";
	}else if (itemType == kItemTypeClass){
		imageName = [[item objectForKey:@"type"] intValue] == kClassTypeInterface 
			? @"interface" : @"class";
	}else{
		FHVSignatureType sigType = [[item objectForKey:@"type"] intValue];
		FHVSignatureParentType sigParentType = [[item objectForKey:@"parentType"] intValue];
		if (sigType == kSigTypeFunction){
			imageName = sigParentType == kSigParentTypeClass ? @"method" : @"function";
		}else if (sigType == kSigTypeVariable){
			imageName = @"property";
		}else if (sigType == kSigTypeConstant){
			imageName = @"constant";
		}else if (sigType == kSigTypeEvent){
			imageName = @"event";
		}
	}
	return [NSImage imageNamed:[NSString stringWithFormat:@"%@.png", imageName]];
}

- (void)loadChildrenOfPackage:(NSDictionary *)package{
	if ([[package objectForKey:@"itemType"] intValue] != kItemTypePackage || 
		[package objectForKey:@"children"] != nil)
		return;
	FHVDocSet *docSet = [self docSetForItem:package];
	NSMutableArray *children = [NSMutableArray array];
	[children addObjectsFromArray:[docSet classesWithParentId:[package objectForKey:@"dbId"]]];
	[children addObjectsFromArray:[docSet signaturesWithPackageId:[package objectForKey:@"dbId"]]];
	[(NSMutableDictionary *)package setObject:children forKey:@"children"];
}

- (NSDictionary *)docSetItemForItem:(id)item{
	NSInteger docSetId = [[item objectForKey:@"docSetId"] intValue];
	for (NSInteger i = 0; i < [m_docSets count]; i++){
		FHVDocSet *docSet = [m_docSets objectAtIndex:i];
		if (docSet.index == docSetId)
			return [m_mainData objectAtIndex:i];
	}
	return nil;
}

- (FHVDocSet *)docSetForItem:(id)item{
	NSInteger docSetId = [[item objectForKey:@"docSetId"] intValue];
	for (FHVDocSet *docSet in m_docSets){
		if (docSet.index == docSetId)
			return docSet;
	}
	return nil;
}

- (NSDictionary *)docSetItemForDocSetId:(NSString *)docSetId{
	for (NSInteger i = 0; i < [m_docSets count]; i++){
		FHVDocSet *docSet = [m_docSets objectAtIndex:i];
		if ([docSet.docSetId isEqualToString:docSetId])
			return [m_mainData objectAtIndex:i];
	}
	return nil;
}



#pragma mark -
#pragma mark KVO Notifications

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change 
	context:(void *)context{
	if (![[(NSTreeController *)object selectedObjects] count])
		return;
	if (object == m_firstLevelController){
		[self selectFirstLevelItem:[[m_firstLevelController selectedObjects] objectAtIndex:0]];
	}else if (object == m_secondLevelController){
		NSDictionary *item = [[m_secondLevelController selectedObjects] objectAtIndex:0];
		[self willChangeValueForKey:@"detailSelectionAnchor"];
		m_detailSelectionAnchor = [[self anchorForItem:item] retain];
		[self didChangeValueForKey:@"detailSelectionAnchor"];
	}
}



#pragma mark -
#pragma mark Private methods

- (void)_loadDocSets{
	NSArray *files = [[NSFileManager defaultManager] 
		contentsOfDirectoryAtPath:m_path error:nil];
	NSMutableArray *docSets = [NSMutableArray array];
	for (NSString *file in files){
		if ([[[file pathExtension] lowercaseString] isEqualToString:@"fhvdocset"]){
			FHVDocSet *docSet = [[FHVDocSet alloc] initWithPath:
				[m_path stringByAppendingPathComponent:file] index:[docSets count]];
			[docSets addObject:docSet];
			[docSet release];
		}
	}
	[docSets sortUsingComparator:^(id obj1, id obj2){
		return [[obj1 valueForKey:@"name"] compare:[obj2 valueForKey:@"name"]];
	}];
	[m_docSets release];
	[self willChangeValueForKey:@"docSets"];
	m_docSets = [docSets copy];
	[self didChangeValueForKey:@"docSets"];
}

- (NSString *)_classHTMLStringWithClassNode:(NSDictionary *)classNode 
	signatures:(NSArray *)signatures{
	NSMutableString *htmlString = [NSMutableString string];
	[htmlString appendFormat:@"<h1>%@</h1>", [classNode objectForKey:@"name"]];
	[htmlString appendString:[classNode objectForKey:@"detail"]];
	
	for (int i = 0; i < [signatures count]; i++){
		NSDictionary *item = [signatures objectAtIndex:i];
		[htmlString appendFormat:@"<h2>%@</h2>", [item objectForKey:@"name"]];
		NSArray *children = [item objectForKey:@"children"];
		for (int j = 0; j < [children count]; j++){
			NSDictionary *sig = [children objectAtIndex:j];
			[htmlString appendFormat:@"<a name='%@'></a>", [self anchorForItem:sig]];
			[htmlString appendFormat:@"<h3>%@</h3>", [sig objectForKey:@"signature"]];
			NSString *detail = [sig objectForKey:@"detail"];
			NSString *summary = [sig objectForKey:@"summary"];
			if ([detail length] > 0) [htmlString appendString:detail];
			else if ([summary length] > 0) [htmlString appendString:summary];
			if (j < [children count] - 1)
				[htmlString appendString:@"<hr />"];
		}
	}
	return htmlString;
}

- (NSString *)_globalFunctionHTMLWithNode:(NSDictionary *)node{
	NSMutableString *htmlString = [NSMutableString string];
	[htmlString appendFormat:@"<h1>%@</h1>", [node objectForKey:@"name"]];
	[htmlString appendString:[node objectForKey:@"detail"]];
	return htmlString;
}

- (NSString *)_globalConstantHTMLWithNode:(NSDictionary *)node{
	NSMutableString *htmlString = [NSMutableString string];
	[htmlString appendFormat:@"<h1>%@</h1>", [node objectForKey:@"name"]];
	[htmlString appendString:[node objectForKey:@"detail"]];
	return htmlString;
}

- (void)_performSearchWithTerm:(NSString *)term{
	[m_searchWorker performSearchWithTerm:term mode:m_searchMode];
}

- (void)_setHTMLBody:(NSString *)body usingTemplate:(NSString *)templateName{
	NSMutableString *html = [NSMutableString stringWithContentsOfFile:[[NSBundle mainBundle] 
		pathForResource:templateName ofType:@"html"] encoding:NSUTF8StringEncoding error:nil];
	[html replaceOccurrencesOfString:@"%BODY%" withString:body 
		options:0 range:(NSRange){0, [html length]}];
	[self willChangeValueForKey:@"detailData"];
	[m_detailData release];
	m_detailData = [html copy];
	[self didChangeValueForKey:@"detailData"];
}



#pragma mark -
#pragma mark FHVSearchWorkerProtocol methods

- (void)searchDidStart{
	[m_searchResults release];
	NSMutableDictionary *headerNode = [NSMutableDictionary dictionary];
	[headerNode setObject:@"Searching ..." forKey:@"name"];
	[headerNode setObject:[NSMutableArray array] forKey:@"children"];
	[headerNode setObject:[NSNumber numberWithBool:NO] forKey:@"leaf"];
	[headerNode setObject:[NSNumber numberWithBool:YES] forKey:@"root"];
	m_searchResults = [[NSArray alloc] initWithObjects:headerNode, nil];
	[m_firstLevelController setContent:m_searchResults];
}

- (void)searchResultsAvailable:(NSArray *)results{
	NSAssert([NSThread isMainThread], @"Not on main thread");
	NSMutableArray *children = [[m_searchResults objectAtIndex:0] objectForKey:@"children"];
	[children addObjectsFromArray:results];
	[m_firstLevelController rearrangeObjects];
}

- (void)searchDidEnd{
	[[m_searchResults objectAtIndex:0] setObject:@"Search Results" forKey:@"name"];
}
@end