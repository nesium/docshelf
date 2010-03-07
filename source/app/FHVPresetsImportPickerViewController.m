//
//  FHVPresetsImportPickerViewController.m
//  EarthDoc
//
//  Created by Marc Bauer on 06.03.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import "FHVPresetsImportPickerViewController.h"


@implementation FHVPresetsImportPickerViewController

#pragma mark -
#pragma mark Initialization & Deallocation

- (id)init{
	if (self = [super init]){
		NSURL *presetsURL = [NSURL URLWithString:@"http://www.nesium.com/docset-presets/"];
		m_presetsURLConnection = [[NSMURLConnection alloc] 
			initWithURLRequest:[NSURLRequest requestWithURL:presetsURL] delegate:self];
		[m_presetsURLConnection start];
		[self _setBusy:YES];
	}
	return self;
}

- (void)dealloc{
	[m_presetsURLConnection cancel];
	[m_presetsURLConnection release];
	[super dealloc];
}



#pragma mark -
#pragma mark NSMURLConnectionDelegate methods

- (void)connectionDidFinishLoading:(NSMURLConnection *)connection success:(BOOL)success{
	if (success){
		NSDictionary *result = [m_presetsURLConnection.data yajl_JSON];
		[m_presetsArrayController setContent:[result objectForKey:@"entry"]];
		[self _setValid:YES];
	}
	[m_presetsURLConnection release];
	m_presetsURLConnection = nil;
	[self _setBusy:NO];
}
@end