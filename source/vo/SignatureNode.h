//
//  SignatureNode.h
//  FlexHelpViewer
//
//  Created by Marc Bauer on 18.05.08.
//  Copyright 2008 nesiumdotcom. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AbstractNode.h"


@interface SignatureNode : AbstractNode{
}
@property (retain) NSString *signature;
@property (retain) NSNumber *isInherited;
@property (nonatomic, readonly) NSString *anchor;

- (NSSet *)children;
- (NSUInteger)numChildren;
- (BOOL)isLeaf;
@end