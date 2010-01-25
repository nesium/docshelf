//
//  FHVSearchWorker.m
//  EarthDocs
//
//  Created by Marc Bauer on 22.01.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import "FHVSearchWorker.h"


@implementation FHVSearchWorker

#pragma mark -
#pragma mark Initialization & Deallocation

- (id)initWithDocSets:(NSArray *)docSets{
	if (self = [super init]){
		m_connectionProxy = (<FHVSearchWorkerProtocol>)[[NSConnection 
			connectionWithRegisteredName:@"com.nesium.FlexHelpViewer.searchWorkerConnection" 
			host:nil] rootProxy];
		m_lock = [[NSConditionLock alloc] initWithCondition:NO_SEARCH_TERM];
		m_interrupted = NO;
		m_docSets = docSets;
		m_searchTerm = nil;
	}
	return self;
}

- (void)dealloc{
	m_interrupted = YES;
	[m_lock release];
	[m_docSets release];
	[super dealloc];
}

- (void)performSearchWithTerm:(NSString *)term mode:(FHVDocSetSearchMode)mode{
	m_interrupted = YES;
	[m_lock lock];
	[term retain];
	[m_searchTerm release];
	m_searchTerm = term;
	m_searchMode = mode;
	[m_lock unlockWithCondition:SEARCH_TERM_AVAILABLE];
}

- (void)cancelSearch{
	m_interrupted = YES;
	[m_lock lock];
	[m_searchTerm release];
	m_searchTerm = nil;
	[m_lock unlockWithCondition:NO_SEARCH_TERM];
}



#pragma mark -
#pragma mark Public methods

- (void)start{
	[NSThread detachNewThreadSelector:@selector(_run) toTarget:self withObject:nil];
}



#pragma mark -
#pragma mark Private methods

- (void)_run{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	for (;;){
		[m_lock lockWhenCondition:SEARCH_TERM_AVAILABLE];
		m_interrupted = NO;
		NSString *searchTerm = [m_searchTerm copy];
		[m_searchTerm release];
		m_searchTerm = nil;
		[m_lock unlockWithCondition:NO_SEARCH_TERM];

		[m_connectionProxy searchDidStart];
		for (FHVDocSet *docSet in m_docSets){
			if (m_interrupted) break;
			if (!docSet.inSearchIncluded) continue;
			NSArray *results = [docSet classesFilteredByExpression:searchTerm 
				searchMode:m_searchMode 
				cancelCondition:&m_interrupted];
			if (m_interrupted) break;
			[m_connectionProxy searchResultsAvailable:results];
		}
		for (FHVDocSet *docSet in m_docSets){
			if (m_interrupted) break;
			if (!docSet.inSearchIncluded) continue;
			NSArray *results = [docSet signaturesFilteredByExpression:searchTerm 
				searchMode:m_searchMode 
				cancelCondition:&m_interrupted];
			if (m_interrupted) break;
			[m_connectionProxy searchResultsAvailable:results];
		}
		[searchTerm release];
		[m_connectionProxy searchDidEnd];
	}
	[pool release];
}
@end