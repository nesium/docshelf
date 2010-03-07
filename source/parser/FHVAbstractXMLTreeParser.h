//
//  AbstractXMLTreeParser.h
//  FlexHelpViewer
//
//  Created by Marc Bauer on 10.05.08.
//  Copyright 2008 nesiumdotcom. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FHVImportContext.h"
#import "NSString+FHVUtils.h"
#import "NSURL+FHVUtils.h"
#import "utils.h"


@interface FHVAbstractXMLTreeParser : NSObject{
	NSURL *m_url;
	NSXMLDocument *m_xmlTree;
	FHVImportContext *m_context;
}
- (id)initWithURL:(NSURL *)url context:(FHVImportContext *)context;
- (id)initWithData:(NSData *)data fromURL:(NSURL *)anURL context:(FHVImportContext *)context;
@end

@interface FHVAbstractXMLTreeParser (Protected)
- (NSXMLElement *)firstNodeForXPath:(NSString *)query ofElement:(NSXMLElement *)elem;
- (NSXMLElement *)summaryTable;
- (NSXMLElement *)summaryTableForType:(NSString *)type;
- (NSArray *)rowsForSummaryTable:(NSXMLElement *)table;
- (void)handleParsingError:(NSError *)error;
- (NSMutableDictionary *)componentsForSummaryTableRow:(NSXMLElement *)row;
- (NSArray *)summaryTableToObjects:(NSXMLElement *)table;
- (NSArray *)summaryTableOfTypeToObjects:(NSString *)type;
- (NSString *)_prepareAttributesInElement:(NSXMLElement *)elem;
- (NSString *)_detailStringForLinkName:(NSString *)linkName;
- (NSString *)_urlToIdent:(NSURL *)url;
@end