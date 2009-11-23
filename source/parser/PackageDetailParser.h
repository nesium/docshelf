//
//  PackageDetailParser.h
//  FlexHelpViewer
//
//  Created by Marc Bauer on 10.05.08.
//  Copyright 2008 nesiumdotcom. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AbstractXMLTreeParser.h"
#import "ClassDetailParser.h"
#import "PackageNode.h"
#import "FunctionNode.h"
#import "ClassNode.h"
#import "InterfaceNode.h"
#import "VariableNode.h"


@interface PackageDetailParser : AbstractXMLTreeParser{
	PackageNode *m_packageNode;
	NSManagedObjectContext *m_context;
}
- (id)initWithPackageNode:(PackageNode *)node filename:(NSString *)filename 
	context:(NSManagedObjectContext *)context;
@end