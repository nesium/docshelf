//
//  ClassNode.m
//  FlexHelpViewer
//
//  Created by Marc Bauer on 10.05.08.
//  Copyright 2008 nesiumdotcom. All rights reserved.
//

#import "ClassNode.h"

NSInteger sortSubnodes(id num1, id num2, void *context){
	ClassNode *parent = (ClassNode *)context;
	SignatureNode *node1 = (SignatureNode *)num1;
	SignatureNode *node2 = (SignatureNode *)num2;
	NSString *constructorName = [NSString stringWithFormat:@"%@(", parent.name];
	if ([node1.signature hasPrefix:constructorName])
		return NSOrderedAscending;
	else if ([node2.signature hasPrefix:constructorName])
		return NSOrderedDescending;
	return [node1.signature compare:node2.signature];
}

@implementation ClassNode

- (NSSet *)methodNodes{
	return [self.signatureNodes filteredSetUsingPredicate:[NSPredicate predicateWithFormat:
		@"SELF.class = %@", [FunctionNode class]]];
}

- (NSSet *)propertyNodes{
	return [self.signatureNodes filteredSetUsingPredicate:[NSPredicate predicateWithFormat: 
		@"SELF.class = %@", [VariableNode class]]];
}

- (NSSet *)eventNodes{
	return [self.signatureNodes filteredSetUsingPredicate:[NSPredicate predicateWithFormat: 
		@"SELF.class = %@", [EventNode class]]];
}

- (NSString *)htmlString{
	NSMutableString *htmlString = [NSMutableString string];
	[htmlString appendFormat:@"<h1>%@</h1>", self.name];
	[htmlString appendString:self.detail];
	NSArray *methodNodes = [[self.methodNodes allObjects] sortedArrayUsingFunction:sortSubnodes 
		context:self];
	
	NSArray *sortDescriptors = [NSArray arrayWithObject:[[[NSSortDescriptor alloc] 
		initWithKey:@"signature" ascending:YES] autorelease]];
	
	NSUInteger numNodes = [methodNodes count];
	if (numNodes){
		[htmlString appendString:@"<h2>Methods</h2>"];
	}
	for (NSUInteger i = 0; i < numNodes; i++){
		AbstractNode *node = [methodNodes objectAtIndex:i];
		[htmlString appendString:[node htmlString]];
		if (i < numNodes - 1)
			[htmlString appendString:@"<hr />"];
	}
	
	NSArray *propertyNodes = [[self.propertyNodes allObjects] 
		sortedArrayUsingDescriptors:sortDescriptors];
	numNodes = [propertyNodes count];
	if (numNodes){
		[htmlString appendString:@"<h2>Properties</h2>"];
	}
	for (NSUInteger i = 0; i < numNodes; i++){
		AbstractNode *node = [propertyNodes objectAtIndex:i];
		[htmlString appendString:[node htmlString]];
		if (i < numNodes - 1)
			[htmlString appendString:@"<hr />"];
	}
	
	NSArray *eventNodes = [[self.eventNodes allObjects] 
		sortedArrayUsingDescriptors:sortDescriptors];
	numNodes = [eventNodes count];
	if (numNodes){
		[htmlString appendString:@"<h2>Events</h2>"];
	}
	for (NSUInteger i = 0; i < numNodes; i++){
		AbstractNode *node = [eventNodes objectAtIndex:i];
		[htmlString appendString:[node htmlString]];
		if (i < numNodes - 1)
			[htmlString appendString:@"<hr />"];
	}
	
	return htmlString;
}
@end