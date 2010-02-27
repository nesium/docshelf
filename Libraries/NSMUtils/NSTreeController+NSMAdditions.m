//
//  NSTreeController+NSMAdditions.m
//  EarthDocs
//
//  Created by Marc Bauer on 27.02.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import "NSTreeController+NSMAdditions.h"

@interface NSTreeController (NSMPrivateAdditions)
- (NSInteger)_indexOfObject:(id)anObject inArray:(NSArray *)anArray;
@end


@implementation NSTreeController (NSMAdditions)

- (void)setSelectedObject:(id)anObject{
	if (anObject == nil) return;
	[self setSelectedObjects:[NSArray arrayWithObject:anObject]];
}

- (void)setSelectedObjects:(NSArray *)objects{
	NSMutableArray *indexPaths = [NSMutableArray array];
	for (id obj in objects){
		NSIndexPath *path = [self indexPathForObject:obj];
		if (path) [indexPaths addObject:path];
	}
	[self setSelectionIndexPaths:indexPaths];
}

- (NSIndexPath *)indexPathForObject:(id)anObject{
	NSInteger index;
	if ((index = [[self content] indexOfObjectIdenticalTo:anObject]) != NSNotFound)
		return [NSIndexPath indexPathWithIndex:index];
	
	__block BOOL (^indexPathOfObjectInNode)(id, id, NSIndexPath**);
	indexPathOfObjectInNode = ^(id anObject, id aNode, NSIndexPath **path){
			NSArray *nodes = [aNode valueForKey:[self childrenKeyPath]];
			if (!nodes) return NO;
			NSInteger index = [nodes indexOfObjectIdenticalTo:anObject];
			if (index != NSNotFound){
				*path = [*path indexPathByAddingIndex:index];
				return YES;
			}
			NSInteger i = 0;
			for (id subNode in nodes){
				NSIndexPath *pathCopy = [*path indexPathByAddingIndex:i++];
				BOOL success = indexPathOfObjectInNode(anObject, subNode, &pathCopy);
				if (success){
					*path = pathCopy;
					return YES;
				}
			}
			return NO;
	};
	
	NSInteger i = 0;
	for (id subNode in [self content]){
		NSIndexPath *path = [NSIndexPath indexPathWithIndex:i++];
		if (indexPathOfObjectInNode(anObject, subNode, &path)){
			return path;
		}
	}
	
	return nil;
}
@end