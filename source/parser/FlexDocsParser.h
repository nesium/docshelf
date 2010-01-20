//
//  FlexDocsParser.h
//  FlexHelpViewer
//
//  Created by Marc Bauer on 10.05.08.
//  Copyright 2008 nesiumdotcom. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AbstractXMLTreeParser.h"
#import "PackageSummaryParser.h"
#import "PackageDetailParser.h"
#import "FHVClassParserOperation.h"
#import "FHVImportContext.h"
#import "utils.h"
#import "SQLiteImporter.h"


@interface FlexDocsParser : NSObject{
	NSString *m_path;
	NSOperationQueue *m_classParsingQueue;
	FHVImportContext *m_context;
	SQLiteImporter *m_importer;
}
@property (retain) NSString *path;
- (id)initWithPath:(NSString *)path;
- (void)parse;
@end