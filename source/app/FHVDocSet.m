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
- (NSArray *)_fetchClasses:(NSString *)whereClause;
@end


@implementation FHVDocSet

#pragma mark -
#pragma mark Initialization & Deallocation

- (id)initWithPath:(NSString *)path{
	if (self = [super init]){
		m_db = 0x0;
		m_path = [path retain];
		[self _open];
	}
	return self;
}

- (void)dealloc{
	[self _close];
	[m_path release];
	[super dealloc];
}



#pragma mark -
#pragma mark Public methods

- (NSArray *)allPackages{
	NSMutableArray *packages = [NSMutableArray array];
	sqlite3_stmt *stmt;
	sqlite3_prepare(m_db, "SELECT * FROM `fhv_packages`", -1, &stmt, 0);
	while (sqlite3_step(stmt) == SQLITE_ROW){
		NSDictionary *package = [NSDictionary dictionaryWithObjectsAndKeys: 
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
	return [self _fetchClasses:nil];
}



#pragma mark -
#pragma mark Private methods

- (NSArray *)_fetchClasses:(NSString *)whereClause{
	NSMutableArray *classes = [NSMutableArray array];
	NSString *sql = @"SELECT `id`, `package_id`, `ident`, `name`, `summary`, `type` FROM `fhv_classes`";
	if (whereClause != nil) sql = [NSString stringWithFormat:@"%@ WHERE %@", sql, whereClause];
	sql = [sql stringByAppendingString:@" ORDER BY `package_id`, `name`"];
	sqlite3_stmt *stmt;
	sqlite3_prepare(m_db, [sql UTF8String], -1, &stmt, 0);
	while (sqlite3_step(stmt) == SQLITE_ROW){
		NSDictionary *clazz = [NSDictionary dictionaryWithObjectsAndKeys: 
			[NSNumber numberWithLongLong:sqlite3_column_int64(stmt, 0)], @"dbId", 
			[NSNumber numberWithLongLong:sqlite3_column_int64(stmt, 1)], @"packageDbId", 
			sqlite3_column_nsstring(stmt, 2), @"ident", 
			sqlite3_column_nsstring(stmt, 3), @"name", 
			sqlite3_column_nsstring(stmt, 4), @"summary", 
			[NSNumber numberWithInt:sqlite3_column_int(stmt, 5)], @"type", 
			nil];
		[classes addObject:clazz];
	}
	sqlite3_finalize(stmt);
	return classes;
}

- (BOOL)_open{
	NSString *path = [m_path stringByAppendingPathComponent:@"Resources/Data.sql"];
	int result = sqlite3_open_v2([path  UTF8String], &m_db, 
		SQLITE_OPEN_READONLY | SQLITE_OPEN_NOMUTEX, NULL);
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