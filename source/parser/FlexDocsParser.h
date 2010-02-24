//
//  FlexDocsParser.h
//  FlexHelpViewer
//
//  Created by Marc Bauer on 10.05.08.
//  Copyright 2008 nesiumdotcom. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FHVConstants.h"
#import "AbstractXMLTreeParser.h"
#import "PackageSummaryParser.h"
#import "PackageDetailParser.h"
#import "FHVClassParserOperation.h"
#import "FHVImportContext.h"
#import "utils.h"
#import "SQLiteImporter.h"
#import "NSFileManager+NSMAdditions.h"
#import "NSString+NSMAdditions.h"

@protocol FlexDocsParserConnectionDelegate
- (void)setStatusMessage:(NSString *)message;
- (void)setProgressIsIndeterminate:(BOOL)bFlag;
- (void)setMaxProgressValue:(double)value;
- (void)setProgress:(double)progress;
- (void)parsingComplete:(NSError *)error;
@end


@interface FlexDocsParser : NSObject{
	NSString *m_path;
	NSOperationQueue *m_classParsingQueue;
	FHVImportContext *m_context;
	SQLiteImporter *m_importer;
	id <FlexDocsParserConnectionDelegate> m_connectionProxy;
}
@property (retain) NSString *path;
- (id)initWithPath:(NSString *)path docSetName:(NSString *)docSetName;
- (void)parse;
@end