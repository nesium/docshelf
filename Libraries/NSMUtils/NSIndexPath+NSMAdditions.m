//
//  NSIndexPath+NSMAdditions.m
//  EarthDocs
//
//  Created by Marc Bauer on 28.02.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import "NSIndexPath+NSMAdditions.h"


@implementation NSIndexPath (NSMAdditions)

+ (id)indexPathWithIndexes:(NSArray *)indexes{
	NSUInteger *buf = malloc([indexes count] * sizeof(NSUInteger));
	for (NSUInteger i = 0; i < [indexes count]; i++){
		NSNumber *num = [indexes objectAtIndex:i];
		buf[i] = [num unsignedIntValue];
	}
	NSIndexPath *path = [NSIndexPath indexPathWithIndexes:buf length:[indexes count]];
	free(buf);
	return path;
}

- (NSArray *)allIndexes{
	NSMutableArray *arr = [NSMutableArray arrayWithCapacity:[self length]];
	for (NSUInteger i = 0; i < [self length]; i++){
		[arr addObject:[NSNumber numberWithInt:[self indexAtPosition:i]]];
	}
	return [[arr copy] autorelease];
}
@end