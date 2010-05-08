//
//  FHVRemoteImportPickerViewController.m
//
//  Created by Marc Bauer on 06.03.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import "FHVRemoteImportPickerViewController.h"

@interface FHVRemoteImportPickerViewController (Private)
- (void)_performURLSanityCheck;
- (void)_cancelURLSanityCheck;
- (void)_updateValidity;
@end


@implementation FHVRemoteImportPickerViewController

#pragma mark -
#pragma mark Initialization & Deallocation

- (id)init{
	if (self = [super init]){
		m_connection = nil;
		m_urlIsValid = NO;
	}
	return self;
}

- (void)awakeFromNib{
	[m_remoteAddressTextField sendActionOn:NSAnyEventMask];
	[m_nameTextField sendActionOn:NSAnyEventMask];
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
	m_urlIsValid = NO;
	[self _updateValidity];
	[self _performURLSanityCheck];
}

- (void)reset{
	[super reset];
	m_urlIsValid = NO;
	[self _cancelURLSanityCheck];
	[m_remoteAddressTextField setStringValue:@""];
	[m_nameTextField setStringValue:@""];
	[m_warningIcon setHidden:YES];
}

- (NSURL *)URL{
	return [NSURL URLWithString:[[m_remoteAddressTextField stringValue] 
		stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
}

- (NSString *)docSetName{
	return [[m_nameTextField stringValue] stringByTrimmingCharactersInSet:
		[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}



#pragma mark -
#pragma mark IB Actions

- (IBAction)addressTextField_didEndEditing:(id)sender{
	[self _performURLSanityCheck];
}



#pragma mark -
#pragma mark NSTextField notifications

- (void)controlTextDidChange:(NSNotification *)aNotification{
	if ([aNotification object] == m_remoteAddressTextField){
		[self _cancelURLSanityCheck];
		m_urlIsValid = NO;
		[self _setValid:NO];
	}else{
		[self _updateValidity];
	}
}



#pragma mark -
#pragma mark NSMURLConnectionDelegate methods

- (void)connectionDidFinishLoading:(NSMURLConnection *)connection success:(BOOL)success{
	if (!success){
		if ([m_connection.error code] == NSMURLConnectionIllegalMIMETypeError){
			[m_warningIcon setToolTip:@"No valid ASDocs found"];
		}else{
			[m_warningIcon setToolTip:@"Could not load data from URL!"];
		}
		NDCLog(@"%@", m_connection.error);
		[m_warningIcon setHidden:NO];
		m_urlIsValid = NO;
		[self _updateValidity];
		[self _setBusy:NO];
		return;
	}
	
	NSError *error = nil;
	FHVPackageSummaryParser *parser = [[FHVPackageSummaryParser alloc] initWithData:connection.data 
		fromURL:[connection.request URL] context:nil error:&error];
	NSString *title = parser.title;
	if (title){
		[m_warningIcon setHidden:YES];
		[m_nameTextField setStringValue:title];
		m_urlIsValid = YES;
		[self _updateValidity];
	}else{
		[m_warningIcon setHidden:NO];
		[m_warningIcon setToolTip:@"No valid ASDocs found"];
		m_urlIsValid = NO;
		[self _updateValidity];
		NDCLog(@"%@", [error localizedDescription]);
	}
	[self _cancelURLSanityCheck];
}



#pragma mark -
#pragma mark Private methods

- (void)_performURLSanityCheck{
	if (m_urlIsValid)
		return;
	
	NSString *value = [[m_remoteAddressTextField stringValue] 
		stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		
	if (![value length]){
		[m_warningIcon setHidden:YES];
		[self _cancelURLSanityCheck];
		return;
	}
	if (![value nsm_isURL]){
		[m_warningIcon setHidden:NO];
		[m_warningIcon setToolTip:@"Not a valid URL!"];
		[self _cancelURLSanityCheck];
		return;
	}
	
	NSURL *url = [NSURL URLWithString:[value stringByAppendingPathComponent:@"package-summary.html"]];
	if ([[m_connection.request URL] isEqual:url])
		return;
	
	[self _cancelURLSanityCheck];
	m_connection = [[NSMURLConnection alloc] initWithURLRequest:[NSURLRequest requestWithURL:url] 
		delegate:self];
	m_connection.allowedMIMETypes = [NSArray arrayWithObject:@"text/html"];
	[m_connection start];
	[self _setBusy:YES];
}

- (void)_cancelURLSanityCheck{
	[m_connection cancel];
	[m_connection release];
	m_connection = nil;
	[self _setBusy:NO];
}

- (void)_updateValidity{
	NSString *name = [[m_nameTextField stringValue] 
		stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	[self _setValid:(m_urlIsValid && [name length] > 0)];
}
@end