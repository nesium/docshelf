//
//  NSError+NSMAdditions.h
//
//  Created by Marc Bauer on 14.03.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSError (NSMAdditions)
+ (id)errorWithDomain:(NSString *)domain code:(NSInteger)code description:(NSString *)aDescription;
+ (id)errorWithDomain:(NSString *)domain code:(NSInteger)code description:(NSString *)aDescription 
	recoverySuggestion:(NSString *)aSuggestion;
@end