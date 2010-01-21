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
- (NSArray *)_fetchClasses:(NSString *)whereClause includeDetail:(BOOL)includeDetail;
- (NSArray *)_fetchSignatures:(NSString *)whereClause includeDetail:(BOOL)includeDetail;
@end


@implementation FHVDocSet

#pragma mark -
#pragma mark Initialization & Deallocation

- (id)initWithPath:(NSString *)path index:(NSUInteger)index{
	if (self = [super init]){
		m_db = 0x0;
		m_path = [path retain];
		m_index = [[NSNumber numberWithInt:index] retain];
		[self _open];
	}
	return self;
}

- (void)dealloc{
	[self _close];
	[m_path release];
	[m_index release];
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
		NSDictionary *package = [NSDictionary dictionaryWithObjectsAndKeys: 
			m_index, @"docSetId", 
			[NSNumber numberWithInt:kItemTypePackage], @"itemType", 
			[NSNumber numberWithLongLong:sqlite3_column_int64(stmt, 0)], @"dbId", 
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
	return [self _fetchClasses:nil includeDetail:NO];
}

- (NSArray *)signaturesWithParentId:(NSNumber *)parentId includeInherited:(BOOL)bFlag{
	NSString *whereClause = [NSString stringWithFormat:@"`parent_id` = %qu", 
		[parentId longLongValue]];
	if (!bFlag) whereClause = [whereClause stringByAppendingFormat:@" AND `inherited` = %d", bFlag];
	return [self _fetchSignatures:whereClause includeDetail:YES];
}

- (NSDictionary *)classWithId:(NSNumber *)dbId{
	NSArray *classes = [self _fetchClasses:[NSString stringWithFormat:@"`id` = %qu", 
		[dbId longLongValue]] includeDetail:YES];
	if ([classes count] == 0) return nil;
	return [classes objectAtIndex:0];
}

- (NSArray *)classesFilteredByExpression:(NSString *)filter{
	return [self _fetchClasses:[NSString stringWithFormat:@"`name` LIKE '%@'", filter] 
		includeDetail:NO];
}

- (NSArray *)signaturesFilteredByExpression:(NSString *)filter{
	return [self _fetchSignatures:[NSString stringWithFormat:@"`name` LIKE '%@' AND `inherited` = 0", filter] 
		includeDetail:NO];
}



#pragma mark -
#pragma mark Private methods

- (NSArray *)_fetchClasses:(NSString *)whereClause includeDetail:(BOOL)includeDetail{
	NSMutableArray *classes = [NSMutableArray array];
	NSString *sql = @"SELECT `id`, `package_id`, `ident`, `name`, `summary`, `type`";
	if (includeDetail) sql = [sql stringByAppendingString:@", `detail`"];
	sql = [sql stringByAppendingString:@" FROM `fhv_classes`"];
	if (whereClause != nil) sql = [NSString stringWithFormat:@"%@ WHERE %@", sql, whereClause];
	sql = [sql stringByAppendingString:@" ORDER BY `package_id`, `name`"];
	sqlite3_stmt *stmt;
	sqlite3_prepare(m_db, [sql UTF8String], -1, &stmt, 0);
	while (sqlite3_step(stmt) == SQLITE_ROW){
		NSDictionary *clazz = [NSDictionary dictionaryWithObjectsAndKeys: 
			m_index, @"docSetId", 
			[NSNumber numberWithInt:kItemTypeClass], @"itemType", 
			[NSNumber numberWithLongLong:sqlite3_column_int64(stmt, 0)], @"dbId", 
			[NSNumber numberWithLongLong:sqlite3_column_int64(stmt, 1)], @"packageDbId", 
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

- (NSArray *)_fetchSignatures:(NSString *)whereClause includeDetail:(BOOL)includeDetail{
	NSMutableArray *signatures = [NSMutableArray array];
	NSString *sql = @"SELECT \
`id`, `parent_id`, `parent_type`, `ident`, `name`, `signature`, `summary`, `inherited`, `type`, `parent_name`"; 
	if (includeDetail) sql = [sql stringByAppendingString:@", `detail`"];
	sql = [sql stringByAppendingString:@" FROM `fhv_signatures`"];
	if (whereClause != nil) sql = [NSString stringWithFormat:@"%@ WHERE %@", sql, whereClause];
	sql = [sql stringByAppendingString:@" ORDER BY `type`, `name`"];
	sqlite3_stmt *stmt;
	sqlite3_prepare(m_db, [sql UTF8String], -1, &stmt, 0);
	while (sqlite3_step(stmt) == SQLITE_ROW){
		NSDictionary *sig = [NSDictionary dictionaryWithObjectsAndKeys: 
			m_index, @"docSetId", 
			[NSNumber numberWithInt:kItemTypeSignature], @"itemType", 
			[NSNumber numberWithLongLong:sqlite3_column_int64(stmt, 0)], @"dbId", 
			[NSNumber numberWithLongLong:sqlite3_column_int64(stmt, 1)], @"parentDbId", 
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
@end