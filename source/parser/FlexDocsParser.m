//
//  FlexDocsParser.m
//  FlexHelpViewer
//
//  Created by Marc Bauer on 10.05.08.
//  Copyright 2008 nesiumdotcom. All rights reserved.
//

#import "FlexDocsParser.h"
#import "FlexHelpViewerApp.h"

@interface FlexDocsParser (Private)
- (void)_createDocSetSkeleton:(NSString *)name;
@end


@implementation FlexDocsParser

@synthesize path=m_path;
FlexHelpViewerApp *m_connectionProxy;

- (id)initWithPath:(NSString *)path{
	if (self = [super init]){
		self.path = path;
		m_connectionProxy = (FlexHelpViewerApp *)[[NSConnection 
			connectionWithRegisteredName:@"com.nesium.FlexHelpViewer" host:nil] rootProxy];
		[self _createDocSetSkeleton:@"Test"];
	}
	return self;
}

- (void)dealloc{
	[m_path release];
	[m_context release];
	[super dealloc];
}

- (void)parse{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[m_connectionProxy setProgressIsIndeterminate:YES];
	[m_connectionProxy setStatusMessage:@"Parsing package infos ..."];
	PackageSummaryParser *summaryParser = [[PackageSummaryParser alloc] 
		initWithFile:[m_path stringByAppendingPathComponent:@"package-summary.html"] 
		context:m_context];
	NSArray *packages = [[summaryParser packages] retain];
	[summaryParser release];
	
	[m_connectionProxy setProgressIsIndeterminate:NO];

	NSMutableArray *classes = [[NSMutableArray alloc] init];	
	NSUInteger i = 0;
	NSAutoreleasePool *innerPool = [[NSAutoreleasePool alloc] init];
	for (NSMutableDictionary *package in packages){
		NSNumber *dbId = [m_importer savePackageWithName:[package objectForKey:@"name"] 
			summary:[package objectForKey:@"summary"]];
		[package setObject:dbId forKey:@"dbid"];
		
		PackageDetailParser *packageDetailParser = [[PackageDetailParser alloc] 
			initWithFile:[package objectForKey:@"filepath"] context:m_context];
		NSArray *constants = [packageDetailParser constants];
		NSArray *globalFunctions = [packageDetailParser globalFunctions];
		NSArray *currentClasses = [packageDetailParser classes];
		[currentClasses enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop){
			[obj setObject:dbId forKey:@"packageId"];
			[obj setObject:[NSNumber numberWithInt:kClassTypeClass] forKey:@"type"];
		}];
		NSArray *currentInterfaces = [packageDetailParser interfaces];
		[currentInterfaces enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop){
			[obj setObject:dbId forKey:@"packageId"];
			[obj setObject:[NSNumber numberWithInt:kClassTypeInterface] forKey:@"type"];
		}];
						
		[classes addObjectsFromArray:currentClasses];
		[classes addObjectsFromArray:currentInterfaces];		
		[packageDetailParser release];
		
		if ([constants count] > 0 || [globalFunctions count] > 0){
			NSString *path = [[[package objectForKey:@"filepath"] stringByDeletingLastPathComponent] 
				stringByAppendingPathComponent:@"package.html"];
			ClassDetailParser *classParser = [[ClassDetailParser alloc] initWithFile:path context:m_context];
			[m_importer saveSignatureNodes:[classParser methodsWithScope:PublicScope] 
				withParentType:kSigParentTypePackage parentId:dbId nodeType:kSigTypeFunction];
			[m_importer saveSignatureNodes:[classParser propertiesWithScope:PublicScope constants:YES] 
				withParentType:kSigParentTypePackage parentId:dbId nodeType:kSigTypeVariable];
			[classParser release];
		}
		[m_connectionProxy setProgress:((double)++i/((double)[packages count]/100.0))];
	}
	[innerPool release];
	
	__block double count = 0.0;
	double total = (double)[classes count];
	void (^notifier)(void) = ^(void){
		@synchronized (m_connectionProxy){
			count++;
			[m_connectionProxy setStatusMessage:[NSString stringWithFormat:@"Parsing classes (%d of %d) ...", 
				(int)count, (int)total]];
			[m_connectionProxy setProgress:(count/(total/100))];
		}
	};
	
	NSDate *startDate = [[NSDate date] retain];
	m_classParsingQueue = [[NSOperationQueue alloc] init];
	for (i = 0; i < [classes count];){
		NSUInteger len = MIN([classes count] - i, 300);
		NSArray *opClasses = [classes subarrayWithRange:(NSRange){i, len}];
		FHVClassParserOperation *op = [[FHVClassParserOperation alloc] initWithClasses:opClasses 
			notifier:notifier context:m_context];
		[m_classParsingQueue addOperation:op];
		[op release];
		i += len;
	}
	[m_classParsingQueue waitUntilAllOperationsAreFinished];
	NSLog(@"TIME TOTAL: %0.3f", [[NSDate date] timeIntervalSinceDate:startDate]);
	[m_classParsingQueue release];
	m_classParsingQueue = nil;
	[startDate release];
	
	[classes release];
	[packages release];
	
	[m_connectionProxy parsingComplete];
	[pool release];
}

- (void)_createDocSetSkeleton:(NSString *)name{
	NSString *bundlePath = [[[[[NSApp delegate] applicationSupportFolder] 
		stringByAppendingPathComponent:@"DocSets"] 
		stringByAppendingPathComponent:name] 
		stringByAppendingPathExtension:@"fhvdocset"];
	NSString *resourcesPath = [bundlePath stringByAppendingPathComponent:@"Resources"];
	NSString *bundleInfoPlistPath = [bundlePath stringByAppendingPathComponent:@"Info.plist"];
	NSString *bundleDataPath = [resourcesPath stringByAppendingPathComponent:@"Data.sql"];
	NSString *imagesPath = [resourcesPath stringByAppendingPathComponent:@"Images"];
	
	NSDictionary *mainInfoPlist = [[NSBundle mainBundle] infoDictionary];
	NSDictionary *bundleInfoPlist = [NSDictionary dictionaryWithObjectsAndKeys: 
		name, (NSString *)kCFBundleNameKey, 
		[mainInfoPlist objectForKey:(NSString *)kCFBundleVersionKey], (NSString *)kCFBundleVersionKey, 
		[mainInfoPlist objectForKey:@"CFBundleShortVersionString"], @"CFBundleShortVersionString", 
		nil];
	NSData *bundlePlistData = [NSPropertyListSerialization dataFromPropertyList:bundleInfoPlist 
		format:NSPropertyListXMLFormat_v1_0 errorDescription:nil];
		
	NSFileManager *fm = [NSFileManager defaultManager];
	if ([fm fileExistsAtPath:bundlePath]) [fm removeItemAtPath:bundlePath error:nil];
	[fm createDirectoryAtPath:imagesPath withIntermediateDirectories:YES attributes:nil error:nil];
	[bundlePlistData writeToFile:bundleInfoPlistPath options:0 error:nil];
	
	m_importer = [[SQLiteImporter alloc] initWithDBPath:bundleDataPath];	
	[m_importer open];
	m_context = [[FHVImportContext alloc] initWithPath:m_path imagesPath:imagesPath importer:m_importer];
}
@end