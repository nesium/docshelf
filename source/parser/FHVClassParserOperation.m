//
//  FHVClassParserOperation.m
//  FlexHelpViewer
//
//  Created by Marc Bauer on 15.01.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import "FHVClassParserOperation.h"


@implementation FHVClassParserOperation

@synthesize error=m_error;

- (id)initWithClasses:(NSArray *)classes context:(FHVImportContext *)context{
	if (self = [super init]){
		m_classes = [classes retain];
		m_context = [context retain];
		m_error = nil;
	}
	return self;
}

- (void)dealloc{
	[m_error release];
	[m_classes release];
	[m_context retain];
	[super dealloc];
}

- (void)main{
//	@try{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		int i = 0;
		for (NSDictionary *clazz in m_classes){
			if ([self isCancelled]) break;
			NDCLog(@"parse %@", [clazz objectForKey:@"name"]);
			FHVClassDetailParser *classDetailParser = [[FHVClassDetailParser alloc] 
				initWithURL:[clazz objectForKey:@"fileurl"] context:m_context error:&m_error];
			if (!classDetailParser){
				[m_error retain];
				[self willChangeValueForKey:@"error"];
				[self didChangeValueForKey:@"error"];
			}
			NSArray *publicMethods = [classDetailParser methodsWithScope:PublicScope];
			NSArray *protectedMethods = [classDetailParser methodsWithScope:ProtectedScope];
			NSArray *publicProperties = [classDetailParser propertiesWithScope:PublicScope constants:NO];
			NSArray *protectedProperties = [classDetailParser propertiesWithScope:ProtectedScope constants:NO];
			NSArray *publicConstants = [classDetailParser propertiesWithScope:PublicScope constants:YES];
			NSArray *events = [classDetailParser events];
			NSString *clazzName = [clazz objectForKey:@"name"];
			
			// we synchronize here because of the shortcoming of sqlite3_last_insert_rowid
			// if we insert in multiple threads simultaneously we could read the wrong rowid
			[m_context.importerLock lock];
			
			if ([self isCancelled]){
				[m_context.importerLock unlock];
				break;
			}
			
			NSNumber *dbId = [m_context.importer saveClassWithName:clazzName 
				summary:[clazz objectForKey:@"summary"] 
				ident:[classDetailParser ident] 
				detail:[classDetailParser detail] 
				type:[[clazz objectForKey:@"type"] intValue] 
				packageId:[clazz objectForKey:@"packageId"]];
			
			if ([publicMethods count] == 0){
				NSLog(@"num methods: %d - %@", [publicMethods count], [clazz objectForKey:@"name"]);
			}
			
			[m_context.importer saveSignatureNodes:publicMethods withParentType:kSigParentTypeClass 
				parentId:dbId parentName:clazzName nodeType:kSigTypeFunction];
			if ([self isCancelled]){
				[m_context.importerLock unlock];
				break;
			}
			
			[m_context.importer saveSignatureNodes:protectedMethods withParentType:kSigParentTypeClass 
				parentId:dbId parentName:clazzName nodeType:kSigTypeFunction];
			if ([self isCancelled]){
				[m_context.importerLock unlock];
				break;
			}
			
			[m_context.importer saveSignatureNodes:publicProperties withParentType:kSigParentTypeClass 
				parentId:dbId parentName:clazzName nodeType:kSigTypeVariable];
			if ([self isCancelled]){
				[m_context.importerLock unlock];
				break;
			}
			
			[m_context.importer saveSignatureNodes:protectedProperties withParentType:kSigParentTypeClass 
				parentId:dbId parentName:clazzName nodeType:kSigTypeVariable];
			if ([self isCancelled]){
				[m_context.importerLock unlock];
				break;
			}
			
			[m_context.importer saveSignatureNodes:publicConstants withParentType:kSigParentTypeClass 
				parentId:dbId parentName:clazzName nodeType:kSigTypeVariable];
			if ([self isCancelled]){
				[m_context.importerLock unlock];
				break;
			}
			
			[m_context.importer saveSignatureNodes:events withParentType:kSigParentTypeClass 
				parentId:dbId parentName:clazzName nodeType:kSigTypeEvent];
			
			[m_context.importerLock unlock];
			
			[classDetailParser release];
			[m_context countParsedClass];
			
			if (++i == 10){
				[pool release];
				pool = [[NSAutoreleasePool alloc] init];
				i = 0;
			}
		}
		[pool release];
//	}@catch(NSException *exception){
//		NSLog(@"An exception occured while importing! Name: %@, Reason: %@, UserInfo: %@\n%@", 
//			[exception name], [exception reason], [exception userInfo], 
//			[exception callStackSymbols]);
//	}
}
@end