//
//  FHVDocSetModel.h
//  FlexHelpViewer
//
//  Created by Marc Bauer on 19.01.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FHVDocSet.h"
#import "NSString+FHVUtils.h"
#import "SQLiteImporter.h"
#import "FHVDocSetSearchOperation.h"


@interface FHVDocSetModel : NSObject{
	NSString *m_path;
	NSArray *m_docSets;
	NSArray *m_mainData;
	NSArray *m_currentData;
	NSArray *m_selectionData;
	NSString *m_detailData;
	NSDictionary *m_selectedItem;
	BOOL m_showsInheritedSignatures;
	NSOperationQueue *m_searchQueue;
	FHVDocSetSearchOperation *m_searchOp;
	BOOL m_inSearchMode;
}
@property (readonly) NSArray *currentData;
@property (readonly) NSArray *selectionData;
@property (readonly) NSString *detailData;
@property (nonatomic, assign) BOOL showsInheritedSignatures;
@property (readonly) BOOL inSearchMode;
- (id)initWithDocSetPath:(NSString *)path;
- (void)selectFirstLevelItem:(id)item;
- (NSURL *)URLForImageWithName:(NSString *)imageName;
- (NSString *)anchorForItem:(id)item;
- (void)setFilterString:(NSString *)filter;
@end