//
//  NSURL+FHVUtils.m
//  EarthDoc
//
//  Created by Marc Bauer on 07.03.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import "NSURL+FHVUtils.h"


@implementation NSURL (FHVUtils)

- (NSString *)packageNameByResolvingAgainstBasePath:(NSString *)basePath{
	return [[self path] packageNameByResolvingAgainstBasePath:basePath];
}

- (NSString *)packageNameByResolvingAgainstBaseURL:(NSURL *)baseURL{
	return [[self path] packageNameByResolvingAgainstBasePath:[baseURL path]];
}
@end