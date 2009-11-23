//
//  ConstantNode.h
//  FlexHelpViewer
//
//  Created by Marc Bauer on 10.05.08.
//  Copyright 2008 nesiumdotcom. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SignatureNode.h"


@interface VariableNode : SignatureNode 
{

}

@property (retain) NSNumber *isConstant;

@end