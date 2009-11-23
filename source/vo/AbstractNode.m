//
//  AbstractNode.m
//  FlexHelpViewer
//
//  Created by Marc Bauer on 10.05.08.
//  Copyright 2008 nesiumdotcom. All rights reserved.
//

#import "AbstractNode.h"
#import "SignatureNode.h"


@implementation AbstractNode

@dynamic filepath;
@dynamic summary;
@dynamic name;
@dynamic parent;
@dynamic entities;
@dynamic detail;

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)context{
	NSManagedObjectModel *managedObjectModel = [[context persistentStoreCoordinator] 
		managedObjectModel];
	NSEntityDescription *entity = [[managedObjectModel entitiesByName] 
		objectForKey:[self className]];
	if (self = [super initWithEntity:entity insertIntoManagedObjectContext:context]){
	}
	return self;
}

- (NSSet *)signatureNodes{
	return [self.entities filteredSetUsingPredicate:[NSPredicate predicateWithFormat:
		@"SELF.signature != nil"]];
}

- (NSString *)htmlString{
	return @"";
}
@end