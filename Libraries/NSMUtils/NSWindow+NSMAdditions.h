//
//  NSWindow+NSMAdditions.h
//
//  Created by Marc Bauer on 25.02.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSWindow (NSMAdditions)
- (void)nsm_resizeToFitContentSize:(NSSize)contentSize animated:(BOOL)animated;
@end