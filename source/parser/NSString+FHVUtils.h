//
//  NSString+FHVUtils.h
//  FlexHelpViewer
//
//  Created by Marc Bauer on 16.01.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSString (FHVUtils)
- (NSString *)packageNameByResolvingAgainstBasePath:(NSString *)basePath;
- (NSString *)stringByRemovingLastPackageComponent;
@end