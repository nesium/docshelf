//
//  NSDate+NSMAdditions.h
//  EarthDoc
//
//  Created by Marc Bauer on 03.03.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSDate (NSMAdditions)
- (NSString *)relativeDateStringFromDate:(NSDate *)date oldDateFormat:(NSString *)oldDateFormat;
@end