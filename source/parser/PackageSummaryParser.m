//
//  PackageSummaryParser.m
//  FlexHelpViewer
//
//  Created by Marc Bauer on 09.05.08.
//  Copyright 2008 nesiumdotcom. All rights reserved.
//

#import "PackageSummaryParser.h"


@implementation PackageSummaryParser

- (NSString *)title{
	NSError *error = nil;
	NSArray *matchingNodes = [m_xmlTree nodesForXPath:@"/html/body//table[@id='titleTable'][1]/tr[1]/td[@class='titleTableTitle'][1]" 
		error:&error];
	if (![matchingNodes count])
		return nil;
	NSXMLElement *elem = [matchingNodes objectAtIndex:0];
	return [[elem stringValue] 
		stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSArray *)packages{
	NSError *error = nil;
	NSArray *rows = [self rowsForSummaryTable:[self summaryTable]];
	NSMutableArray *packages = [NSMutableArray arrayWithCapacity:[rows count]];
	for (NSXMLNode *row in rows){
		NSXMLElement *anchor = [[row nodesForXPath:@"./td/a[starts-with(@onclick, 'javascript:loadClassListFrame')][1]" 
			error:&error] objectAtIndex:0];
		NSString *name = [anchor stringValue];
		NSString *filepath = [[m_filePath stringByDeletingLastPathComponent] 
			stringByAppendingPathComponent: [[anchor attributeForName:@"href"] stringValue]];
		NSString *summary = [[[row nodesForXPath:@"./td[@class='summaryTableLastCol'][1]" 
			error:&error] objectAtIndex:0] stringValue];
		NSMutableDictionary *package = [NSMutableDictionary dictionaryWithObjectsAndKeys:
			summary, @"summary", name, @"name", filepath, @"filepath", nil];
		[packages addObject:package];
	}
	return packages;
}
@end