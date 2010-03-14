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
#import "FlexDocsParserConnectionDelegate.h"


@interface FHVImportContext : NSObject{
	NSString *m_name;
	NSURL *m_sourceURL;
	NSString *m_imagesPath;
	NSString *m_tmpTargetPath;
	NSMutableDictionary *m_images;
	FHVSQLiteImporter *m_importer;
	NSDistantObject <FlexDocsParserConnectionDelegate> *m_connectionProxy;
	NSUInteger m_numClasses;
	NSUInteger m_numParsedClasses;
	NSLock *m_importerLock;
}
@property (readonly) NSString *name;
@property (readonly) NSURL *sourceURL;
@property (readonly) NSString *imagesPath;
@property (readonly) FHVSQLiteImporter *importer;
@property (readonly) NSString *temporaryTargetPath;
@property (readonly) NSLock *importerLock;
@property (nonatomic, assign) NSUInteger numClasses;
- (id)initWithName:(NSString *)aName sourceURL:(NSURL *)anURL imagesPath:(NSString *)imagesPath 
	importer:(FHVSQLiteImporter *)importer temporaryTargetPath:(NSString *)aTargetPath 
	connectionProxy:(NSDistantObject <FlexDocsParserConnectionDelegate> *)connectionProxy;
- (NSString *)identForImageWithPath:(NSString *)path;
- (void)registerImageWithPath:(NSString *)path ident:(NSString *)ident;
- (void)countParsedClass;
@end