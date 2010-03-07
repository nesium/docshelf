//
//  PSURLConnection.m
//  ProSieben
//
//  Created by Marc Bauer on 06.02.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import "NSMURLConnection.h"


@implementation NSMURLConnection

@synthesize data=m_data, 
			success=m_success, 
			complete=m_complete, 
			request=m_request, 
			response=m_response;

#pragma mark -
#pragma mark Initialization & Deallocation

- (id)initWithURLRequest:(NSURLRequest *)aRequest delegate:(id<NSMURLConnectionDelegate>)delegate{
	if (self = [super init]){
		m_connection = [[NSURLConnection alloc] initWithRequest:aRequest delegate:self];
		m_data = [[NSMutableData alloc] init];
		m_delegate = delegate;
		m_complete = NO;
		m_success = NO;
		m_response = nil;
		m_request = [aRequest retain];
	}
	return self;
}

- (void)dealloc{
	[m_connection release];
	[m_data release];
	[m_response release];
	[m_request release];
	[super dealloc];
}



#pragma mark -
#pragma mark Public methods

- (void)start{
	[m_connection start];
}

- (void)cancel{
	[m_connection cancel];
}

- (NSString *)stringValue{
	return [[[NSString alloc] initWithData:m_data encoding:NSUTF8StringEncoding] autorelease];
}

- (CGFloat)estimatedProgress{
	if (!m_response || ![m_response expectedContentLength])
		return 0.0f;
	return (CGFloat)[m_data length] / (CGFloat)[m_response expectedContentLength];
}



#pragma mark -
#pragma mark NSConnection delegate methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
	m_response = [response retain];
	[m_data setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
	[m_data appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
	m_success = YES;
	m_complete = YES;
	if ([(id)m_delegate respondsToSelector:@selector(connectionDidFinishLoading:success:)])
		[m_delegate connectionDidFinishLoading:self success:YES];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
	m_success = NO;
	m_complete = YES;
	if ([(id)m_delegate respondsToSelector:@selector(connectionDidFinishLoading:success:)])
		[m_delegate connectionDidFinishLoading:self success:NO];
}
@end