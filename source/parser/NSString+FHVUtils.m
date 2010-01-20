//
//  NSString+FHVUtils.m
//  FlexHelpViewer
//
//  Created by Marc Bauer on 16.01.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import "NSString+FHVUtils.h"


@implementation NSString (FHVUtils)

- (NSString *)packageNameByResolvingAgainstBasePath:(NSString *)basePath{
	if (![self isAbsolutePath] || ![basePath isAbsolutePath]) return nil;
	NSString *resolvee = self;
	NSString *resolveeLastPathComponent = [[resolvee lastPathComponent] lowercaseString];
	if ([resolveeLastPathComponent isEqualToString:@"package.html"] || 
		[resolveeLastPathComponent isEqualToString:@"package-detail.html"]){
		resolvee = [resolvee stringByDeletingLastPathComponent];
	}
	NSArray *components = [[resolvee stringByDeletingPathExtension] pathComponents];
	NSArray *baseComponents = [basePath pathComponents];
	if ([baseComponents count] >= [components count]) return @"";
	components = [components subarrayWithRange:(NSRange){[baseComponents count], 
		[components count] - [baseComponents count]}];
	if ([components count] == 0) return @"";
	return [components componentsJoinedByString:@"."];
}

- (NSString *)stringByRemovingLastPackageComponent{
	NSArray *parts = [self componentsSeparatedByString:@"."];
	if ([parts count] <= 1) return @"Top Level";
	parts = [parts subarrayWithRange:(NSRange){0, [parts count] - 1}];
	return [parts componentsJoinedByString:@"."];
}
@end