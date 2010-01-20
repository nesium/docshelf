//
//  FHVDocSetModel.m
//  FlexHelpViewer
//
//  Created by Marc Bauer on 19.01.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import "FHVDocSetModel.h"


@interface FHVDocSetModel (Private)
- (void)_loadDocSets;
- (void)_mergeDocSetsData;
@end


@implementation FHVDocSetModel

@synthesize currentData=m_currentData;

#pragma mark -
#pragma mark Initialization & Deallocation

- (id)initWithDocSetPath:(NSString *)path{
	if (self = [super init]){
		m_path = [path copy];
		m_docSets = [[NSMutableArray alloc] init];
		m_currentData = nil;
		[self _loadDocSets];
		[self _mergeDocSetsData];
	}
	return self;
}

- (void)dealloc{
	[m_path release];
	[m_docSets release];
	[m_currentData release];
	[super dealloc];
}



#pragma mark -
#pragma mark Private methods

- (void)_loadDocSets{
	NSArray *files = [[NSFileManager defaultManager] 
		contentsOfDirectoryAtPath:m_path error:nil];
	for (NSString *file in files){
		if ([[[file pathExtension] lowercaseString] isEqualToString:@"fhvdocset"]){
			FHVDocSet *docSet = [[FHVDocSet alloc] initWithPath:
				[m_path stringByAppendingPathComponent:file]];
			[m_docSets addObject:docSet];
			[docSet release];
		}
	}
}

- (void)_mergeDocSetsData{
	NSArray *docSets = m_docSets;
	NSMutableArray *packages = [NSMutableArray array];
	NSMutableArray *classes = [NSMutableArray array];
	for (FHVDocSet *docSet in docSets){
		[packages addObjectsFromArray:[docSet allPackages]];
		[classes addObjectsFromArray:[docSet allClasses]];
	}
	if ([docSets count] > 1){
		NSComparator comparator = ^(id obj1, id obj2){
			return [[obj1 objectForKey:@"ident"] compare:[obj2 objectForKey:@"ident"]];
		};
		[classes sortUsingComparator:comparator];
		[packages sortUsingComparator:comparator];
	}
	
	NSMutableArray *mergedData = [NSMutableArray array];
	int i = 0;
	for (NSDictionary *package in packages){
		NSMutableDictionary *mutablePackage = [package mutableCopy];
		NSDictionary *clazz = [classes objectAtIndex:i++];
		while ([[[clazz objectForKey:@"ident"] stringByRemovingLastPackageComponent] 
			isEqualToString:[mutablePackage objectForKey:@"ident"]]){
			NSMutableArray *children = [mutablePackage objectForKey:@"children"];
			if (!children){
				children = [NSMutableArray array];
				[mutablePackage setObject:children forKey:@"children"];
			}
			[children addObject:clazz];
			if (i == [classes count]) break;
			clazz = [classes objectAtIndex:i++];
		}
		NSDictionary *immutablePackage = [mutablePackage copy];
		[mutablePackage release];
		[mergedData addObject:immutablePackage];
		[immutablePackage release];
	}
	[self willChangeValueForKey:@"currentData"];
	if (m_currentData) [m_currentData release];
	m_currentData = [mergedData copy];
	[self didChangeValueForKey:@"currentData"];
}
@end