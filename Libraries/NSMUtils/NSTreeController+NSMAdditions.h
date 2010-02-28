//
//  NSTreeController+NSMAdditions.h
//  EarthDocs
//
//  Created by Marc Bauer on 27.02.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSTreeController (NSMAdditions)
- (void)setSelectedObject:(id)anObject;
- (void)setSelectedObjects:(NSArray *)objects;
- (NSIndexPath *)indexPathForObject:(id)anObject;
- (NSTreeNode *)nodeForObject:(id)anObject;
@end