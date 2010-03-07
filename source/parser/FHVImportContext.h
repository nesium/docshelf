//
//  FHVImportContext.h
//  FlexHelpViewer
//
//  Created by Marc Bauer on 16.01.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "sqlite3.h"
#import "FHVSQLiteImporter.h"


@interface FHVImportContext : NSObject{
	NSString *m_name;
	NSURL *m_sourceURL;
	NSString *m_imagesPath;
	NSString *m_tmpTargetPath;
	NSMutableDictionary *m_images;
	FHVSQLiteImporter *m_importer;
}
@property (readonly) NSString *name;
@property (readonly) NSURL *sourceURL;
@property (readonly) NSString *imagesPath;
@property (readonly) FHVSQLiteImporter *importer;
@property (readonly) NSString *temporaryTargetPath;
- (id)initWithName:(NSString *)aName sourceURL:(NSURL *)anURL imagesPath:(NSString *)imagesPath 
	importer:(FHVSQLiteImporter *)importer temporaryTargetPath:(NSString *)aTargetPath;
- (NSString *)identForImageWithPath:(NSString *)path;
- (void)registerImageWithPath:(NSString *)path ident:(NSString *)ident;
@end