//
//  FHVImportPickerViewController.m
//
//  Created by Marc Bauer on 06.03.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import "FHVAbstractImportPickerViewController.h"


@implementation FHVAbstractImportPickerViewController

@synthesize valid=m_valid, 
			busy=m_busy, 
			URL=m_url, 
			docSetName=m_docSetName;

#pragma mark -
#pragma mark Initialization & Deallocation

- (id)init{
	if (self = [super init]){
		m_url = nil;
		m_docSetName = nil;
		[self reset];
	}
	return self;
}

- (void)dealloc{
	[m_url release];
	[super dealloc];
}



#pragma mark -
#pragma mark Public methods

- (void)reset{
	[m_url release];
	m_url = nil;
	[m_docSetName release];
	m_docSetName = nil;
	m_valid = NO;
	m_busy = NO;
}



#pragma mark -
#pragma mark Protected methods

- (void)_setURL:(NSURL *)anURL{
	[self willChangeValueForKey:@"URL"];
	[anURL retain];
	[m_url release];
	m_url = anURL;
	[self didChangeValueForKey:@"URL"];
}

- (void)_setBusy:(BOOL)bFlag{
	[self willChangeValueForKey:@"busy"];
	m_busy = bFlag;
	[self didChangeValueForKey:@"busy"];
}

- (void)_setValid:(BOOL)bFlag{
	[self willChangeValueForKey:@"valid"];
	m_valid = bFlag;
	[self didChangeValueForKey:@"valid"];
}

- (void)_setDocSetName:(NSString *)aName{
	[self willChangeValueForKey:@"docSetName"];
	[aName retain];
	[m_docSetName release];
	m_docSetName = aName;
	[self didChangeValueForKey:@"docSetName"];
}
@end