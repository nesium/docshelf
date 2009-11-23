//
//  AbstractXMLTreeParser.m
//  FlexHelpViewer
//
//  Created by Marc Bauer on 10.05.08.
//  Copyright 2008 nesiumdotcom. All rights reserved.
//

#import "AbstractXMLTreeParser.h"

@interface AbstractXMLTreeParser (Private)
- (void)parseFile;
@end


@implementation AbstractXMLTreeParser

- (id)initWithFile:(NSString *)file{
	if (self = [super init]){
		m_filePath = [file retain];
	}
	return self;
}

- (void)dealloc{
	NSLog(@"-> DEALLOC");
	[m_xmlTree release];
	[m_filePath release];
	[super dealloc];
}

- (void)parse{
	[self parseFile];
	[self parseTree];
	[m_xmlTree release];
	m_xmlTree = nil;
}

- (void)parseFile{
    NSError *error = nil;
	m_xmlTree = [[NSXMLDocument alloc] initWithContentsOfURL:[NSURL fileURLWithPath:m_filePath]
		options:NSXMLDocumentTidyHTML error:&error];
	
    if (m_xmlTree == nil){
		//NSLog(@"error while parsing file %@: %@", m_filePath, error);
		return;
    }

    if (error){
		//NSLog(@"error not nil: %@", error);
	}
}

- (NSXMLElement *)firstNodeForXPath:(NSString *)query ofElement:(NSXMLElement *)elem{
	if (!elem){
		elem = [m_xmlTree rootElement];
	}
	NSError *error = nil;
	NSArray *nodes = [elem nodesForXPath:query error:&error];
	if (error){
		NSLog(@"error: %@", error);
		return nil;
	}
	if ([nodes count]){
		return (NSXMLElement *)[nodes objectAtIndex:0];
	}
	return nil;
}

- (NSSet *)summaryTableOfType:(NSString *)type toNodes:(Class)nodeClass 
	context:(NSManagedObjectContext *)context{
	return [self summaryTable:[self summaryTableForType:type] toNodes:nodeClass context:context];
}

- (NSSet *)summaryTable:(NSXMLElement *)table toNodes:(Class)nodeClass 
	context:(NSManagedObjectContext *)context{
	NSArray *rows = [self rowsForSummaryTable:table];
	NSMutableSet *nodes = [[[NSMutableSet alloc] initWithCapacity:[rows count]] autorelease];
	for (NSXMLElement *row in rows){
		AbstractNode *node = (AbstractNode *)[[nodeClass alloc] 
			initWithManagedObjectContext:context];
		NSDictionary *components = [self componentsForSummaryTableRow:row];
		node.name = [components objectForKey:@"name"];
		node.summary = [components objectForKey:@"description"];
		node.filepath = [[m_filePath stringByDeletingLastPathComponent] 
			stringByAppendingPathComponent:[components objectForKey:@"url"]];
		[nodes addObject:node];
		[node release];
	}
	return nodes;
}

- (NSXMLElement *)summaryTable{
	NSError *error = nil;
	NSArray *potentialTables = [m_xmlTree nodesForXPath:@"//table[@class='summaryTable']" 
		error:&error];
	if (error)
	{
		[self handleParsingError:error];
		return nil;
	}
	if (![potentialTables count])
	{
		return nil;
	}
	return (NSXMLElement *)[potentialTables objectAtIndex:0];
}

- (NSXMLElement *)summaryTableForType:(NSString *)type{
	NSError *error = nil;
	NSArray *potentialTables = [m_xmlTree nodesForXPath:[NSString stringWithFormat:
	@"//a[@name='%@']/following::table[@class='summaryTable']", type]
		error:&error];
	if (error){
		[self handleParsingError:error];
		return nil;
	}
	if (![potentialTables count]){
		return nil;
	}
	return (NSXMLElement *)[potentialTables objectAtIndex:0];
}

- (NSArray *)rowsForSummaryTable:(NSXMLElement *)table{
	NSError *error = nil;
	NSArray *rows = [table nodesForXPath:@"./tr[starts-with(@class, 'prow')]" 
		error:&error];
	if (error){
		[self handleParsingError:error];
		return nil;
	}
	return rows;
}

- (NSDictionary *)componentsForSummaryTableRow:(NSXMLElement *)row{
	NSError *error = nil;
	NSArray *potentialAnchors = [row nodesForXPath:@"./td[@class='summaryTableSecondCol']\
		/descendant::a" error:&error];
	if (error){
		[self handleParsingError:error];
		return nil;
	}
	if (![potentialAnchors count]){
		return nil;
	}
	NSXMLElement *anchor = (NSXMLElement *)[potentialAnchors objectAtIndex:0];
	NSString *url = [[anchor attributeForName:@"href"] stringValue];
	NSString *name = [anchor stringValue];
	NSArray *potentialDescriptions = [row nodesForXPath:@".//td[@class='summaryTableLastCol']" 
		error:&error];
	NSString *description = [potentialDescriptions count] ? 
		[(NSXMLElement *)[potentialDescriptions objectAtIndex:0] stringValue] : @"";
	return [NSDictionary dictionaryWithObjectsAndKeys:url, @"url", name, @"name", 
		description, @"description", nil];
}

- (void)handleParsingError:(NSError *)error{
	NSLog(@"%@", error);
}

- (id)objectValue{
	return nil;
}

@end