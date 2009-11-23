//
//  Package.h
//  FlexHelpViewer
//
//  Created by Marc Bauer on 10.05.08.
//  Copyright 2008 nesiumdotcom. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AbstractNode.h"


@interface PackageNode : AbstractNode{
}
- (NSSet *)children;
- (NSUInteger)numChildren;
- (BOOL)isLeaf;
@end