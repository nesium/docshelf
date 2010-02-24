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
#import "FHVSearchWorker.h"
#import "Constants.h"

@interface FHVDocSetModel : NSObject{
	NSString *m_path;
	NSArray *m_docSets;
	NSMutableArray *m_mainData;
	NSArray *m_currentData;
	NSArray *m_selectionData;
	NSString *m_detailData;
	NSString *m_lastSearchTerm;
	NSDictionary *m_selectedItem;
	NSMutableArray *m_searchResults;
	BOOL m_showsInheritedSignatures;
	BOOL m_inSearchMode;
	FHVSearchWorker *m_searchWorker;
	NSConnection *m_searchWorkerConnection;
	NSInteger m_detailSelectionIndex;
	NSString *m_detailSelectionAnchor;
	FHVDocSetSearchMode m_searchMode;
}
@property (readonly) NSArray *currentData;
@property (readonly) NSArray *selectionData;
@property (readonly) NSString *detailData;
@property (nonatomic, assign) BOOL showsInheritedSignatures;
@property (readonly) BOOL inSearchMode;
@property (readonly) NSInteger detailSelectionIndex;
@property (readonly) NSString *detailSelectionAnchor;
@property (nonatomic, assign) FHVDocSetSearchMode searchMode;
@property (readonly) NSArray *docSets;
- (id)initWithDocSetPath:(NSString *)path;
- (void)loadDocSets;
- (void)selectFirstLevelItem:(id)item;
- (NSURL *)URLForImageWithName:(NSString *)imageName;
- (NSString *)anchorForItem:(id)item;
- (void)setSearchTerm:(NSString *)filter;
- (void)setSearchMode:(FHVDocSetSearchMode)mode;
- (void)setDocSetWithIndex:(NSUInteger)index inSearchIncluded:(BOOL)bFlag;
- (NSImage *)imageForItem:(id)item;
- (void)loadChildrenOfPackage:(NSDictionary *)package;
@end