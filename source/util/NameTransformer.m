//
//  NameTransformer.m
//  FlexHelpViewer
//
//  Created by Marc Bauer on 22.11.09.
//  Copyright 2009 nesiumdotcom. All rights reserved.
//

#import "NameTransformer.h"


@implementation NameTransformer

+ (Class)transformedValueClass{
	return [NSString class];
}

+ (BOOL)allowsReverseTransformation{
	return NO;
}

- (id)transformedValue:(id)obj{
	if ([obj respondsToSelector:@selector(name)]){
		if ([obj name] != nil)
			return [obj name];
	}
	if ([obj respondsToSelector:@selector(signature)]){
		if ([obj signature] != nil)
			return [obj signature];
	}
	return @"Untitled";
}
@end