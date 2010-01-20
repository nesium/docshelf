//
//  NodeClassToIconTransformer.m
//  FlexHelpViewer
//
//  Created by Marc Bauer on 11.05.08.
//  Copyright 2008 nesiumdotcom. All rights reserved.
//

#import "NodeClassToIconTransformer.h"


@implementation NodeClassToIconTransformer

+ (Class)transformedValueClass{
	return [NSImage class];
}

+ (BOOL)allowsReverseTransformation{
	return NO;
}

- (id)transformedValue:(id)obj{
	return nil;
}
@end