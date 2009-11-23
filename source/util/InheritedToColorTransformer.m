//
//  InheritedToColorTransformer.m
//  FlexHelpViewer
//
//  Created by Marc Bauer on 19.05.08.
//  Copyright 2008 nesiumdotcom. All rights reserved.
//

#import "InheritedToColorTransformer.h"


@implementation InheritedToColorTransformer

+ (Class)transformedValueClass
{
	return [NSImage class];
}

+ (BOOL)allowsReverseTransformation
{
	return NO;
}

- (id)transformedValue:(id)obj
{
	return ![[(SignatureNode *)obj isInherited] boolValue] ? 
		[NSColor blackColor] : [NSColor grayColor];
}

@end