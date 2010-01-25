//
//  FHVDocSet.h
//  FlexHelpViewer
//
//  Created by Marc Bauer on 19.01.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "sqlite3.h"
#import "Constants.h"


@interface FHVDocSet : NSObject{
	NSString *m_path;
	NSString *m_name;
	NSNumber *m_index;
	NSMutableDictionary *m_infoPlist;
	sqlite3 *m_db;
	BOOL m_inSearchIncluded;
}
@property (readonly) NSString *name;
@property (readonly) NSUInteger index;
@property (nonatomic, assign) BOOL inSearchIncluded;
- (id)initWithPath:(NSString *)path index:(NSUInteger)index;
- (NSString *)imagePath;
- (NSArray *)allPackages;
- (NSArray *)allClasses;
- (NSArray *)allGlobalSignatures;
- (NSArray *)classesFilteredByExpression:(NSString *)filter searchMode:(FHVDocSetSearchMode)searchMode 
	cancelCondition:(BOOL *)cancelCondition;
- (NSArray *)signaturesFilteredByExpression:(NSString *)filter 
	searchMode:(FHVDocSetSearchMode)searchMode cancelCondition:(BOOL *)cancelCondition;
- (NSArray *)signaturesWithParentId:(NSNumber *)parentId includeInherited:(BOOL)bFlag;
- (NSDictionary *)classWithId:(NSNumber *)dbId;
@end