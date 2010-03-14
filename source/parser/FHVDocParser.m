//
//  FlexDocsParser.m
//  FlexHelpViewer
//
//  Created by Marc Bauer on 10.05.08.
//  Copyright 2008 nesiumdotcom. All rights reserved.
//

#import "FHVDocParser.h"

@interface FHVDocParser (Private)
- (void)_createDocSetSkeleton:(NSString *)name;
- (BOOL)_moveToFinalDestination;
- (void)_finish;
@end


@implementation FHVDocParser

@synthesize isCancelled=m_isCancelled;

#pragma mark -
#pragma mark Initialization & Deallocation

- (id)initWithURL:(NSURL *)url docSetName:(NSString *)docSetName{
	if (self = [super init]){
		m_url = [url retain];
		m_isCancelled = NO;
		m_classParsingQueue = nil;
		m_error = nil;
		m_connectionProxy = (NSDistantObject <FlexDocsParserConnectionDelegate> *)[[NSConnection 
			connectionWithRegisteredName:@"com.nesium.FlexHelpViewer" host:nil] rootProxy];
		[m_connectionProxy setProtocolForProxy:@protocol(FlexDocsParserConnectionDelegate)];
		[self _createDocSetSkeleton:docSetName];
	}
	return self;
}

- (void)dealloc{
	[m_startDate release];
	[m_url release];
	[m_context release];
	[m_error release];
	[super dealloc];
}



#pragma mark -
#pragma mark Public methods

- (void)parse{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[m_connectionProxy setProgressIsIndeterminate:YES];
	[m_connectionProxy setStatusMessage:@"Parsing package infos ..."];
	
	if (m_isCancelled || m_error)
		goto bailout;
	
	NSURL *summaryURL = [m_url URLByAppendingPathComponent:@"package-summary.html"];
	FHVPackageSummaryParser *summaryParser = [[FHVPackageSummaryParser alloc] 
		initWithURL:summaryURL 
		context:m_context 
		error:&m_error];
	if (!summaryParser){
		[m_error retain];
		goto bailout;
	}
	
	{
		NSArray *packages = [[summaryParser packages] retain];
		[summaryParser release];
		
		[m_connectionProxy setProgressIsIndeterminate:NO];

		NSMutableArray *classes = [[NSMutableArray alloc] init];	
		NSUInteger i = 0;
		NSAutoreleasePool *innerPool = [[NSAutoreleasePool alloc] init];
		for (NSMutableDictionary *package in packages){
			if (m_isCancelled){
				[classes release];
				classes = nil;
				[innerPool release];
				[packages release];
				packages = nil;
				goto bailout;
			}
		
			NSString *packageName = [package objectForKey:@"name"];
			NSNumber *dbId = [m_importer savePackageWithName:packageName 
				summary:[package objectForKey:@"summary"]];
			[package setObject:dbId forKey:@"dbid"];
			
			FHVPackageDetailParser *packageDetailParser = [[FHVPackageDetailParser alloc] 
				initWithURL:[package objectForKey:@"fileurl"] 
				context:m_context 
				error:&m_error];
			if (!packageDetailParser){
				[m_error retain];
				[packages release];
				[classes release];
				[innerPool release];
				goto bailout;
			}
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
				NSURL *url = [[[package objectForKey:@"fileurl"] URLByDeletingLastPathComponent] 
					URLByAppendingPathComponent:@"package.html"];
				FHVClassDetailParser *classParser = [[FHVClassDetailParser alloc] 
					initWithURL:url 
					context:m_context 
					error:&m_error];
				if (!classParser){
					[m_error retain];
					[packages release];
					[classes release];
					[innerPool release];
					goto bailout;
				}
				[m_importer saveSignatureNodes:[classParser methodsWithScope:PublicScope] 
					withParentType:kSigParentTypePackage parentId:dbId parentName:packageName 
					nodeType:kSigTypeFunction];
				[m_importer saveSignatureNodes:[classParser propertiesWithScope:PublicScope constants:YES] 
					withParentType:kSigParentTypePackage parentId:dbId parentName:packageName 
					nodeType:kSigTypeVariable];
				[classParser release];
			}
			[m_connectionProxy setProgress:((double)++i/((double)[packages count]/100.0))];
		}
		[innerPool release];
		
		m_context.numClasses = [classes count];
		
		m_startDate = [[NSDate date] retain];
		m_classParsingQueue = [[NSOperationQueue alloc] init];
		for (i = 0; i < [classes count];){
			NSUInteger len = MIN([classes count] - i, 300);
			NSArray *opClasses = [classes subarrayWithRange:(NSRange){i, len}];
			FHVClassParserOperation *op = [[FHVClassParserOperation alloc] initWithClasses:opClasses 
				context:m_context];
			[op addObserver:self forKeyPath:@"error" options:0 context:NULL];
			[op addObserver:self forKeyPath:@"isFinished" options:0 context:NULL];
			[m_classParsingQueue addOperation:op];
			[op release];
			i += len;
		}
		
		[classes release];
		[packages release];
		
		[m_classParsingQueue addObserver:self forKeyPath:@"operationCount" options:0 context:0];
	}
	
bailout:
	if (m_error != nil || m_isCancelled){
		[m_importer close];
		[[NSFileManager defaultManager] removeItemAtPath:m_context.temporaryTargetPath error:nil];
		[m_connectionProxy parsingComplete:m_error];
		m_connectionProxy = nil;
	}
	[pool release];
}

- (void)cancel{
	if (m_isCancelled) return;
	m_isCancelled = YES;
	[m_classParsingQueue cancelAllOperations];
	NDCLog(@"CANCEL!");
}


#pragma mark -
#pragma mark KVO Notifications

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change 
	context:(void *)context{
	NDCLog(@"HELLO! %@ %d", keyPath, [m_classParsingQueue operationCount]);
	if (object == m_classParsingQueue){
		if ([m_classParsingQueue operationCount] == 0)
			[self _finish];
	}else{
		if ([keyPath isEqualToString:@"error"]){
			m_error = [[(FHVClassParserOperation *)object error] copy];
			[self cancel];
		}else{
			[object removeObserver:self forKeyPath:@"error"];
			[object removeObserver:self forKeyPath:@"isFinished"];
		}
	}
}



#pragma mark -
#pragma mark Private methods

- (void)_finish{
	NDCLog(@"TIME TOTAL: %0.3f", [[NSDate date] timeIntervalSinceDate:m_startDate]);
	
	if (!m_error && !m_isCancelled){
		[m_classParsingQueue release];
		m_classParsingQueue = nil;
		[m_connectionProxy setProgressIsIndeterminate:YES];
		[m_connectionProxy setStatusMessage:@"Creating indexes ..."];
		BOOL success = [m_importer createIndexes:&m_error];
		if (!success){
			[m_error retain];
		}
		[m_importer commit];
		[m_importer close];
		[self _moveToFinalDestination];
	}else{
		[m_importer close];
		[[NSFileManager defaultManager] removeItemAtPath:m_context.temporaryTargetPath error:nil];	
	}
	[m_connectionProxy parsingComplete:m_error];
	m_connectionProxy = nil;
}

- (void)_createDocSetSkeleton:(NSString *)name{
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *bundlePath = [[fm nsm_temporaryDirectory] 
		stringByAppendingPathComponent:[NSString nsm_uuid]];
	NSString *resourcesPath = [bundlePath stringByAppendingPathComponent:@"Resources"];
	NSString *bundleInfoPlistPath = [bundlePath stringByAppendingPathComponent:@"Info.plist"];
	NSString *bundleDataPath = [resourcesPath stringByAppendingPathComponent:@"Data.sql"];
	NSString *imagesPath = [resourcesPath stringByAppendingPathComponent:@"Images"];
	
	NSDictionary *mainInfoPlist = [[NSBundle mainBundle] infoDictionary];
	NSDictionary *bundleInfoPlist = [NSDictionary dictionaryWithObjectsAndKeys: 
		name, (NSString *)kCFBundleNameKey, 
		[NSString nsm_uuid], @"FHVDocSetId", 
		[NSNumber numberWithBool:YES], @"FHVInSearchIncluded", 
		[m_url absoluteString], @"FHVSource", 
		[[NSDate date] stringWithDateFormat:@"yyyy-MM-dd HH:mm:ss Z"], @"FHVCreationDate", 
		[mainInfoPlist objectForKey:(NSString *)kCFBundleVersionKey], (NSString *)kCFBundleVersionKey, 
		[mainInfoPlist objectForKey:@"CFBundleShortVersionString"], @"CFBundleShortVersionString", 
		nil];
	NSString *errorString = nil;
	NSData *bundlePlistData = [NSPropertyListSerialization dataFromPropertyList:bundleInfoPlist 
		format:NSPropertyListXMLFormat_v1_0 errorDescription:&errorString];
	if (errorString){
		m_error = [[NSError 
			errorWithDomain:NSPOSIXErrorDomain 
			code:-1 
			description:[NSString stringWithFormat:@"Could not serialize Plist data. %@", 
				errorString]] retain];
		NSLog(@"%@", bundleInfoPlist);
		[errorString release];
		return;
	}
	
	if ([fm fileExistsAtPath:bundlePath]) [fm removeItemAtPath:bundlePath error:nil];
	NSError *error = nil;
	BOOL success = [fm createDirectoryAtPath:imagesPath withIntermediateDirectories:YES 
		attributes:nil error:&error];
	if (!success){
		m_error = [[NSError 
			errorWithDomain:[error domain] 
			code:[error code] 
			description:[NSString stringWithFormat:@"Could not create docset folder at %@. %@", 
				imagesPath, [error localizedDescription]]] retain];
		return;
	}
	
	success = [bundlePlistData writeToFile:bundleInfoPlistPath options:0 error:&error];
	if (!success){
		m_error = [[NSError 
			errorWithDomain:[error domain] 
			code:[error code] 
			description:[NSString stringWithFormat:@"Could not create plist at %@. %@", 
				bundleInfoPlistPath, [error localizedDescription]]] retain];
		return;
	}
	
	m_importer = [[FHVSQLiteImporter alloc] initWithDBPath:bundleDataPath];	
	success = [m_importer open:&m_error];
	if (!success){
		[m_error retain];
		return;
	}
	m_context = [[FHVImportContext alloc] initWithName:name sourceURL:m_url 
		imagesPath:imagesPath importer:m_importer temporaryTargetPath:bundlePath 
		connectionProxy:m_connectionProxy];
}

- (BOOL)_moveToFinalDestination{
	NSString *bundleFolder = FHVDocSetsFolder();
	NSError *error = nil;
	BOOL success;
	NSFileManager *fm = [NSFileManager defaultManager];
	if (![fm fileExistsAtPath:bundleFolder]){
		success = [fm createDirectoryAtPath:bundleFolder withIntermediateDirectories:YES 
			attributes:nil error:&error];
		if (!success){
			m_error = [[NSError 
				errorWithDomain:[error domain] 
				code:[error code] 
				description:[NSString stringWithFormat:@"Could not create bundle folder at %@. %@", 
					[error localizedDescription]]] retain];
			return NO;
		}
	}
	NSString *filename = [fm nsm_nextAvailableFileNameAtPath:bundleFolder 
		proposedFileName:[[m_context.name nsm_normalizedFilename] 
			stringByAppendingPathExtension:@"fhvdocset"] scheme:nil];
	NSString *targetPath = [bundleFolder stringByAppendingPathComponent:filename];
	success = [fm moveItemAtPath:m_context.temporaryTargetPath toPath:targetPath error:&error];
	if (!success){
		m_error = [[NSError 
			errorWithDomain:[error domain] 
			code:[error code] 
			description:[NSString stringWithFormat:@"Could not move docset to final destination %@. %@", 
				targetPath, [error localizedDescription]]] retain];
		return NO;
	}
	return YES;
}
@end