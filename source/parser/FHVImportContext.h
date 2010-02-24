//
//  FHVImportContext.h
//  FlexHelpViewer
//
//  Created by Marc Bauer on 16.01.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "sqlite3.h"
#import "SQLiteImporter.h"


@interface FHVImportContext : NSObject{
	NSString *m_name;
	NSString *m_sourcePath;
	NSString *m_imagesPath;
	NSString *m_tmpTargetPath;
	NSMutableDictionary *m_images;
	SQLiteImporter *m_importer;
}
@property (readonly) NSString *name;
@property (readonly) NSString *sourcePath;
@property (readonly) NSString *imagesPath;
@property (readonly) SQLiteImporter *importer;
@property (readonly) NSString *temporaryTargetPath;
- (id)initWithName:(NSString *)aName sourcePath:(NSString *)aPath imagesPath:(NSString *)imagesPath 
	importer:(SQLiteImporter *)importer temporaryTargetPath:(NSString *)aTargetPath;
- (NSString *)identForImageWithPath:(NSString *)path;
- (void)registerImageWithPath:(NSString *)path ident:(NSString *)ident;
@end