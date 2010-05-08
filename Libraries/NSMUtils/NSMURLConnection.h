//
//  PSURLConnection.h
//  ProSieben
//
//  Created by Marc Bauer on 06.02.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSError+NSMAdditions.h"

extern NSString *const NSMURLConnectionErrorDomain;
extern OSStatus const NSMURLConnectionIllegalMIMETypeError;
extern OSStatus const NSMURLConnectionIllegalStatusCodeError;

@class NSMURLConnection;

@protocol NSMURLConnectionDelegate
@optional
- (void)connectionDidFinishLoading:(NSMURLConnection *)connection success:(BOOL)success;
@end


@interface NSMURLConnection : NSObject{
	NSURLConnection *m_connection;
	NSMutableData *m_data;
	id <NSMURLConnectionDelegate> m_delegate;
	BOOL m_success;
	BOOL m_complete;
	NSURLRequest *m_request;
	NSURLResponse *m_response;
	NSUInteger m_failedAttempts;
	NSUInteger m_maxAttempts;
	NSArray *m_allowedMIMETypes;
	BOOL m_treatsNonSuccessStatusCodesAsErrors;
	NSInteger m_statusCode;
	NSError *m_error;
}
@property (readonly) NSURLRequest *request;
@property (readonly) NSURLResponse *response;
@property (readonly) NSData *data;
@property (readonly) BOOL success;
@property (readonly) BOOL complete;
@property (readonly) CGFloat estimatedProgress;
@property (readonly) NSInteger statusCode;
@property (readonly) NSError *error;
@property (nonatomic, assign) NSUInteger maxAttempts; // defaults to 3
@property (nonatomic, retain) NSArray *allowedMIMETypes;
@property (nonatomic, assign) BOOL treatsNonSuccessStatusCodesAsErrors; // defaults to YES
- (id)initWithURLRequest:(NSURLRequest *)aRequest;
- (id)initWithURLRequest:(NSURLRequest *)aRequest delegate:(id<NSMURLConnectionDelegate>)delegate;
- (void)start;
- (void)startSynchronously;
- (void)cancel;
- (NSString *)stringValue;
@end