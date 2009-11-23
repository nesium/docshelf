//
//  Package.m
//  FlexHelpViewer
//
//  Created by Marc Bauer on 10.05.08.
//  Copyright 2008 nesiumdotcom. All rights reserved.
//

#import "PackageNode.h"


@implementation PackageNode

- (NSSet *)children{
	return [self.entities filteredSetUsingPredicate:[NSPredicate predicateWithFormat:
		@"SELF.class = %@", [PackageNode class]]];
}

- (NSUInteger)numChildren{
	return [[self children] count];
}

- (BOOL)isLeaf{
	return [self numChildren] < 1;
}

@end