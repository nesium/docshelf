//
//  PackageDetailParser.m
//  FlexHelpViewer
//
//  Created by Marc Bauer on 10.05.08.
//  Copyright 2008 nesiumdotcom. All rights reserved.
//

#import "FHVPackageDetailParser.h"

@implementation FHVPackageDetailParser

- (id)initWithData:(NSData *)data fromURL:(NSURL *)anURL context:(FHVImportContext *)context 
	error:(NSError **)error{
	if (self = [super initWithData:data fromURL:anURL context:context error:error]){
		m_name = [[[self firstNodeForXPath:@"/html/body/div[@id='banner'][1]/table[@class='titleTable'][1]//h1[1]" 
			ofElement:nil] stringValue] retain];
	}
	return self;
}

- (void)dealloc{
	[m_name release];
	[super dealloc];
}

- (NSString *)name{
	return m_name;
}

- (NSArray *)globalFunctions{
	NSArray *functions = [self summaryTableOfTypeToObjects:@"methodSummary"];
	return functions;
}

- (NSArray *)classes{
	NSArray *classes = [self summaryTableOfTypeToObjects:@"classSummary"];
	return classes;
}

- (NSArray *)interfaces{
	NSArray *interfaces = [self summaryTableOfTypeToObjects:@"interfaceSummary"];
	return interfaces;
}

- (NSArray *)constants{
	NSArray *constants = [self summaryTableOfTypeToObjects:@"constantSummary"];
	return constants;
}
@end