//
//  FlexDocsParser.m
//  FlexHelpViewer
//
//  Created by Marc Bauer on 10.05.08.
//  Copyright 2008 nesiumdotcom. All rights reserved.
//

#import "FlexDocsParser.h"
#import "FlexHelpViewerApp.h"

@interface FlexDocsParser (Private)
- (void)parsePackageSummary;
- (void)parsePackages;
@end


@implementation FlexDocsParser

@synthesize path=m_path;
FlexHelpViewerApp *m_connectionProxy;

- (id)initWithPath:(NSString *)path{
	if (self = [super init]){
		self.path = path;
		m_connectionProxy = (FlexHelpViewerApp *)[[NSConnection 
			connectionWithRegisteredName:@"com.nesium.FlexHelpViewer" host:nil] rootProxy];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(parsingStatusChange:) 
			name:@"parsingStatusChangeNotification" object:nil];
	}
	return self;
}

- (void)parse{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	m_context = [[NSManagedObjectContext alloc] init];
	[m_context setPersistentStoreCoordinator:[[NSApp delegate] persistentStoreCoordinator]];
	[m_context setUndoManager:nil];
	[self parsePackageSummary];
	[self parsePackages];
	[m_connectionProxy parsingComplete];
	[m_context release];
	
	[pool release];
}

- (void)parsingStatusChange:(NSNotification *)notification{
	[m_connectionProxy setStatusMessage:[[notification userInfo] objectForKey:@"message"]];
}

- (void)parsePackageSummary{
	[m_connectionProxy setProgressIsIndeterminate:YES];
	[m_connectionProxy setStatusMessage:@"Parsing index"];
	AbstractXMLTreeParser *parser = [[PackageSummaryParser alloc] 
		initWithFile:[m_path stringByAppendingPathComponent:@"package-summary.html"] 
		context:m_context];
	[parser parse];
	[parser release];
}

- (void)parsePackages{
	NSEntityDescription *entityDescription = [NSEntityDescription
		entityForName:[PackageNode className] inManagedObjectContext:m_context];
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setEntity:entityDescription];
	NSError *error = nil;
	NSArray *packages = [m_context executeFetchRequest:request error:&error];
	[request release];
	
//	NSMutableArray *objectIDs = [[NSMutableArray alloc] init];
//	for (PackageNode *node in packages){
//		NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
//			[node objectID], @"objectId", 
//			node.filepath, @"filepath", 
//			node.name, @"name", 
//			nil];
//		[objectIDs addObject:dict];
//	}
	
	[m_connectionProxy setProgressIsIndeterminate:NO];
	[m_connectionProxy setMaxProgressValue:(double)[packages count]];
	unsigned int i = 0;
	
	for (PackageNode *pkg in packages){
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
//		NSManagedObjectID *objID = [dict objectForKey:@"objectId"];
//		NSString *path = [dict objectForKey:@"filepath"];
//		NSString *name = [dict objectForKey:@"name"];
		
//		PackageNode *pkg = (PackageNode *)[m_context objectWithID:objID];
		NSLog(@"%@", pkg);
		[m_connectionProxy setStatusMessage:[NSString stringWithFormat:@"Indexing %@",
			pkg.name]];
		AbstractXMLTreeParser *parser = [[PackageDetailParser alloc] initWithPackageNode:pkg 
			filename:pkg.filepath context:m_context];
		[parser parse];
		[parser release];
		i++;
		[m_connectionProxy setProgress:(double)i];
		NSError *error = nil;
		if (![m_context save:&error]){
			NSLog(@"Failed to save %@", [error userInfo]);
		}
		
		//[context refreshObject:pkg mergeChanges:NO];
		//[context reset];
        [pool release];
	}
//	[objectIDs release];
}

@end