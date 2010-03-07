//
//  FHVClassParserOperation.m
//  FlexHelpViewer
//
//  Created by Marc Bauer on 15.01.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import "FHVClassParserOperation.h"


@implementation FHVClassParserOperation

- (id)initWithClasses:(NSArray *)classes notifier:(void (^)(void))notifier 
	context:(FHVImportContext *)context{
	if (self = [super init]){
		m_classes = [classes retain];
		m_notifier = notifier;
		m_context = [context retain];
	}
	return self;
}

- (void)dealloc{
	[m_classes release];
	[m_context retain];
	[super dealloc];
}

- (void)main{
	@try{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		int i = 0;
		for (NSDictionary *clazz in m_classes){
			if ([self isCancelled]) break;
			FHVClassDetailParser *classDetailParser = [[FHVClassDetailParser alloc] 
				initWithURL:[clazz objectForKey:@"fileurl"] context:m_context];
			NSArray *publicMethods = [classDetailParser methodsWithScope:PublicScope];
			NSArray *protectedMethods = [classDetailParser methodsWithScope:ProtectedScope];
			NSArray *publicProperties = [classDetailParser propertiesWithScope:PublicScope constants:NO];
			NSArray *protectedProperties = [classDetailParser propertiesWithScope:ProtectedScope constants:NO];
			NSArray *publicConstants = [classDetailParser propertiesWithScope:PublicScope constants:YES];
			NSArray *events = [classDetailParser events];
			NSString *clazzName = [clazz objectForKey:@"name"];
			
			// we synchronize here because of the shortcoming of sqlite3_last_insert_rowid
			// if we insert in multiple threads simultaneously we could read the wrong rowid
			@synchronized (m_context.importer){
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
				[m_context.importer saveSignatureNodes:protectedMethods withParentType:kSigParentTypeClass 
					parentId:dbId parentName:clazzName nodeType:kSigTypeFunction];
				[m_context.importer saveSignatureNodes:publicProperties withParentType:kSigParentTypeClass 
					parentId:dbId parentName:clazzName nodeType:kSigTypeVariable];
				[m_context.importer saveSignatureNodes:protectedProperties withParentType:kSigParentTypeClass 
					parentId:dbId parentName:clazzName nodeType:kSigTypeVariable];
				[m_context.importer saveSignatureNodes:publicConstants withParentType:kSigParentTypeClass 
					parentId:dbId parentName:clazzName nodeType:kSigTypeVariable];
				[m_context.importer saveSignatureNodes:events withParentType:kSigParentTypeClass 
					parentId:dbId parentName:clazzName nodeType:kSigTypeEvent];
			}
			
			[classDetailParser release];
			m_notifier();
			
			if (++i == 10){
				[pool release];
				pool = [[NSAutoreleasePool alloc] init];
				i = 0;
			}
		}
		[pool release];
	}@catch(...){}
}
@end