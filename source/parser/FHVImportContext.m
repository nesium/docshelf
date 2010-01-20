//
//  FHVImportContext.m
//  FlexHelpViewer
//
//  Created by Marc Bauer on 16.01.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import "FHVImportContext.h"


@implementation FHVImportContext

@synthesize path=m_path, 
			imagesPath=m_imagesPath, 
			importer=m_importer;

- (id)initWithPath:(NSString *)aPath imagesPath:(NSString *)imagesPath 
	importer:(SQLiteImporter *)importer{
	if (self = [super init]){
		m_path = [aPath retain];
		m_images = [[NSMutableDictionary alloc] init];
		m_imagesPath = [imagesPath retain];
		m_importer = [importer retain];
	}
	return self;
}

- (void)dealloc{
	[m_importer release];
	[m_path release];
	[m_images release];
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