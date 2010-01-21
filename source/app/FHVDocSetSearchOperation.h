//
//  FHVDocSetSearchOperation.h
//  FlexHelpViewer
//
//  Created by Marc Bauer on 20.01.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FHVDocSet.h"


@interface FHVDocSetSearchOperation : NSOperation{
	NSArray *m_docSets;
	NSString *m_filter;
	NSArray *m_searchResults;
}
@property (readonly) NSArray *searchResults;
- (id)initWithDocSets:(NSArray *)docSets filter:(NSString *)filter;
@end