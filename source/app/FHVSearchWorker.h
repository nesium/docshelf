//
//  FHVSearchWorker.h
//  EarthDocs
//
//  Created by Marc Bauer on 22.01.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FHVDocSet.h"

enum {SEARCH_TERM_AVAILABLE, NO_SEARCH_TERM};

@protocol FHVSearchWorkerProtocol
- (void)searchDidStart;
- (void)searchResultsAvailable:(NSArray *)results;
- (void)searchDidEnd;
@end

@interface FHVSearchWorker : NSWindowController{
	id<FHVSearchWorkerProtocol> m_connectionProxy;
	BOOL m_interrupted;
	NSConditionLock *m_lock;
	NSString *m_searchTerm;
	FHVDocSetSearchMode m_searchMode;
	NSArray *m_docSets;
}
- (id)initWithDocSets:(NSArray *)docSets;
- (void)start;
- (void)performSearchWithTerm:(NSString *)term mode:(FHVDocSetSearchMode)mode;
- (void)cancelSearch;
@end