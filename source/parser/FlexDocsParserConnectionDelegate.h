//
//  FHVDocParserDelegate.h
//  EarthDoc
//
//  Created by Marc Bauer on 14.03.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@protocol FlexDocsParserConnectionDelegate
- (oneway void)setStatusMessage:(NSString *)message;
- (oneway void)setProgressIsIndeterminate:(BOOL)bFlag;
- (oneway void)setMaxProgressValue:(double)value;
- (oneway void)setProgress:(double)progress;
- (oneway void)parsingComplete:(NSError *)error;
@end