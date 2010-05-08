//
//  NSFileManager+MBExtensions.m
//
//  Created by Marc Bauer on 24.02.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import "NSFileManager+NSMAdditions.h"


@implementation NSFileManager (NSMAdditions)

- (NSString *)nsm_temporaryDirectory{
	return [NSTemporaryDirectory() stringByAppendingPathComponent:
		[[NSProcessInfo processInfo] globallyUniqueString]];
}

- (NSString *)nsm_nextAvailableFileNameAtPath:(NSString *)aPath 
	proposedFileName:(NSString *)fileName scheme:(NSString *)scheme{
	NSString *extension = [fileName pathExtension];
	NSString *plainName = [fileName stringByDeletingPathExtension];
	if (scheme == nil) scheme = @"%@-%d";
	NSArray *dirContents = [self contentsOfDirectoryAtPath:aPath error:nil];
	BOOL (^containsFileWithName)(NSString *aName) = ^(NSString *aName){
		for (NSString *name in dirContents){
			NSString *plainName = [name stringByDeletingPathExtension];
			if ([[plainName lowercaseString] isEqualToString:[aName lowercaseString]])
				return YES;
		}
		return NO;
	};
	NSString *newFileName = plainName;
	NSInteger i = 1;
	// be careful to use a scheme, which uses a decimal placeholder to not get stuck in the loop!
	while (containsFileWithName(newFileName))
		newFileName = [NSString stringWithFormat:scheme, plainName, i++];
	return [newFileName stringByAppendingPathExtension:extension];
}
@end