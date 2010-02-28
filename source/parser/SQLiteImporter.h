//
//  SQLiteImporter.h
//  FlexHelpViewer
//
//  Created by Marc Bauer on 18.01.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "sqlite3.h"
#import "Constants.h"

enum {HAS_DATA, NO_DATA};

@interface SQLiteImporter : NSObject {
	NSString *m_path;
	sqlite3 *m_db;
	sqlite3_stmt *m_packageInsertStmt;
	sqlite3_stmt *m_classInsertStmt;
	sqlite3_stmt *m_signatureInsertStmt;
}
- (id)initWithDBPath:(NSString *)aPath;
- (BOOL)open;
- (void)commit;
- (BOOL)close;
- (BOOL)createIndexes;
- (NSNumber *)savePackageWithName:(NSString *)name summary:(NSString *)summary;
- (NSNumber *)saveClassWithName:(NSString *)name summary:(NSString *)summary ident:(NSString *)ident 
	detail:(NSString *)detail type:(FHVClassType)type packageId:(NSNumber *)packageId;
- (void)saveSignatureNodes:(NSArray *)nodes withParentType:(FHVSignatureParentType)parentType 
	parentId:(NSNumber *)parentId parentName:(NSString *)parentName nodeType:(FHVSignatureType)nodeType;
- (void)saveSignatureNode:(NSDictionary *)attribs withParentType:(FHVSignatureParentType)parentType 
	parentId:(NSNumber *)parentId parentName:(NSString *)parentName nodeType:(FHVSignatureType)nodeType;
@end