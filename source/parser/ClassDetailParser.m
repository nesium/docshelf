//
//  ClassDetailParser.m
//  FlexHelpViewer
//
//  Created by Marc Bauer on 11.05.08.
//  Copyright 2008 nesiumdotcom. All rights reserved.
//

#import "ClassDetailParser.h"

@interface ClassDetailParser (Private)
- (void)parseDetail;
- (void)parseMethodTableWithScope:(ASScope)scope;
- (void)parsePropertyTableWithScope:(ASScope)scope constants:(BOOL)parseConstants;
- (void)parseEventTable;
- (NSString *)detailStringForLinkName:(NSString *)linkName;
- (void)dispatchStatusMessage:(NSString *)message;
- (NSArray *)rowsForClassSummaryTable:(NSString *)tableId;
@end


@implementation ClassDetailParser

- (id)initWithClassNode:(ClassNode *)node context:(NSManagedObjectContext *)context{
	if (self = [super initWithFile:node.filepath]){
		m_classNode = [node retain];
		m_context = [context retain];
	}
	return self;
}

- (void)dealloc{
	[m_classNode release];
	[m_context release];
	[super dealloc];
}

- (void)parseTree{
	[self dispatchStatusMessage:[NSString stringWithFormat:@"%@::%@", m_classNode.parent.name,
		m_classNode.name]];
	[self parseDetail];
	[self parseMethodTableWithScope:PublicScope];
	[self parseMethodTableWithScope:ProtectedScope];
	[self parsePropertyTableWithScope:PublicScope constants:NO];
	[self parsePropertyTableWithScope:ProtectedScope constants:NO];
	[self parsePropertyTableWithScope:PublicScope constants:YES];
	[self parseEventTable];
}

- (void)parseDetail{
	m_classNode.detail = [[self firstNodeForXPath:@"/html/body/div[@class='MainContent'][1]" ofElement:nil] 
		XMLStringWithOptions:0]; //NSXMLNodePrettyPrint | NSXMLDocumentTidyHTML
}

- (void)parseMethodTableWithScope:(ASScope)scope{
	NSString *tableId = scope == PublicScope 
		? @"summaryTableMethod" 
		: @"summaryTableProtectedMethod";
	
	NSString *signatureExpr = @"./td/div[@class='summarySignature'][1]";
	NSString *summaryExpr = @"./td/div[@class='summaryTableDescription'][1]";
	NSString *ownerExpr = @"./td[@class='summaryTableOwnerCol'][1]";
	NSString *signatureLinkExpr = @"./a[@class='signatureLink'][1]";
	NSCharacterSet *set = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	
	NSArray *rows = [self rowsForClassSummaryTable:tableId];
	NSMutableSet *methods = [[NSMutableSet alloc] initWithCapacity:[rows count]];
	for (NSXMLElement *row in rows){
		NSXMLElement *signature = [self firstNodeForXPath:signatureExpr ofElement:row];
		NSXMLElement *summary = [self firstNodeForXPath:summaryExpr ofElement:row];
		NSXMLElement *owner = [self firstNodeForXPath:ownerExpr ofElement:row];
		NSString *signatureLink = [[[self firstNodeForXPath:signatureLinkExpr ofElement:signature] 
			attributeForName:@"href"] stringValue];
		
		NSURL *linkURL = [NSURL URLWithString:signatureLink 
			relativeToURL:[NSURL URLWithString:m_classNode.filepath]];
		BOOL isInheritated = ![[[owner stringValue] 
			stringByTrimmingCharactersInSet:set] isEqualToString:m_classNode.name];
		
		FunctionNode *method = [[FunctionNode alloc] 
			initWithManagedObjectContext:m_context];
		if (!isInheritated) method.detail = [self detailStringForLinkName:signatureLink];
		method.filepath = [linkURL absoluteString];
		method.signature = [[signature stringValue] stringByTrimmingCharactersInSet:set];
		method.summary = [[summary stringValue] 
			stringByTrimmingCharactersInSet:set];	
		method.isInherited = [NSNumber numberWithBool:isInheritated];
		method.parent = m_classNode;
		[methods addObject:method];
		[method release];
	}
	[m_classNode addEntities:methods];
	[methods release];
}

- (void)parsePropertyTableWithScope:(ASScope)scope constants:(BOOL)parseConstants{
	NSString *tableId = @"summaryTableConstant";
	if (!parseConstants){
		tableId = scope == PublicScope 
			? @"summaryTableProperty" 
			: @"summaryTableProtectedProperty";
	}
	
	NSString *signatureExpr = @"./td[@class='summaryTableSignatureCol'][1]";
	NSString *signatureLinkExpr = @"./a[@class='signatureLink'][1]";
	NSString *ownerExpr = @"./td[@class='summaryTableOwnerCol'][1]";
	NSString *summaryExpr = @"./div[@class='summaryTableDescription'][1]";
	NSCharacterSet *set = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	
	NSArray *rows = [self rowsForClassSummaryTable:tableId];
	NSMutableSet *properties = [[NSMutableSet alloc] initWithCapacity:[rows count]];
	for (NSXMLElement *row in rows){
		NSXMLElement *signatureContainer = [self firstNodeForXPath:signatureExpr ofElement:row];
		NSString *signatureLink = [[[self firstNodeForXPath:signatureLinkExpr 
			ofElement:signatureContainer] attributeForName:@"href"] stringValue];
		NSXMLElement *summary = [self firstNodeForXPath:summaryExpr ofElement:signatureContainer];
		[summary detach];
		NSXMLElement *owner = [self firstNodeForXPath:ownerExpr ofElement:row];
		
		NSURL *linkURL = [NSURL URLWithString:signatureLink 
			relativeToURL:[NSURL URLWithString:m_classNode.filepath]];
		BOOL isInherited = ![[[owner stringValue] 
			stringByTrimmingCharactersInSet:set] isEqualToString:m_classNode.name];
		
		VariableNode *property = [[VariableNode alloc] 
			initWithManagedObjectContext:m_context];
		property.filepath = [linkURL absoluteString];
		property.summary = [[summary stringValue] stringByTrimmingCharactersInSet:set];
		property.signature = [[signatureContainer stringValue] stringByTrimmingCharactersInSet:set];
		property.isInherited = [NSNumber numberWithBool:isInherited];
		property.isConstant = [NSNumber numberWithBool:parseConstants];
		property.parent = m_classNode;
		if (!isInherited) property.detail = [self detailStringForLinkName:signatureLink];
		[properties addObject:property];
		[property release];
	}
	[m_classNode addEntities:properties];
	[properties release];
}

- (void)parseEventTable{
	NSString *signatureExpr = @"./td/div[@class='summarySignature'][1]";
	NSString *summaryExpr = @"./td[starts-with(@class, 'summaryTableDescription')][1]";
	NSString *ownerExpr = @"./td[@class='summaryTableOwnerCol'][1]";
	NSString *signatureLinkExpr = @"./a[@class='signatureLink'][1]";
	NSCharacterSet *set = [NSCharacterSet whitespaceAndNewlineCharacterSet];

	NSArray *rows = [self rowsForClassSummaryTable:@"summaryTableEvent"];
	NSMutableSet *events = [[NSMutableSet alloc] initWithCapacity:[rows count]];
	for (NSXMLElement *row in rows){
		NSXMLElement *signature = [self firstNodeForXPath:signatureExpr ofElement:row];
		NSXMLElement *summary = [self firstNodeForXPath:summaryExpr ofElement:row];
		NSXMLElement *owner = [self firstNodeForXPath:ownerExpr ofElement:row];
		NSString *signatureLink = [[[self firstNodeForXPath:signatureLinkExpr ofElement:signature] 
			attributeForName:@"href"] stringValue];
		
		NSURL *linkURL = [NSURL URLWithString:signatureLink 
			relativeToURL:[NSURL URLWithString:m_classNode.filepath]];
		BOOL isInherited = ![[[owner stringValue] 
			stringByTrimmingCharactersInSet:set] isEqualToString:m_classNode.name];
		
		EventNode *event = [[EventNode alloc] 
			initWithManagedObjectContext:m_context];
		event.signature = [[signature stringValue] stringByTrimmingCharactersInSet:set];
		event.filepath = [linkURL absoluteString];
		event.summary = [[summary stringValue] 
			stringByTrimmingCharactersInSet:set];
		event.isInherited = [NSNumber numberWithBool:isInherited];
		event.parent = m_classNode;
		if (!isInherited) event.detail = [self detailStringForLinkName:signatureLink];
		[events addObject:event];
		[event release];
	}
	[m_classNode addEntities:events];
	[events release];
}

- (void)dispatchStatusMessage:(NSString *)message{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"parsingStatusChangeNotification" 
		object:self userInfo:[NSDictionary dictionaryWithObject:
			[NSString stringWithFormat:@"Indexing %@", message] forKey:@"message"]];
}

- (NSArray *)rowsForClassSummaryTable:(NSString *)tableId{
	NSXMLElement *table = [self firstNodeForXPath:[NSString 
		stringWithFormat:@"/html/body/div/table[@id='%@'][1]", tableId] ofElement:nil];
	//remove header
	NSXMLElement *headerRow = [self firstNodeForXPath:@"./tr[1]" ofElement:table];
	[headerRow detach];
	NSError *error = nil;
	NSArray *rows = [table nodesForXPath:@"./tr" error:&error];
	return rows;
}

- (NSString *)detailStringForLinkName:(NSString *)linkName{
	NSString *detailExpr = @"/html/body/div/a[@name='%@'][1]/following-sibling::div[@class='detailBody'][1]";
	NSXMLElement *detail = [self firstNodeForXPath:
		[NSString stringWithFormat:detailExpr, [linkName substringFromIndex:1]] 
		ofElement:nil];
	return [detail XMLStringWithOptions:NSXMLNodePrettyPrint | NSXMLDocumentTidyHTML];
}

@end