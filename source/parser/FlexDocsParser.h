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
- (oneway void)setStatusMessage:(NSString *)message;
- (oneway void)setProgressIsIndeterminate:(BOOL)bFlag;
- (oneway void)setMaxProgressValue:(double)value;
- (oneway void)setProgress:(double)progress;
- (oneway void)parsingComplete:(NSError *)error;
@end


@interface FlexDocsParser : NSObject{
	NSString *m_path;
	NSOperationQueue *m_classParsingQueue;
	FHVImportContext *m_context;
	SQLiteImporter *m_importer;
	NSDistantObject <FlexDocsParserConnectionDelegate> *m_connectionProxy;
	BOOL m_isCancelled;
}
@property (retain) NSString *path;
@property (readonly) BOOL isCancelled;
- (id)initWithPath:(NSString *)path docSetName:(NSString *)docSetName;
- (void)parse;
- (void)cancel;
@end