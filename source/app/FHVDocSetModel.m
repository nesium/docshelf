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
- (void)_mergeDocSetsData;
- (FHVDocSet *)_docSetForItem:(id)item;
- (NSString *)_classHTMLStringWithClassNode:(NSDictionary *)classNode 
	signatures:(NSArray *)signatures;
- (void)_updateDetailSelectionIndex:(NSNumber *)idToLookFor;
@end


@implementation FHVDocSetModel

@synthesize currentData=m_currentData, 
			selectionData=m_selectionData, 
			detailData=m_detailData, 
			showsInheritedSignatures=m_showsInheritedSignatures, 
			inSearchMode=m_inSearchMode, 
			detailSelectionIndex=m_detailSelectionIndex, 
			detailSelectionAnchor=m_detailSelectionAnchor, 
			searchMode=m_searchMode, 
			docSets=m_docSets;

#pragma mark -
#pragma mark Initialization & Deallocation

- (id)initWithDocSetPath:(NSString *)path{
	if (self = [super init]){
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		m_path = [path copy];
		m_docSets = nil;
		m_currentData = nil;
		m_selectionData = nil;
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
	[NSThread detachNewThreadSelector:@selector(_mergeDocSetsData) toTarget:self withObject:nil];
}

- (void)selectFirstLevelItem:(id)item{
	m_detailSelectionIndex = -1;
	
	if (item == nil){
		[m_selectedItem release];
		m_selectedItem = nil;
		[self willChangeValueForKey:@"selectionData"];
		[m_selectionData release];
		m_selectionData = nil;
		[self didChangeValueForKey:@"selectionData"];
		[self willChangeValueForKey:@"detailData"];
		[m_detailData release];
		m_detailData = @"";
		[self didChangeValueForKey:@"detailData"];
		return;
	}
	
	// @TODO handle the case where item could be a package, or where the parent of the item could 
	// be a package
	NSNumber *idToSelect = nil;
	FHVDocSet *docSet = [self _docSetForItem:item];
	if ([[item objectForKey:@"itemType"] intValue] == kItemTypeSignature){
		idToSelect = [item objectForKey:@"dbId"];
		item = [docSet classWithId:[item objectForKey:@"parentDbId"]];
	}
	
	if (m_selectedItem != nil && [[item objectForKey:@"itemType"] 
		isEqualToNumber:[m_selectedItem objectForKey:@"itemType"]] && 
		[[item objectForKey:@"dbId"] isEqualToNumber:[m_selectedItem objectForKey:@"dbId"]]){
		[self _updateDetailSelectionIndex:idToSelect];
		return;
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
			constructor, @"children", 
			nil]];
	}
	if (constants){
		[mergedSigs addObject:[NSDictionary dictionaryWithObjectsAndKeys: 
			@"Constants", @"name", 
			constants, @"children", 
			nil]];
	}
	if (properties){
		[mergedSigs addObject:[NSDictionary dictionaryWithObjectsAndKeys: 
			@"Properties", @"name", 
			properties, @"children", 
			nil]];
	}
	if (methods){
		[mergedSigs addObject:[NSDictionary dictionaryWithObjectsAndKeys: 
			@"Methods", @"name", 
			methods, @"children", 
			nil]];
	}
	if (events){
		[mergedSigs addObject:[NSDictionary dictionaryWithObjectsAndKeys: 
			@"Events", @"name", 
			events, @"children", 
			nil]];
	}
	
	[self willChangeValueForKey:@"selectionData"];
	[m_selectionData release];
	m_selectionData = [mergedSigs copy];
	if (idToSelect) [self _updateDetailSelectionIndex:idToSelect];
	[self didChangeValueForKey:@"selectionData"];
	
	NSString *htmlBody = [self _classHTMLStringWithClassNode:[docSet classWithId:selectedId] 
		signatures:m_selectionData];
	NSMutableString *html = [NSMutableString stringWithContentsOfFile:[[NSBundle mainBundle] 
		pathForResource:@"class" ofType:@"html"] encoding:NSUTF8StringEncoding error:nil];
	[html replaceOccurrencesOfString:@"%BODY%" withString:htmlBody 
		options:0 range:(NSRange){0, [html length]}];
	[self willChangeValueForKey:@"detailData"];
	[m_detailData release];
	m_detailData = [html copy];
	[self didChangeValueForKey:@"detailData"];
}

- (NSURL *)URLForImageWithName:(NSString *)imageName{
	FHVDocSet *docSet = [self _docSetForItem:m_selectedItem];
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
		[self willChangeValueForKey:@"currentData"];
		[m_searchResults release];
		m_searchResults = nil;
		m_currentData = m_mainData;
		[self didChangeValueForKey:@"currentData"];
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
	m_docSets = [docSets copy];
}

- (void)_mergeDocSetsData{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	id *connectionProxy = [[NSConnection 
		connectionWithRegisteredName:@"com.nesium.FlexDocs.InitialLoadConnection" 
		host:nil] rootProxy];
	
	NSArray *docSets = m_docSets;
	NSMutableArray *allPackages = [NSMutableArray array];
	NSMutableDictionary *allClasses = [NSMutableDictionary dictionary];
	[connectionProxy setProgressIsIndeterminate:YES];
	int i = 1;
	for (FHVDocSet *docSet in docSets){
		[connectionProxy setStatusMessage:[NSString stringWithFormat:@"Loading %@ (%d/%d) ...", 
			docSet.name, i++, [docSets count]]];
		[allPackages addObjectsFromArray:[docSet allPackages]];
		NSArray *classes = [docSet allClasses];
		for (NSDictionary *clazz in classes){
			NSString *classPackageName = [[clazz objectForKey:@"ident"] 
				stringByRemovingLastPackageComponent];
			NSMutableArray *children = [allClasses objectForKey:classPackageName];
			if (!children){
				children = [NSMutableArray array];
				[allClasses setObject:children forKey:classPackageName];
			}
			[children addObject:clazz];
		}
		NSArray *globalSignatures = [docSet allGlobalSignatures];
		for (NSDictionary *sig in globalSignatures){
			NSString *sigPackageName = [sig objectForKey:@"parentName"];
			NSMutableArray *children = [allClasses objectForKey:sigPackageName];
			if (!children){
				children = [NSMutableArray array];
				[allClasses setObject:children forKey:sigPackageName];
			}
			[children addObject:sig];
		}
	}
	
	[connectionProxy setStatusMessage:@"Preparing data ..."];
	[allPackages sortUsingComparator:^(id obj1, id obj2){
		return [[obj1 objectForKey:@"ident"] compare:[obj2 objectForKey:@"ident"]];
	}];
	
	NSMutableArray *mergedData = [NSMutableArray array];
	NSMutableArray *mergedPackageNames = [NSMutableArray array];
	for (NSDictionary *package in allPackages){
		NSString *packageName = [package objectForKey:@"name"];
		// prevent duplicates
		if ([mergedPackageNames containsObject:packageName])
			continue;
		NSMutableArray *children = [allClasses objectForKey:packageName];
		[mergedPackageNames addObject:packageName];
		if (!children){
			[mergedData addObject:package];
			continue;
		}
		NSArray *immutableChildren = [children copy];
		NSMutableDictionary *mutablePackage = [package mutableCopy];
		[mutablePackage setObject:immutableChildren forKey:@"children"];
		NSDictionary *immutablePackage = [mutablePackage copy];
		[mutablePackage release];
		[mergedData addObject:immutablePackage];
		[immutablePackage release];
		[immutableChildren release];
	}
	[m_mainData release];
	m_mainData = [mergedData copy];
	[self performSelectorOnMainThread:@selector(_docSetDataMerged) withObject:nil waitUntilDone:NO];
	
	[pool release];
}

- (void)_docSetDataMerged{
	BOOL isInitialLoad = m_currentData == nil;
	[self willChangeValueForKey:@"currentData"];
	m_currentData = m_mainData;
	[self didChangeValueForKey:@"currentData"];
	if (isInitialLoad){
		[m_searchWorker start];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"FHVDocSetModelInitialLoadDone" 
			object:self];
	}
}

- (FHVDocSet *)_docSetForItem:(id)item{
	return [m_docSets objectAtIndex:[[item objectForKey:@"docSetId"] intValue]];
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

- (void)_updateDetailSelectionIndex:(NSNumber *)idToSelect{
	NSInteger i = 0;
	[m_detailSelectionAnchor release];
	m_detailSelectionAnchor = nil;
	for (NSDictionary *dict in m_selectionData){
		i++;
		NSArray *children = [dict objectForKey:@"children"];
		for (NSDictionary *sig in children){
			if ([[sig objectForKey:@"dbId"] isEqualToNumber:idToSelect]){
				m_detailSelectionIndex = i;
				m_detailSelectionAnchor = [[self anchorForItem:sig] retain];
				return;
			}
			i++;
		}
	}
	m_detailSelectionIndex = -1;
}

- (void)_performSearchWithTerm:(NSString *)term{
	[m_searchWorker performSearchWithTerm:term mode:m_searchMode];
}



#pragma mark -
#pragma mark FHVSearchWorkerProtocol methods

- (void)searchDidStart{
	NSLog(@"searchDidStart");
	[self willChangeValueForKey:@"currentData"];
	[m_searchResults release];
	NSMutableArray *children = [NSMutableArray array];
	NSMutableDictionary *headerNode = [NSMutableDictionary dictionary];
	[headerNode setObject:@"Searching ..." forKey:@"name"];
	[headerNode setObject:children forKey:@"children"];
	m_searchResults = [[NSArray alloc] initWithObjects:headerNode, nil];
	m_currentData = m_searchResults;
	[self didChangeValueForKey:@"currentData"];
}

- (void)searchResultsAvailable:(NSArray *)results{
	NSAssert([NSThread isMainThread], @"Not on main thread");
	[self willChangeValueForKey:@"currentData"];
	NSMutableArray *children = [[m_searchResults objectAtIndex:0] objectForKey:@"children"];
	[children addObjectsFromArray:results];
	[self didChangeValueForKey:@"currentData"];
}

- (void)searchDidEnd{
	NSLog(@"searchDidEnd");
	[[m_searchResults objectAtIndex:0] setObject:@"Search Results" forKey:@"name"];
}
@end