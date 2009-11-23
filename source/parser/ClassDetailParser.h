//
//  ClassDetailParser.h
//  FlexHelpViewer
//
//  Created by Marc Bauer on 11.05.08.
//  Copyright 2008 nesiumdotcom. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AbstractXMLTreeParser.h"
#import "ClassNode.h"
#import "FunctionNode.h"
#import "EventNode.h"
#import "VariableNode.h"

typedef enum _ASScope{
	PublicScope,
	ProtectedScope
} ASScope;


@interface ClassDetailParser : AbstractXMLTreeParser{
	ClassNode *m_classNode;
	NSManagedObjectContext *m_context;
}
- (id)initWithClassNode:(ClassNode *)node context:(NSManagedObjectContext *)context;
@end