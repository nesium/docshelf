//
//  NSManagedObjectContext+Extensions.h
//  FlexHelpViewer
//
//  Created by Marc Bauer on 21.11.09.
//  Copyright 2009 nesiumdotcom. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSManagedObjectContext (Extensions)
- (NSSet *)fetchObjectsForEntityName:(NSString *)newEntityName
    withPredicate:(id)stringOrPredicate, ...;
@end
