//
//  AbstractXMLTreeParser.h
//  FlexHelpViewer
//
//  Created by Marc Bauer on 10.05.08.
//  Copyright 2008 nesiumdotcom. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AbstractNode.h"


@interface AbstractXMLTreeParser : NSObject{
	NSString *m_filePath;
	NSXMLDocument *m_xmlTree;
}
- (id)initWithFile:(NSString *)file;
- (void)parse;
- (id)objectValue;
@end

@interface AbstractXMLTreeParser (Protected)
- (void)parseTree;
- (NSXMLElement *)firstNodeForXPath:(NSString *)query ofElement:(NSXMLElement *)elem;
- (NSXMLElement *)summaryTable;
- (NSXMLElement *)summaryTableForType:(NSString *)type;
- (NSArray *)rowsForSummaryTable:(NSXMLElement *)table;
- (void)handleParsingError:(NSError *)error;
- (NSDictionary *)componentsForSummaryTableRow:(NSXMLElement *)row;
- (NSSet *)summaryTable:(NSXMLElement *)table toNodes:(Class)nodeClass 
	context:(NSManagedObjectContext *)context;
- (NSSet *)summaryTableOfType:(NSString *)type toNodes:(Class)nodeClass 
	context:(NSManagedObjectContext *)context;
@end