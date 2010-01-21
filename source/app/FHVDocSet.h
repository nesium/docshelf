//
//  FHVDocSet.h
//  FlexHelpViewer
//
//  Created by Marc Bauer on 19.01.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "sqlite3.h"

typedef enum _FHVItemType{
	kItemTypePackage = 0, 
	kItemTypeClass = 1, 
	kItemTypeSignature = 2
} FHVItemType;


@interface FHVDocSet : NSObject{
	NSString *m_path;
	NSString *m_name;
	NSNumber *m_index;
	sqlite3 *m_db;
}
- (id)initWithPath:(NSString *)path index:(NSUInteger)index;
- (NSString *)imagePath;
- (NSArray *)allPackages;
- (NSArray *)allClasses;
- (NSArray *)classesFilteredByExpression:(NSString *)filter;
- (NSArray *)signaturesFilteredByExpression:(NSString *)filter;
- (NSArray *)signaturesWithParentId:(NSNumber *)parentId includeInherited:(BOOL)bFlag;
- (NSDictionary *)classWithId:(NSNumber *)dbId;
@end