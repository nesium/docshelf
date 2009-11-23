//
//  ClassNode.h
//  FlexHelpViewer
//
//  Created by Marc Bauer on 10.05.08.
//  Copyright 2008 nesiumdotcom. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AbstractNode.h"
#import "FunctionNode.h"
#import "VariableNode.h"
#import "EventNode.h"


@interface ClassNode : AbstractNode{
}
- (NSSet *)methodNodes;
- (NSSet *)propertyNodes;
- (NSSet *)eventNodes;
@end