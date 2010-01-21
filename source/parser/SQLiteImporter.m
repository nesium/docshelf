//
//  SQLiteImporter.m
//  FlexHelpViewer
//
//  Created by Marc Bauer on 18.01.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import "SQLiteImporter.h"


@implementation SQLiteImporter

- (id)initWithDBPath:(NSString *)aPath{
	if (self = [super init]){
		m_path = [aPath copy];
		m_db = 0x0;
	}
	return self;
}

- (void)dealloc{
	[self close];
	[m_path release];
	[super dealloc];
}

- (BOOL)open{
	int result = sqlite3_open_v2([m_path fileSystemRepresentation], &m_db, 
		SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX, NULL);
	if (result != SQLITE_OK){
		NSLog(@"Could not open database");
		return NO;
	}
	
	NSError *error = nil;
	NSString *schema = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] 
		pathForResource:@"schema" ofType:@"sql"] encoding:NSUTF8StringEncoding error:&error];
	if (error){
		NSLog(@"Could not read schema");
		[self close];
		return NO;
	}
	
	result = sqlite3_exec(m_db, [schema UTF8String], NULL, NULL, NULL);
	if (result != SQLITE_OK){
		NSLog(@"Could not create tables");
		[self close];
		return NO;
	}
	
	return YES;
}

- (BOOL)close{
	int result = sqlite3_close(m_db);
	if (result != SQLITE_OK){
		NSLog(@"Could not close db");
		return NO;
	}
	m_db = 0x0;
	return YES;
}



- (NSNumber *)savePackageWithName:(NSString *)name summary:(NSString *)summary{
	sqlite3_stmt *stmt;
	sqlite3_prepare_v2(m_db, "INSERT INTO `fhv_packages` (`ident`, `name`, `summary`) VALUES (?, ?, ?)", 
		-1, &stmt, 0);
	sqlite3_bind_text(stmt, 1, [name UTF8String], -1, SQLITE_STATIC);
	sqlite3_bind_text(stmt, 2, [name UTF8String], -1, SQLITE_STATIC);
	sqlite3_bind_text(stmt, 3, [summary UTF8String], -1, SQLITE_STATIC);
	if (!sqlite3_step(stmt) == SQLITE_DONE){
		NSLog(@"Could not save package %@ to database", name);
	}
	sqlite3_finalize(stmt);
	return [NSNumber numberWithLongLong:sqlite3_last_insert_rowid(m_db)];
}

- (NSNumber *)saveClassWithName:(NSString *)name summary:(NSString *)summary ident:(NSString *)ident 
	detail:(NSString *)detail type:(FHVClassType)type packageId:(NSNumber *)packageId{
	sqlite3_stmt *stmt;
	sqlite3_prepare_v2(m_db, "INSERT INTO `fhv_classes` \
(`package_id`, `ident`, `name`, `summary`, `detail`, `type`) VALUES \
(?, ?, ?, ?, ?, ?)", -1, &stmt, 0);
	sqlite3_bind_int64(stmt, 1, [packageId longLongValue]);
	sqlite3_bind_text(stmt, 2, [ident UTF8String], -1, SQLITE_STATIC);
	sqlite3_bind_text(stmt, 3, [name UTF8String], -1, SQLITE_STATIC);
	sqlite3_bind_text(stmt, 4, [summary UTF8String], -1, SQLITE_STATIC);
	sqlite3_bind_text(stmt, 5, [detail UTF8String], -1, SQLITE_STATIC);
	sqlite3_bind_int(stmt, 6, type);
	int result = sqlite3_step(stmt);
	if (result != SQLITE_DONE){
		NSLog(@"Could not save class %@ to database", name);
	}
	sqlite3_finalize(stmt);
	return [NSNumber numberWithLongLong:sqlite3_last_insert_rowid(m_db)];
}

- (void)saveSignatureNodes:(NSArray *)nodes withParentType:(FHVSignatureParentType)parentType 
	parentId:(NSNumber *)parentId parentName:(NSString *)parentName nodeType:(FHVSignatureType)nodeType{
	for (NSDictionary *node in nodes){
		[self saveSignatureNode:node withParentType:parentType parentId:parentId 
			parentName:parentName nodeType:nodeType];
	}
}

- (void)saveSignatureNode:(NSDictionary *)attribs withParentType:(FHVSignatureParentType)parentType 
	parentId:(NSNumber *)parentId parentName:(NSString *)parentName nodeType:(FHVSignatureType)nodeType{
	if (nodeType == kSigTypeVariable && [[attribs objectForKey:@"constant"] boolValue] == YES)
		nodeType = kSigTypeConstant;
	sqlite3_stmt *stmt;
	sqlite3_prepare_v2(m_db, "INSERT INTO `fhv_signatures` \
(`parent_id`, `parent_type`, `parent_name`, `ident`, `name`, `signature`, `summary`, `detail`, `inherited`, `type`) \
VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", -1, &stmt, 0);
	sqlite3_bind_int64(stmt, 1, [parentId longLongValue]);
	sqlite3_bind_int(stmt, 2, parentType);
	sqlite3_bind_text(stmt, 3, [parentName UTF8String], -1, SQLITE_STATIC);
	sqlite3_bind_text(stmt, 4, [[attribs objectForKey:@"ident"] UTF8String], -1, SQLITE_STATIC);
	sqlite3_bind_text(stmt, 5, [[attribs objectForKey:@"name"] UTF8String], -1, SQLITE_STATIC);
	sqlite3_bind_text(stmt, 6, [[attribs objectForKey:@"signature"] UTF8String], -1, SQLITE_STATIC);
	sqlite3_bind_text(stmt, 7, [[attribs objectForKey:@"summary"] UTF8String], -1, SQLITE_STATIC);
	sqlite3_bind_text(stmt, 8, [[attribs objectForKey:@"detail"] UTF8String], -1, SQLITE_STATIC);
	sqlite3_bind_int(stmt, 9, [[attribs objectForKey:@"inherited"] intValue]);
	sqlite3_bind_int(stmt, 10, nodeType);
	if (!sqlite3_step(stmt) == SQLITE_DONE){
		NSLog(@"Could not save signature node %@ to database", [attribs objectForKey:@"name"]);
	}
	sqlite3_finalize(stmt);
}
@end