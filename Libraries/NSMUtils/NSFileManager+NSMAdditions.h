//
//  NSFileManager+MBExtensions.h
//  EarthDocs
//
//  Created by Marc Bauer on 24.02.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSFileManager (NSMAdditions)
- (NSString *)nsm_temporaryDirectory;
- (NSString *)nsm_nextAvailableFileNameAtPath:(NSString *)aPath 
	proposedFileName:(NSString *)fileName scheme:(NSString *)scheme;
@end