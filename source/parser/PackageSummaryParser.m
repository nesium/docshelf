//
//  PackageSummaryParser.m
//  FlexHelpViewer
//
//  Created by Marc Bauer on 09.05.08.
//  Copyright 2008 nesiumdotcom. All rights reserved.
//

#import "PackageSummaryParser.h"


@implementation PackageSummaryParser

- (id)initWithFile:(NSString *)file context:(NSManagedObjectContext *)context{
	if (self = [super initWithFile:file]){
		m_context = [context retain];
	}
	return self;
}

- (void)dealloc{
	[m_context release];
	[super dealloc];
}

- (void)parseTree{
	NSError *error = nil;
	NSArray *rows = [self rowsForSummaryTable:[self summaryTable]];
	PackageNode *lastPackage = nil;
	
	for (NSXMLNode *row in rows){
		NSXMLElement *anchor = [[row nodesForXPath:@".//a[starts-with(@onclick, 'javascript:loadClassListFrame')]" 
			error:&error] objectAtIndex:0];
		NSString *name = [anchor stringValue];
		NSString *filepath = [[m_filePath stringByDeletingLastPathComponent] 
			stringByAppendingPathComponent: [[anchor attributeForName:@"href"] stringValue]];
		NSString *summary = [[[row nodesForXPath:@".//td[@class='summaryTableLastCol']" 
			error:&error] objectAtIndex:0] stringValue];
		PackageNode *package = [[PackageNode alloc] initWithManagedObjectContext:m_context];
		package.summary = summary;
		package.name = name;
		package.filepath = filepath;
		
		if (lastPackage && [name hasPrefix:lastPackage.name]){
			//name = [name substringFromIndex:[lastPackage.name length] + 1];
			package.parent = lastPackage;
		}
		else if (lastPackage && lastPackage.parent){
			AbstractNode *parent = lastPackage.parent;
			while (parent){
				if ([name hasPrefix:parent.name]){
					//name = [name substringFromIndex:[parent.name length] + 1];
					package.parent = parent;
					break;
				}
				parent = parent.parent;
			}
		}
		lastPackage = package;
		[package release];
	}
}

@end