//
//  NSError+NSMAdditions.m
//
//  Created by Marc Bauer on 14.03.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import "NSError+NSMAdditions.h"


@implementation NSError (NSMAdditions)

+ (id)errorWithDomain:(NSString *)domain code:(NSInteger)code description:(NSString *)aDescription{
	return [NSError errorWithDomain:domain code:code userInfo:[NSDictionary 
		dictionaryWithObjectsAndKeys:aDescription, NSLocalizedDescriptionKey, nil]];
}

+ (id)errorWithDomain:(NSString *)domain code:(NSInteger)code description:(NSString *)aDescription 
	recoverySuggestion:(NSString *)aSuggestion{
	return [NSError errorWithDomain:domain code:code userInfo:[NSDictionary 
		dictionaryWithObjectsAndKeys:aDescription, NSLocalizedDescriptionKey, 
		aSuggestion, NSLocalizedRecoverySuggestionErrorKey, nil]];
}
@end