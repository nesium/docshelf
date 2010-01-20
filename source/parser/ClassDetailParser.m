//
//  ClassDetailParser.m
//  FlexHelpViewer
//
//  Created by Marc Bauer on 11.05.08.
//  Copyright 2008 nesiumdotcom. All rights reserved.
//

#import "ClassDetailParser.h"

@interface ClassDetailParser (Private)
- (NSString *)_detailStringForLinkName:(NSString *)linkName;
- (NSArray *)_rowsForClassSummaryTable:(NSString *)tableId;
- (NSString *)_prepareAttributesInElement:(NSXMLElement *)elem;
@end


@implementation ClassDetailParser

- (id)initWithFile:(NSString *)file context:(FHVImportContext *)context{
	m_name = nil;
	if (self = [super initWithFile:file context:context]){
		if ([[[file lastPathComponent] lowercaseString] isEqualToString:@"package.html"])
			m_name = nil;
		else{
			m_name = [[[self firstNodeForXPath:@"/html/body/div[@id='banner'][1]/table[@class='titleTable'][1]//h1[1]" 
				ofElement:nil] stringValue] retain];
		}
		m_ident = [[file packageNameByResolvingAgainstBasePath:context.path] retain];
	}
	return self;
}

- (void)dealloc{
	[m_name release];
	[m_ident release];
	[super dealloc];
}

- (NSString *)name{
	return m_name;
}

- (NSString *)ident{
	return m_ident;
}

- (NSString *)detail{
	NSXMLElement *detailElem = [self firstNodeForXPath:@"/html/body/div[@class='MainContent'][1]" 
		ofElement:nil];
	return [self _prepareAttributesInElement:detailElem];
}

- (NSArray *)methodsWithScope:(ASScope)scope{
	NSString *tableId = scope == PublicScope 
		? @"summaryTableMethod" 
		: @"summaryTableProtectedMethod";
	
	NSString *signatureExpr = @"./td/div[@class='summarySignature'][1]";
	NSString *summaryExpr = @"./td/div[@class='summaryTableDescription'][1]";
	NSString *ownerExpr = @"./td[@class='summaryTableOwnerCol'][1]/a[1]";
	NSString *signatureLinkExpr = @"./a[@class='signatureLink'][1]";
	NSCharacterSet *set = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	
	NSArray *rows = [self _rowsForClassSummaryTable:tableId];
	NSMutableArray *methods = [NSMutableArray arrayWithCapacity:[rows count]];
	for (NSXMLElement *row in rows){
		NSXMLElement *signature = [self firstNodeForXPath:signatureExpr ofElement:row];
		NSXMLElement *summary = [self firstNodeForXPath:summaryExpr ofElement:row];
		NSXMLElement *owner = [self firstNodeForXPath:ownerExpr ofElement:row];
		NSXMLElement *signatureLink = [self firstNodeForXPath:signatureLinkExpr ofElement:signature];
		NSString *signatureLinkHref = [[signatureLink attributeForName:@"href"] stringValue];
		
		NSURL *linkURL = [NSURL URLWithString:signatureLinkHref relativeToURL:m_fileURL];
		BOOL isInherited = owner != nil;
		NSURL *implementorURL = nil;
		
		if (isInherited){
			implementorURL = [NSURL URLWithString:[[owner attributeForName:@"href"] stringValue] 
				relativeToURL:m_fileURL];
//			NSLog(@"%@", [[implementorURL absoluteString] 
//				packageNameByResolvingAgainstBasePath:m_context.path]);
		}
		
		NSDictionary *method = [NSDictionary dictionaryWithObjectsAndKeys: 
			[self _urlToIdent:linkURL], @"ident", 
			[signatureLink stringValue], @"name", 
			[self _prepareAttributesInElement:signature], @"signature", 
			[[summary stringValue] stringByTrimmingCharactersInSet:set], @"summary", 
			[NSNumber numberWithBool:isInherited], @"inherited", 
			(isInherited ? nil : [self _detailStringForLinkName:signatureLinkHref]), @"detail", 
			nil];
		[methods addObject:method];
	}
	return methods;
}

- (NSArray *)propertiesWithScope:(ASScope)scope constants:(BOOL)parseConstants{
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
	
	NSArray *rows = [self _rowsForClassSummaryTable:tableId];
	NSMutableArray *properties = [NSMutableArray arrayWithCapacity:[rows count]];
	for (NSXMLElement *row in rows){
		NSXMLElement *signatureContainer = [self firstNodeForXPath:signatureExpr ofElement:row];
		NSXMLElement *signatureLink = [self firstNodeForXPath:signatureLinkExpr 
			ofElement:signatureContainer];
		NSString *signatureLinkHref = [[signatureLink attributeForName:@"href"] stringValue];
		
		NSXMLElement *summary = [self firstNodeForXPath:summaryExpr ofElement:signatureContainer];
		[summary detach];
		NSXMLElement *owner = [self firstNodeForXPath:ownerExpr ofElement:row];
		
		NSURL *linkURL = [NSURL URLWithString:signatureLinkHref 
			relativeToURL:[NSURL URLWithString:m_filePath]];
		BOOL isInherited = m_name != nil && ![[[owner stringValue] 
			stringByTrimmingCharactersInSet:set] isEqualToString:m_name];
		
		NSDictionary *property = [NSDictionary dictionaryWithObjectsAndKeys:
			[self _urlToIdent:linkURL], @"ident", 
			[signatureLink stringValue], @"name", 
			[[summary stringValue] stringByTrimmingCharactersInSet:set], @"summary", 
			[self _prepareAttributesInElement:signatureLink], @"signature", 
			[NSNumber numberWithBool:isInherited], @"inherited", 
			[NSNumber numberWithBool:parseConstants], @"constant", 
			(isInherited ? nil : [self _detailStringForLinkName:signatureLinkHref]), @"detail", 
			nil];
		[properties addObject:property];
	}
	return properties;
}

- (NSArray *)events{
	NSString *signatureExpr = @"./td/div[@class='summarySignature'][1]";
	NSString *summaryExpr = @"./td[starts-with(@class, 'summaryTableDescription')][1]";
	NSString *ownerExpr = @"./td[@class='summaryTableOwnerCol'][1]";
	NSString *signatureLinkExpr = @"./a[@class='signatureLink'][1]";
	NSCharacterSet *set = [NSCharacterSet whitespaceAndNewlineCharacterSet];

	NSArray *rows = [self _rowsForClassSummaryTable:@"summaryTableEvent"];
	NSMutableArray *events = [NSMutableArray arrayWithCapacity:[rows count]];
	for (NSXMLElement *row in rows){
		NSXMLElement *signature = [self firstNodeForXPath:signatureExpr ofElement:row];
		NSXMLElement *summary = [self firstNodeForXPath:summaryExpr ofElement:row];
		NSXMLElement *owner = [self firstNodeForXPath:ownerExpr ofElement:row];
		NSString *signatureLink = [[[self firstNodeForXPath:signatureLinkExpr ofElement:signature] 
			attributeForName:@"href"] stringValue];
		
		NSURL *linkURL = [NSURL URLWithString:signatureLink 
			relativeToURL:[NSURL URLWithString:m_filePath]];
		BOOL isInherited = ![[[owner stringValue] 
			stringByTrimmingCharactersInSet:set] isEqualToString:m_name];
		
		NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys: 
			[self _prepareAttributesInElement:signature], @"signature", 
			[self _urlToIdent:linkURL], @"ident", 
			[[summary stringValue] stringByTrimmingCharactersInSet:set], @"summary", 
			[NSNumber numberWithBool:isInherited], @"inherited", 
			(isInherited ? nil : [self _detailStringForLinkName:signatureLink]), @"detail", 
			nil];
		[events addObject:event];
	}
	return events;
}

- (NSArray *)_rowsForClassSummaryTable:(NSString *)tableId{
	NSString *summaryTableExp = m_name == nil 
		? @"/html/body/div[@class='MainContent'][1]//table[@id='%@'][1]" 
		: @"/html/body/div/table[@id='%@'][1]";

	NSXMLElement *table = [self firstNodeForXPath:[NSString 
		stringWithFormat:summaryTableExp, tableId] ofElement:nil];
//	if (!table){
//		NSLog(@"%@ - %@ - %@", tableId, m_name, m_filePath);
//	}
	//remove header
	NSXMLElement *headerRow = [self firstNodeForXPath:@"./tr[1]" ofElement:table];
	[headerRow detach];
	NSError *error = nil;
	NSArray *rows = [table nodesForXPath:@"./tr" error:&error];
	return rows;
}
@end