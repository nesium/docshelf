//
//  FHVDocSetSearchOperation.m
//  FlexHelpViewer
//
//  Created by Marc Bauer on 20.01.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import "FHVDocSetSearchOperation.h"


@implementation FHVDocSetSearchOperation

@synthesize searchResults=m_searchResults;

- (id)initWithDocSets:(NSArray *)docSets filter:(NSString *)filter{
	if (self = [super init]){
		m_docSets = [docSets retain];
		m_filter = [filter retain];
		m_searchResults = nil;
	}
	return self;
}

- (void)dealloc{
	[m_docSets release];
	[m_filter release];
	[m_searchResults release];
	[super dealloc];
}

- (void)main{
	@try{
		if ([self isCancelled]) return;
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		NSMutableArray *searchResults = [NSMutableArray array];
		for (FHVDocSet *docSet in m_docSets){
			if ([self isCancelled]) break;
			[searchResults addObjectsFromArray:[docSet classesFilteredByExpression:m_filter]];
			if ([self isCancelled]) break;
			[searchResults addObjectsFromArray:[docSet signaturesFilteredByExpression:m_filter]];
		}
		m_searchResults = [searchResults copy];
		[pool release];
	}@catch(...){}
}
@end