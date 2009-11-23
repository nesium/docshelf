//
//  AbstractNode.h
//  FlexHelpViewer
//
//  Created by Marc Bauer on 10.05.08.
//  Copyright 2008 nesiumdotcom. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AbstractNode : NSManagedObject{
}
- (id)initWithManagedObjectContext:(NSManagedObjectContext *)context;
@property (retain) NSString *filepath;
@property (retain) NSString *summary;
@property (retain) NSString *name;
@property (retain) NSString *detail;
@property (assign) AbstractNode *parent;
@property (retain) NSSet *entities;
- (NSSet *)signatureNodes;
- (NSString *)htmlString;
@end

@interface AbstractNode (CoreDataGeneratedAccessors)
- (void)addEntitiesObject:(AbstractNode *)value;
- (void)removeEntitiesObject:(AbstractNode *)value;
- (void)addEntities:(NSSet *)value;
- (void)removeEntities:(NSSet *)value;
@end