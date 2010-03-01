//
//  FHVDocSet.m
//  FlexHelpViewer
//
//  Created by Marc Bauer on 19.01.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import "FHVDocSet.h"

NSString *sqlite3_column_nsstring(sqlite3_stmt *stmt, int col){
	const unsigned char *text = sqlite3_column_text(stmt, col);
	return (text == NULL) ? @"" : [NSString stringWithUTF8String:(const char *)text];
}

@interface FHVDocSet (Private)
- (BOOL)_open;
- (BOOL)_close;
- (NSArray *)_fetchClasses:(NSString *)whereClause includeDetail:(BOOL)includeDetail 
	cancelCondition:(BOOL *)cancelCondition;
- (NSArray *)_fetchSignatures:(NSString *)whereClause includeDetail:(BOOL)includeDetail 
	limit:(NSInteger)limit cancelCondition:(BOOL *)cancelCondition preventSorting:(BOOL)preventSorting;
- (NSString *)_conditionForSearchTerm:(NSString *)term andMode:(FHVDocSetSearchMode)mode;
- (void)_saveInfoPlist;
@end


@implementation FHVDocSet

@synthesize name=m_name, 
			path=m_path, 
			docSetId=m_docSetId;

#pragma mark -
#pragma mark Initialization & Deallocation

- (id)initWithPath:(NSString *)path index:(NSUInteger)index{
	if (self = [super init]){
		m_db = 0x0;
		m_path = [path retain];
		m_index = [[NSNumber numberWithInt:index] retain];
		m_infoPlist = [[NSDictionary dictionaryWithContentsOfFile:
			[m_path stringByAppendingPathComponent:@"Info.plist"]] retain];
		m_name = [[m_infoPlist objectForKey:(NSString *)kCFBundleNameKey] retain];
		m_docSetId = [[m_infoPlist objectForKey:@"FHVDocSetId"] retain];
		m_inSearchIncluded = YES;
		[self _open];
	}
	return self;
}

- (void)dealloc{
	[self _close];
	[m_path release];
	m_path = nil;
	[m_index release];
	m_index = nil;
	[m_name release];
	m_name = nil;
	[m_docSetId release];
	m_docSetId = nil;
	[m_infoPlist release];
	m_infoPlist = nil;
	[super dealloc];
}



#pragma mark -
#pragma mark Public methods

- (NSString *)imagePath{
	return [m_path stringByAppendingPathComponent:@"Resources/Images"];
}

- (NSArray *)allPackages{
	NSMutableArray *packages = [NSMutableArray array];
	sqlite3_stmt *stmt;
	sqlite3_prepare(m_db, "SELECT * FROM `fhv_packages`", -1, &stmt, 0);
	while (sqlite3_step(stmt) == SQLITE_ROW){
		NSMutableDictionary *package = [NSMutableDictionary dictionaryWithObjectsAndKeys: 
			m_index, @"docSetId", 
			[NSNumber numberWithInt:kItemTypePackage], @"itemType", 
			[NSNumber numberWithLongLong:sqlite3_column_int64(stmt, 0)], @"dbId", 
			[NSNumber numberWithBool:NO], @"leaf", 
			sqlite3_column_nsstring(stmt, 1), @"ident", 
			sqlite3_column_nsstring(stmt, 2), @"name", 
			sqlite3_column_nsstring(stmt, 3), @"summary", 
			nil];
		[packages addObject:package];
	}
	sqlite3_finalize(stmt);
	return packages;
}

- (NSArray *)allClasses{
	return [self _fetchClasses:nil includeDetail:NO cancelCondition:NULL];
}

- (NSArray *)allGlobalSignatures{
	return [self _fetchSignatures:[NSString stringWithFormat:@"`parent_type` = %d", 
		kSigParentTypePackage] includeDetail:NO limit:-1 cancelCondition:NULL preventSorting:YES];
}

- (NSArray *)classesWithParentId:(NSNumber *)parentId{
	NSString *whereClause = [NSString stringWithFormat:@"`package_id` = %qu", 
		[parentId longLongValue]];
	return [self _fetchClasses:whereClause includeDetail:YES cancelCondition:NULL];
}

- (NSArray *)signaturesWithPackageId:(NSNumber *)packageId{
	NSString *whereClause = [NSString stringWithFormat:@"`parent_id` = %qu AND `parent_type` = %d", 
		[packageId longLongValue], kSigParentTypePackage];
	return [self _fetchSignatures:whereClause includeDetail:NO limit:-1 cancelCondition:NULL 
		preventSorting:NO];
}

- (NSArray *)signaturesWithParentId:(NSNumber *)parentId includeInherited:(BOOL)bFlag{
	NSString *whereClause = [NSString stringWithFormat:@"`parent_id` = %qu AND `parent_type` = %d", 
		[parentId longLongValue], kSigParentTypeClass];
	if (!bFlag) whereClause = [whereClause stringByAppendingFormat:@" AND `inherited` = %d", bFlag];
	return [self _fetchSignatures:whereClause includeDetail:YES limit:-1 cancelCondition:NULL 
		preventSorting:NO];
}

- (NSDictionary *)signatureWithId:(NSNumber *)dbId{
	NSArray *signatures = [self _fetchSignatures:[NSString stringWithFormat:@"`id` = %qu", 
		[dbId longLongValue]] includeDetail:YES limit:1 cancelCondition:NULL preventSorting:YES];
	if ([signatures count] == 0) return nil;
	return [signatures objectAtIndex:0];
}

- (NSDictionary *)classWithId:(NSNumber *)dbId{
	NSArray *classes = [self _fetchClasses:[NSString stringWithFormat:@"`id` = %qu", 
		[dbId longLongValue]] includeDetail:YES cancelCondition:NULL];
	if ([classes count] == 0) return nil;
	return [classes objectAtIndex:0];
}

- (NSArray *)classesFilteredByExpression:(NSString *)filter searchMode:(FHVDocSetSearchMode)searchMode 
	cancelCondition:(BOOL *)cancelCondition{
	return [self _fetchClasses:[self _conditionForSearchTerm:filter andMode:searchMode] 
		includeDetail:NO cancelCondition:cancelCondition];
}

- (NSArray *)signaturesFilteredByExpression:(NSString *)filter 
	searchMode:(FHVDocSetSearchMode)searchMode cancelCondition:(BOOL *)cancelCondition{
	NSString *whereClause = [NSString stringWithFormat:@"%@  AND `inherited` = 0", 
		[self _conditionForSearchTerm:filter andMode:searchMode]];
	return [self _fetchSignatures:whereClause includeDetail:NO limit:300 
		cancelCondition:cancelCondition preventSorting:YES];
}

- (NSUInteger)index{
	return [m_index intValue];
}

- (void)setInSearchIncluded:(BOOL)bFlag{
	[m_infoPlist setObject:[NSNumber numberWithBool:bFlag] forKey:@"FHVInSearchIncluded"];
	[self _saveInfoPlist];
}

- (BOOL)inSearchIncluded{
	return [[m_infoPlist objectForKey:@"FHVInSearchIncluded"] boolValue];
}



#pragma mark -
#pragma mark Private methods

- (NSArray *)_fetchClasses:(NSString *)whereClause includeDetail:(BOOL)includeDetail 
	cancelCondition:(BOOL *)cancelCondition{
	NSMutableArray *classes = [NSMutableArray array];
	NSString *sql = @"SELECT `id`, `package_id`, `ident`, `name`, `summary`, `type`";
	if (includeDetail) sql = [sql stringByAppendingString:@", `detail`"];
	sql = [sql stringByAppendingString:@" FROM `fhv_classes`"];
	if (whereClause != nil) sql = [NSString stringWithFormat:@"%@ WHERE %@", sql, whereClause];
	sql = [sql stringByAppendingString:@" ORDER BY `package_id`, `name`"];
	sqlite3_stmt *stmt;
	sqlite3_prepare(m_db, [sql UTF8String], -1, &stmt, 0);
	while (sqlite3_step(stmt) == SQLITE_ROW && (cancelCondition == NULL || *cancelCondition != YES)){
		NSDictionary *clazz = [NSDictionary dictionaryWithObjectsAndKeys: 
			m_index, @"docSetId", 
			[NSNumber numberWithInt:kItemTypeClass], @"itemType", 
			[NSNumber numberWithLongLong:sqlite3_column_int64(stmt, 0)], @"dbId", 
			[NSNumber numberWithLongLong:sqlite3_column_int64(stmt, 1)], @"packageDbId", 
			[NSNumber numberWithBool:YES], @"leaf", 
			sqlite3_column_nsstring(stmt, 2), @"ident", 
			sqlite3_column_nsstring(stmt, 3), @"name", 
			sqlite3_column_nsstring(stmt, 4), @"summary", 
			[NSNumber numberWithInt:sqlite3_column_int(stmt, 5)], @"type", 
			includeDetail ? sqlite3_column_nsstring(stmt, 6) : nil, @"detail", 
			nil];
		[classes addObject:clazz];
	}
	sqlite3_finalize(stmt);
	return classes;
}

- (NSArray *)_fetchSignatures:(NSString *)whereClause includeDetail:(BOOL)includeDetail 
	limit:(NSInteger)limit cancelCondition:(BOOL *)cancelCondition preventSorting:(BOOL)preventSorting{
	NSMutableArray *signatures = [NSMutableArray array];
	NSString *sql = @"SELECT \
`id`, `parent_id`, `parent_type`, `ident`, `name`, `signature`, `summary`, `inherited`, `type`, `parent_name`"; 
	if (includeDetail) sql = [sql stringByAppendingString:@", `detail`"];
	sql = [sql stringByAppendingString:@" FROM `fhv_signatures`"];
	if (whereClause != nil) sql = [NSString stringWithFormat:@"%@ WHERE %@", sql, whereClause];
	if (preventSorting) sql = [sql stringByAppendingString:@" ORDER BY `type`, `name`"];
	else sql = [sql stringByAppendingFormat:@" LIMIT %d", limit];
	sqlite3_stmt *stmt;
	sqlite3_prepare(m_db, [sql UTF8String], -1, &stmt, 0);
	while (sqlite3_step(stmt) == SQLITE_ROW && (cancelCondition == NULL || *cancelCondition != YES)){
		NSDictionary *sig = [NSDictionary dictionaryWithObjectsAndKeys: 
			m_index, @"docSetId", 
			[NSNumber numberWithInt:kItemTypeSignature], @"itemType", 
			[NSNumber numberWithLongLong:sqlite3_column_int64(stmt, 0)], @"dbId", 
			[NSNumber numberWithLongLong:sqlite3_column_int64(stmt, 1)], @"parentDbId", 
			[NSNumber numberWithBool:YES], @"leaf", 
			[NSNumber numberWithInt:sqlite3_column_int(stmt, 2)], @"parentType", 
			sqlite3_column_nsstring(stmt, 3), @"ident", 
			sqlite3_column_nsstring(stmt, 4), @"name", 
			sqlite3_column_nsstring(stmt, 5), @"signature", 
			sqlite3_column_nsstring(stmt, 6), @"summary", 
			[NSNumber numberWithBool:sqlite3_column_int(stmt, 7) == 1], @"inherited", 
			[NSNumber numberWithInt:sqlite3_column_int(stmt, 8)], @"type", 
			sqlite3_column_nsstring(stmt, 9), @"parentName", 
			includeDetail ? sqlite3_column_nsstring(stmt, 10) : nil, @"detail", 
			nil];
		[signatures addObject:sig];
	}
	sqlite3_finalize(stmt);
	return signatures;
}

- (BOOL)_open{
	NSString *path = [m_path stringByAppendingPathComponent:@"Resources/Data.sql"];
	int result = sqlite3_open_v2([path  UTF8String], &m_db, 
		SQLITE_OPEN_READONLY | SQLITE_OPEN_FULLMUTEX, NULL);
	if (result != SQLITE_OK){
		NSLog(@"Could not open database at path %@", path);
		return NO;
	}
	return YES;
}

- (BOOL)_close{
	int result = sqlite3_close(m_db);
	if (result != SQLITE_OK){
		NSLog(@"Could not close database");
		return NO;
	}
	m_db = 0x0;
	return YES;
}

- (NSString *)_conditionForSearchTerm:(NSString *)term andMode:(FHVDocSetSearchMode)mode{
	NSString *searchString = nil;
	if (mode == kFHVDocSetSearchModeContains){
		searchString = @"`name` LIKE '%%%@%%'";
	}else if (mode == kFHVDocSetSearchModePrefix){
		searchString = @"`name` LIKE '%@%%'";
	}else{
		searchString = @"`name` LIKE '%@'";
	}
	return [NSString stringWithFormat:searchString, term];
}

- (void)_saveInfoPlist{
	[m_infoPlist writeToFile:[m_path stringByAppendingPathComponent:@"Info.plist"] atomically:YES];
}
@end