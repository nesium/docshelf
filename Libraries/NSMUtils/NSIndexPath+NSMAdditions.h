//
//  NSIndexPath+NSMAdditions.h
//  EarthDocs
//
//  Created by Marc Bauer on 28.02.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSIndexPath (NSMAdditions)
+ (id)indexPathWithIndexes:(NSArray *)indexes;
- (NSArray *)allIndexes;
@end