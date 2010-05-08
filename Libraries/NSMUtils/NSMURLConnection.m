//
//  PSURLConnection.m
//  ProSieben
//
//  Created by Marc Bauer on 06.02.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import "NSMURLConnection.h"

NSString *const NSMURLConnectionErrorDomain = @"NSMURLConnectionErrorDomain";
OSStatus const NSMURLConnectionIllegalMIMETypeError = 1001;
OSStatus const NSMURLConnectionIllegalStatusCodeError = 1002;

@interface NSMURLConnection (Private)
- (void)_failWithError:(NSError *)error retry:(BOOL)retry;
- (void)_retry;
@end


@implementation NSMURLConnection

@synthesize data=m_data, 
			success=m_success, 
			complete=m_complete, 
			request=m_request, 
			response=m_response, 
			maxAttempts=m_maxAttempts, 
			allowedMIMETypes=m_allowedMIMETypes, 
			treatsNonSuccessStatusCodesAsErrors=m_treatsNonSuccessStatusCodesAsErrors, 
			statusCode=m_statusCode, 
			error=m_error;

#pragma mark -
#pragma mark Initialization & Deallocation

- (id)initWithURLRequest:(NSURLRequest *)aRequest{
	return [self initWithURLRequest:aRequest delegate:nil];
}

- (id)initWithURLRequest:(NSURLRequest *)aRequest delegate:(id<NSMURLConnectionDelegate>)delegate{
	if (self = [super init]){
		m_connection = [[NSURLConnection alloc] initWithRequest:aRequest delegate:self 
			startImmediately:NO];
		m_data = [[NSMutableData alloc] init];
		m_delegate = delegate;
		m_complete = NO;
		m_success = NO;
		m_response = nil;
		m_request = [aRequest retain];
		m_failedAttempts = 0;
		m_maxAttempts = 3;
		m_allowedMIMETypes = nil;
		m_statusCode = -1;
		m_treatsNonSuccessStatusCodesAsErrors = YES;
		m_error = nil;
	}
	return self;
}

- (void)dealloc{
	[m_allowedMIMETypes release];
	[m_connection release];
	[m_data release];
	[m_response release];
	[m_request release];
	[m_error release];
	[super dealloc];
}



#pragma mark -
#pragma mark Public methods

- (void)start{
	[m_connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[m_connection start];
}

- (void)startSynchronously{
	[self start];
	while (!m_complete){
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
	}
}

- (void)cancel{
	[m_connection cancel];
	m_complete = YES;
}

- (NSString *)stringValue{
	// @TODO use textEncodingName from response (if set)
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
	
	if (m_allowedMIMETypes && ![m_allowedMIMETypes containsObject:[response MIMEType]]){
		NDCLog(@"Received non-allowed mime type: %@", [response MIMEType]);
		[m_connection cancel];
		NSError *error = [NSError 
			errorWithDomain:NSMURLConnectionErrorDomain 
			code:NSMURLConnectionIllegalMIMETypeError 
			description:[NSString stringWithFormat:@"Received illegal MIME type %@", 
				[response MIMEType]]];
		[self _failWithError:error retry:NO];
		return;
	}
	
	if ([response isKindOfClass:[NSHTTPURLResponse class]]){
		NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
		m_statusCode = [httpResponse statusCode];
		if (m_statusCode != 200 && m_treatsNonSuccessStatusCodesAsErrors){
			[m_connection cancel];
			NSError *error = [NSError 
				errorWithDomain:NSMURLConnectionErrorDomain 
				code:NSMURLConnectionIllegalStatusCodeError 
				description:[NSString stringWithFormat:@"Server returned \"%@\" (%d)", 
					[NSHTTPURLResponse localizedStringForStatusCode:m_statusCode], m_statusCode]];
			// @TODO perhaps try again, if status is 500?
			[self _failWithError:error retry:NO];
			return;
		}
	}
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
	[self _failWithError:error retry:YES];
}



#pragma mark -
#pragma mark Private methods

- (void)_failWithError:(NSError *)error retry:(BOOL)retry{
	if (++m_failedAttempts < m_maxAttempts && retry){
		[self _retry];
		return;
	}
	m_error = [error retain];
	m_success = NO;
	m_complete = YES;
	if ([(id)m_delegate respondsToSelector:@selector(connectionDidFinishLoading:success:)])
		[m_delegate connectionDidFinishLoading:self success:NO];
}

- (void)_retry{
	m_statusCode = -1;
	[m_response release];
	m_response = nil;
	[m_data setLength:0];
	[m_connection release];
	m_connection = [[NSURLConnection alloc] initWithRequest:m_request delegate:self];
}
@end