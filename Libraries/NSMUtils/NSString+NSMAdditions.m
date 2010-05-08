//
//  NSString+PSAdditions.m
//  ProSieben
//
//  Created by Marc Bauer on 17.02.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import "NSString+NSMAdditions.h"


@implementation NSString (NSMAdditions)

+ (NSString *)nsm_uuid{
	CFUUIDRef uuidRef = CFUUIDCreate(NULL);
	CFStringRef uuidStringRef = CFUUIDCreateString(NULL, uuidRef);
	CFRelease(uuidRef);
	return [(NSString *)uuidStringRef autorelease];
}

- (NSString *)nsm_stringByEscapingHTMLEntities{
	NSMutableString *escapedString = [NSMutableString stringWithString:self];
	[escapedString replaceOccurrencesOfString:@"&" withString: @"&amp;" 
		options:NSLiteralSearch range:NSMakeRange(0, [escapedString length])];
	[escapedString replaceOccurrencesOfString:@"\"" withString: @"&quot;" 
		options:NSLiteralSearch range:NSMakeRange(0, [escapedString length])];
	[escapedString replaceOccurrencesOfString:@"'" withString: @"&#39;" 
		options:NSLiteralSearch range:NSMakeRange(0, [escapedString length])];
	[escapedString replaceOccurrencesOfString:@">" withString: @"&gt;" 
		options:NSLiteralSearch range:NSMakeRange(0, [escapedString length])];
	[escapedString replaceOccurrencesOfString:@"<" withString: @"&lt;" 
		options:NSLiteralSearch range:NSMakeRange(0, [escapedString length])];
	return [[escapedString copy] autorelease];
}

- (NSString *)nsm_normalizedFilename{
	NSMutableString *result = [NSMutableString stringWithString:self];
	[result replaceOccurrencesOfString:@":" withString:@"-" 
		options:0 range:(NSRange){0, [result length]}];
	[result replaceOccurrencesOfString:@"/" withString:@":" 
		options:0 range:(NSRange){0, [result length]}];
	return [result precomposedStringWithCanonicalMapping];
}

- (BOOL)nsm_isURL{
	return [self isMatchedByRegex:@"([hH][tT][tT][pP][sS]?:\\/\\/[^ ,'\">\\]\\)]*[^\\. ,'\">\\]\\)])"];
}
@end