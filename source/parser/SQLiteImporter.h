//
//  SQLiteImporter.h
//  FlexHelpViewer
//
//  Created by Marc Bauer on 18.01.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "sqlite3.h"

typedef enum _FHVSignatureParentType{
	kSigParentTypePackage = 0, 
	kSigParentTypeClass = 1
} FHVSignatureParentType;

typedef enum _FHVSignatureType{
	kSigTypeFunction = 0, 
	kSigTypeVariable = 1, 
	kSigTypeConstant = 2, 
	kSigTypeEvent = 3
} FHVSignatureType;

typedef enum _FHVClassType{
	kClassTypeClass = 0, 
	kClassTypeInterface = 1
} FHVClassType;


@interface SQLiteImporter : NSObject {
	NSString *m_path;
	sqlite3 *m_db;
}
- (id)initWithDBPath:(NSString *)aPath;
- (BOOL)open;
- (BOOL)close;
- (NSNumber *)savePackageWithName:(NSString *)name summary:(NSString *)summary;
- (NSNumber *)saveClassWithName:(NSString *)name summary:(NSString *)summary ident:(NSString *)ident 
	detail:(NSString *)detail type:(FHVClassType)type packageId:(NSNumber *)packageId;
- (void)saveSignatureNodes:(NSArray *)nodes withParentType:(FHVSignatureParentType)parentType 
	parentId:(NSNumber *)parentId parentName:(NSString *)parentName nodeType:(FHVSignatureType)nodeType;
- (void)saveSignatureNode:(NSDictionary *)attribs withParentType:(FHVSignatureParentType)parentType 
	parentId:(NSNumber *)parentId parentName:(NSString *)parentName nodeType:(FHVSignatureType)nodeType;
@end