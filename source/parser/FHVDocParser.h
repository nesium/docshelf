//
//  FlexDocsParser.h
//  FlexHelpViewer
//
//  Created by Marc Bauer on 10.05.08.
//  Copyright 2008 nesiumdotcom. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FHVConstants.h"
#import "FHVAbstractXMLTreeParser.h"
#import "FHVPackageSummaryParser.h"
#import "FHVPackageDetailParser.h"
#import "FHVClassParserOperation.h"
#import "FHVImportContext.h"
#import "utils.h"
#import "FHVSQLiteImporter.h"
#import "NSFileManager+NSMAdditions.h"
#import "NSString+NSMAdditions.h"
#import "NSDate+NSMAdditions.h"

@protocol FlexDocsParserConnectionDelegate
- (oneway void)setStatusMessage:(NSString *)message;
- (oneway void)setProgressIsIndeterminate:(BOOL)bFlag;
- (oneway void)setMaxProgressValue:(double)value;
- (oneway void)setProgress:(double)progress;
- (oneway void)parsingComplete:(NSError *)error;
@end


@interface FHVDocParser : NSObject{
	NSURL *m_url;
	NSOperationQueue *m_classParsingQueue;
	FHVImportContext *m_context;
	FHVSQLiteImporter *m_importer;
	NSDistantObject <FlexDocsParserConnectionDelegate> *m_connectionProxy;
	BOOL m_isCancelled;
}
@property (readonly) BOOL isCancelled;
- (id)initWithURL:(NSURL *)url docSetName:(NSString *)docSetName;
- (void)parse;
- (void)cancel;
@end