//
//  NSURL+FHVUtils.h
//
//  Created by Marc Bauer on 07.03.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSString+FHVUtils.h"


@interface NSURL (FHVUtils)
- (NSString *)packageNameByResolvingAgainstBasePath:(NSString *)basePath;
- (NSString *)packageNameByResolvingAgainstBaseURL:(NSURL *)baseURL;
@end