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
	NSString *m_path;
	NSString *m_imagesPath;
	NSMutableDictionary *m_images;
	SQLiteImporter *m_importer;
}
@property (readonly) NSString *path;
@property (readonly) NSString *imagesPath;
@property (readonly) SQLiteImporter *importer;
- (id)initWithPath:(NSString *)aPath imagesPath:(NSString *)imagesPath 
	importer:(SQLiteImporter *)importer;
- (NSString *)identForImageWithPath:(NSString *)path;
- (void)registerImageWithPath:(NSString *)path ident:(NSString *)ident;
@end