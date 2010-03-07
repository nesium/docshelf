//
//  FHVRemoteImportPickerViewController.m
//  EarthDoc
//
//  Created by Marc Bauer on 06.03.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import "FHVRemoteImportPickerViewController.h"


@implementation FHVRemoteImportPickerViewController

#pragma mark -
#pragma mark Initialization & Deallocation

- (id)init{
	if (self = [super init]){
		m_connection = nil;
	}
	return self;
}

- (void)dealloc{
	[m_connection cancel];
	[m_connection release];
	[super dealloc];
}



#pragma mark -
#pragma mark Public methods

- (void)setURLString:(NSString *)aString{
	[m_remoteAddressTextField setStringValue:aString];
	NSString *urlString = [aString stringByAppendingPathComponent:@"package-summary.html"];
	m_connection = [[NSMURLConnection alloc] 
		initWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]] 
		delegate:self];
	[self _setBusy:YES];
}



#pragma mark -
#pragma mark NSMURLConnectionDelegate methods

- (void)connectionDidFinishLoading:(NSMURLConnection *)connection success:(BOOL)success{
	if (success){
		PackageSummaryParser *parser = [[PackageSummaryParser alloc] initWithData:connection.data 
			fromURL:[connection.request URL] context:nil];
		NSString *title = parser.title;
		success = title != nil;
		if (title) [m_nameTextField setStringValue:parser.title];
	}
	if (!success)
		[m_warningIcon setToolTip:@"No valid ASDocs found at path"];
	[m_connection release];
	m_connection = nil;
	[m_warningIcon setHidden:success];
	[self _setValid:success];
	[self _setBusy:NO];
}
@end