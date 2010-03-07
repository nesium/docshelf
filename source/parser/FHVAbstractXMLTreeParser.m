//
//  AbstractXMLTreeParser.m
//  FlexHelpViewer
//
//  Created by Marc Bauer on 10.05.08.
//  Copyright 2008 nesiumdotcom. All rights reserved.
//

#import "FHVAbstractXMLTreeParser.h"

@implementation FHVAbstractXMLTreeParser

- (id)initWithURL:(NSURL *)url context:(FHVImportContext *)context{
	NSData *data = [NSData dataWithContentsOfURL:url];
	if (self = [self initWithData:data fromURL:url context:context]){
	}
	return self;
}

- (id)initWithData:(NSData *)data fromURL:(NSURL *)anURL context:(FHVImportContext *)context{
	if (self = [super init]){
		m_url = [anURL retain];
		m_context = [context retain];
		NSError *error = nil;
		m_xmlTree = [[NSXMLDocument alloc] initWithData:data options:NSXMLDocumentTidyHTML 
			error:&error];
		if (!m_xmlTree){
			NSLog(@"error while parsing file %@: %@", m_url, error);
			[self release];
			return nil;
		}
	}
	return self;
}

- (void)dealloc{
	[m_xmlTree release];
	[m_url release];
	[m_context release];
	[super dealloc];
}

- (NSXMLElement *)firstNodeForXPath:(NSString *)query ofElement:(NSXMLElement *)elem{
	if (!elem)
		elem = [m_xmlTree rootElement];
	NSError *error = nil;
	NSArray *nodes = [elem nodesForXPath:query error:&error];
	if (error){
		NSLog(@"error: %@", error);
		return nil;
	}
	if ([nodes count])
		return (NSXMLElement *)[nodes objectAtIndex:0];
	return nil;
}

- (NSArray *)summaryTableOfTypeToObjects:(NSString *)type{
	return [self summaryTableToObjects:[self summaryTableForType:type]];
}

- (NSArray *)summaryTableToObjects:(NSXMLElement *)table{
	NSArray *rows = [self rowsForSummaryTable:table];
	NSMutableArray *nodes = [NSMutableArray arrayWithCapacity:[rows count]];
	for (NSXMLElement *row in rows){
		[nodes addObject:[self componentsForSummaryTableRow:row]];
	}
	return nodes;
}

- (NSXMLElement *)summaryTable{
	NSError *error = nil;
	NSArray *potentialTables = [m_xmlTree nodesForXPath:@"/html/body/div/table[@class='summaryTable'][1]" 
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

- (NSXMLElement *)summaryTableForType:(NSString *)type{
	NSError *error = nil;
	NSArray *potentialTables = [m_xmlTree nodesForXPath:[NSString stringWithFormat:
	@"/html/body/div/a[@name='%@'][1]/following::table[@class='summaryTable'][1]", type]
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

- (NSMutableDictionary *)componentsForSummaryTableRow:(NSXMLElement *)row{
	NSError *error = nil;
	// Interfaces are enclosed by italic tags, thus //a
	NSArray *potentialAnchors = [row nodesForXPath:@"./td[@class='summaryTableSecondCol']//a[1]" 
		error:&error];
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
	
	NSArray *potentialDescriptions = [row nodesForXPath:@"./td[@class='summaryTableLastCol'][1]" 
		error:&error];
	NSString *description = [potentialDescriptions count] ? 
		[(NSXMLElement *)[potentialDescriptions objectAtIndex:0] stringValue] : @"";
	return [NSMutableDictionary dictionaryWithObjectsAndKeys:
		url, @"url", 
		[[m_url URLByDeletingLastPathComponent] URLByAppendingPathComponent:url], @"fileurl", 
		name, @"name", 
		description, @"summary", nil];
}

- (void)handleParsingError:(NSError *)error{
	NSLog(@"%@", error);
}

- (NSString *)_prepareAttributesInElement:(NSXMLElement *)elem{
	NSArray *links = [elem nodesForXPath:@".//a" error:nil];
	for (NSXMLElement *link in links){
		NSXMLNode *hrefAttrib = [link attributeForName:@"href"];
		if (!hrefAttrib){
			[link detach];
			continue;
		}
		NSString *href = [hrefAttrib stringValue];
		if (![href hasPrefix:@"/"] && ![href hasPrefix:@"http://"] && 
			![href hasPrefix:@"https://"] && ![href hasPrefix:@"mailto://"]){
			NSURL *url = [NSURL URLWithString:href relativeToURL:m_url];
			NSString *newHref = [NSString stringWithFormat:@"fhelpv://%@", [self _urlToIdent:url]];
			[hrefAttrib setStringValue:newHref];
		}
	}
	NSArray *images = [elem nodesForXPath:@".//img" error:nil];
	for (NSXMLElement *img in images){
		NSXMLNode *srcAttrib = [img attributeForName:@"src"];
		if (!srcAttrib){
			[img detach];
			continue;
		}
		NSURL *url = [NSURL URLWithString:[srcAttrib stringValue] relativeToURL:m_url];
		if ([[[url resourceSpecifier] lastPathComponent] isEqualToString:@"inherit-arrow.gif"])
			continue;
		NSString *ident = [m_context identForImageWithPath:[url path]];
		if (!ident){
			NSString *uuid = createUUID();
			ident = [uuid stringByAppendingPathExtension:[[url pathExtension] lowercaseString]];
			NSString *targetPath = [[m_context imagesPath] stringByAppendingPathComponent:ident];
			[uuid release];
			NSError *error = nil;
			if ([url isFileURL]){
				[[NSFileManager defaultManager] 
					copyItemAtPath:[url path] 
					toPath:targetPath
					error:&error];
			}else{
				NSData *imageData = [NSData dataWithContentsOfURL:url];
				[imageData writeToFile:targetPath options:0 error:&error];
			}
			if (error)
				NSLog(@"Could not copy %@", url);
			else{
				[m_context registerImageWithPath:[url path] ident:ident];
			}
		}
		[srcAttrib setStringValue:ident];
	}
	return [elem XMLStringWithOptions:0];
}

- (NSString *)_detailStringForLinkName:(NSString *)linkName{
	NSString *detailExpr = @"/html/body/div/a[@name='%@'][1]/following-sibling::div[@class='detailBody'][1]";
	NSXMLElement *detail = [self firstNodeForXPath:
		[NSString stringWithFormat:detailExpr, [linkName substringFromIndex:1]] 
		ofElement:nil];
	return [self _prepareAttributesInElement:detail];
}

- (NSString *)_urlToIdent:(NSURL *)url{
	NSString *ident = [[url absoluteURL] packageNameByResolvingAgainstBaseURL:m_context.sourceURL];
	if ([url fragment])
		ident = [NSString stringWithFormat:@"%@#%@", ident, [url fragment]];
	return ident;
}
@end