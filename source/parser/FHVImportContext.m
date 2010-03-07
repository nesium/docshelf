//
//  FHVImportContext.m
//  FlexHelpViewer
//
//  Created by Marc Bauer on 16.01.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import "FHVImportContext.h"


@implementation FHVImportContext

@synthesize sourceURL=m_sourceURL, 
			imagesPath=m_imagesPath, 
			importer=m_importer, 
			temporaryTargetPath=m_tmpTargetPath, 
			name=m_name;

- (id)initWithName:(NSString *)aName sourceURL:(NSURL *)anURL imagesPath:(NSString *)imagesPath 
	importer:(FHVSQLiteImporter *)importer temporaryTargetPath:(NSString *)aTargetPath{
	if (self = [super init]){
		m_name = [aName retain];
		m_sourceURL = [anURL retain];
		m_images = [[NSMutableDictionary alloc] init];
		m_imagesPath = [imagesPath retain];
		m_importer = [importer retain];
		m_tmpTargetPath = [aTargetPath retain];
	}
	return self;
}

- (void)dealloc{
	[m_name release];
	[m_importer release];
	[m_sourceURL release];
	[m_images release];
	[m_tmpTargetPath release];
	[super dealloc];
}

- (NSString *)identForImageWithPath:(NSString *)path{
	NSString *ident = nil;
	@synchronized (m_images){
		ident = [m_images objectForKey:path];
	}
	return ident;
}

- (void)registerImageWithPath:(NSString *)path ident:(NSString *)ident{
	@synchronized (m_images){
		[m_images setObject:ident forKey:path];
	}
}
@end