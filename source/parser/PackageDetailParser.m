//
//  PackageDetailParser.m
//  FlexHelpViewer
//
//  Created by Marc Bauer on 10.05.08.
//  Copyright 2008 nesiumdotcom. All rights reserved.
//

#import "PackageDetailParser.h"

@interface PackageDetailParser (Private)
- (void)parseGlobalFunctions;
- (void)parseClasses;
- (void)parseInterfaces;
- (void)parseConstants;
@end


@implementation PackageDetailParser

- (id)initWithPackageNode:(PackageNode *)node filename:(NSString *)filename 
	context:(NSManagedObjectContext *)context{
	if (self = [super initWithFile:filename]){
		m_packageNode = [node retain];
		m_context = [context retain];
	}
	return self;
}

- (void)dealloc{
	[m_packageNode release];
	[m_context release];
	[super dealloc];
}

- (void)parseTree{
	[self parseGlobalFunctions];
	[self parseClasses];
	[self parseInterfaces];
	[self parseConstants];
}

- (void)parseGlobalFunctions{
	[m_packageNode addEntities:[self summaryTableOfType:@"methodSummary" 
		toNodes:[FunctionNode class] context:m_context]];
}

- (void)parseClasses{
	NSSet *classes = [self summaryTableOfType:@"classSummary" 
		toNodes:[ClassNode class] context:m_context];
	[m_packageNode addEntities:classes];
	for (ClassNode *clazz in classes){
		ClassDetailParser *parser = [[ClassDetailParser alloc] initWithClassNode:clazz 
			context:m_context];
		[parser parse];
		[parser release];
	}
}

- (void)parseInterfaces{
	NSSet *interfaces = [self summaryTableOfType:@"interfaceSummary" 
		toNodes:[InterfaceNode class] context:m_context];
	[m_packageNode addEntities:interfaces];
	for (InterfaceNode *interface in interfaces){
		ClassDetailParser *parser = [[ClassDetailParser alloc] initWithClassNode:interface 
			context:m_context];
		[parser parse];
		[parser release];
	}
}

- (void)parseConstants{
	[m_packageNode addEntities:[self summaryTableOfType:@"constantSummary" 
		toNodes:[VariableNode class] context:m_context]];
}

- (id)objectValue{
	return m_packageNode;
}
@end