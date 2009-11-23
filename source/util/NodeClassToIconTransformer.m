//
//  NodeClassToIconTransformer.m
//  FlexHelpViewer
//
//  Created by Marc Bauer on 11.05.08.
//  Copyright 2008 nesiumdotcom. All rights reserved.
//

#import "NodeClassToIconTransformer.h"


@implementation NodeClassToIconTransformer

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
	NSString *image;
	if ([obj class] == [PackageNode class])
	{
		image = @"package.gif";
	}
	else if ([obj class] == [InterfaceNode class])
	{
		image = @"interface.gif";
	}
	else if ([obj class] == [FunctionNode class])
	{
		image = [[(FunctionNode *)obj parent] isKindOfClass:[ClassNode class]] ? 
			@"method.gif" : @"function.gif";
	}
	else if ([obj class] == [ClassNode class])
	{
		image = @"class.gif";
	}
	else if ([obj class] == [VariableNode class])
	{
		if ([[(VariableNode *)obj isConstant] boolValue])
		{
			image = @"constant.gif";
		}
		else
		{
			image = [[(FunctionNode *)obj parent] isKindOfClass:[ClassNode class]] ? 
				@"property.gif" : @"constant.gif";
		}
	}
	else if ([obj class] == [EventNode class])
	{
		image = @"event.gif";
	}
	return [NSImage imageNamed:image];
}

@end