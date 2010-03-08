//
//  ClassDetailParser.m
//  FlexHelpViewer
//
//  Created by Marc Bauer on 11.05.08.
//  Copyright 2008 nesiumdotcom. All rights reserved.
//

#import "FHVClassDetailParser.h"

@interface FHVClassDetailParser (Private)
- (NSArray *)_rowsForClassSummaryTable:(NSString *)tableId;
@end


@implementation FHVClassDetailParser

- (id)initWithData:(NSData *)data fromURL:(NSURL *)anURL context:(FHVImportContext *)context{
	m_name = nil;
	if (self = [super initWithData:data fromURL:anURL context:context]){
		if ([[[anURL lastPathComponent] lowercaseString] isEqualToString:@"package.html"])
			m_name = nil;
		else{
			NSString *signatureExpr = @"/html/body/div[@class='MainContent'][1]/table[@class='classHeaderTable'][1]/tr/td[@class='classSignature'][1]";
			NSString *classSignature = [[[self firstNodeForXPath:signatureExpr ofElement:nil] stringValue] 
				stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			NSArray *parts = [classSignature componentsSeparatedByString:@" "];
			m_name = [[parts objectAtIndex:[parts count] - 1] retain];
		}
		m_ident = [[anURL packageNameByResolvingAgainstBaseURL:context.sourceURL] retain];
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
		
		NSURL *linkURL = [NSURL URLWithString:signatureLinkHref relativeToURL:m_url];
		BOOL isInherited = owner != nil;
		NSString *implementorIdent = nil;
		NSString *implementorName = nil;
		
		if (isInherited){
			NSURL *implementorURL = [NSURL URLWithString:[[owner attributeForName:@"href"] stringValue] 
				relativeToURL:m_url];
			implementorIdent = [implementorURL packageNameByResolvingAgainstBaseURL:
				m_context.sourceURL];
			implementorName = [[owner stringValue] stringByTrimmingCharactersInSet:set];
		}
		
		NSMutableDictionary *method = [NSMutableDictionary dictionaryWithObjectsAndKeys:
			[self _urlToIdent:linkURL], @"ident", 
			[signatureLink stringValue], @"name", 
			[self _prepareAttributesInElement:signature], @"signature", 
			[[summary stringValue] stringByTrimmingCharactersInSet:set], @"summary", 
			[NSNumber numberWithBool:isInherited], @"inherited", 
			nil];
		if (isInherited){
			[method setObject:implementorIdent forKey:@"implementorIdent"];
			[method setObject:implementorName forKey:@"implementorName"];
		}else{
			[method setObject:[self _detailStringForLinkName:signatureLinkHref] forKey:@"detail"];
		}
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
		
		NSURL *linkURL = [NSURL URLWithString:signatureLinkHref relativeToURL:m_url];
		NSString *implementorName = [[owner stringValue] stringByTrimmingCharactersInSet:set];
		NSString *implementorIdent = nil;
		BOOL isInherited = m_name != nil && ![implementorName isEqualToString:m_name];
		if (isInherited){
			NSXMLElement *anchor = [self firstNodeForXPath:@"a[1]" ofElement:owner];
			if (anchor){
				NSURL *implementorURL = [NSURL URLWithString:[[anchor attributeForName:@"href"] 
					stringValue] relativeToURL:m_url];
				implementorIdent = [implementorURL packageNameByResolvingAgainstBaseURL:
					m_context.sourceURL];
			}
		}
		
		NSMutableDictionary *property = [NSMutableDictionary dictionaryWithObjectsAndKeys:
			[self _urlToIdent:linkURL], @"ident", 
			[signatureLink stringValue], @"name", 
			[[summary stringValue] stringByTrimmingCharactersInSet:set], @"summary", 
			[signatureContainer stringValue], @"signature", 
			[NSNumber numberWithBool:isInherited], @"inherited", 
			[NSNumber numberWithBool:parseConstants], @"constant", 
			nil];
		if (isInherited){
			[property setObject:implementorName forKey:@"implementorName"];
			if (implementorIdent)
				[property setObject:implementorIdent forKey:@"implementorIdent"];
		}else{
			[property setObject:[self _detailStringForLinkName:signatureLinkHref] forKey:@"detail"];
		}
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
		
		NSURL *linkURL = [NSURL URLWithString:signatureLink relativeToURL:m_url];
		NSString *implementorName = [[owner stringValue] stringByTrimmingCharactersInSet:set];
		NSString *implementorIdent = nil;
		BOOL isInherited = ![implementorName isEqualToString:m_name];
		
		if (isInherited){
			NSXMLElement *anchor = [self firstNodeForXPath:@"a[1]" ofElement:owner];
			if (anchor){
				NSURL *implementorURL = [NSURL URLWithString:[[anchor attributeForName:@"href"] 
					stringValue] relativeToURL:m_url];
				implementorIdent = [implementorURL packageNameByResolvingAgainstBaseURL:
					m_context.sourceURL];
			}
		}
		
		NSMutableDictionary *event = [NSMutableDictionary dictionaryWithObjectsAndKeys: 
			[signature stringValue], @"name", 
			[self _prepareAttributesInElement:signature], @"signature", 
			[self _urlToIdent:linkURL], @"ident", 
			[[summary stringValue] stringByTrimmingCharactersInSet:set], @"summary", 
			[NSNumber numberWithBool:isInherited], @"inherited", 
			nil];
		if (isInherited){
			[event setObject:implementorName forKey:@"implementorName"];
			if (implementorIdent)
				[event setObject:implementorIdent forKey:@"implementorIdent"];
		}else{
			[event setObject:[self _detailStringForLinkName:signatureLink] forKey:@"detail"];
		}
			
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
	//remove header
	NSXMLElement *headerRow = [self firstNodeForXPath:@"./tr[1]" ofElement:table];
	[headerRow detach];
	NSError *error = nil;
	NSArray *rows = [table nodesForXPath:@"./tr" error:&error];
	return rows;
}
@end