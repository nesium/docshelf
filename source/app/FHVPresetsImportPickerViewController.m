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

- (void)awakeFromNib{
	[m_presetsArrayController addObserver:self forKeyPath:@"selectionIndexes" options:0 context:NULL];
}

- (void)dealloc{
	[m_presetsArrayController removeObserver:self forKeyPath:@"selectionIndexes"];
	[m_presetsURLConnection cancel];
	[m_presetsURLConnection release];
	[super dealloc];
}



#pragma mark -
#pragma mark Public methods

- (void)reset{
}



#pragma mark -
#pragma mark KVO Notifications

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change 
	context:(void *)context{
	if (![[m_presetsArrayController selectedObjects] count]){
		[self _setURL:nil];
		[self _setDocSetName:nil];
		[self _setValid:NO];
	}else{
		NSDictionary *item = [[m_presetsArrayController selectedObjects] objectAtIndex:0];
		[self _setURL:[NSURL URLWithString:[item objectForKey:@"url"]]];
		[self _setDocSetName:[item objectForKey:@"name"]];
		[self _setValid:YES];
	}
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