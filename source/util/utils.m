//
//  utils.m
//  FlexHelpViewer
//
//  Created by Marc Bauer on 17.01.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import "utils.h"

NSString *createUUID(){
	CFUUIDRef uuidRef = CFUUIDCreate(NULL);
	CFStringRef uuidStringRef = CFUUIDCreateString(NULL, uuidRef);
	CFRelease(uuidRef);
	return (NSString *)uuidStringRef;
}