//
//  PSURLConnection.h
//  ProSieben
//
//  Created by Marc Bauer on 06.02.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import <Foundation/Foundation.h>

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
}
@property (readonly) NSURLRequest *request;
@property (readonly) NSURLResponse *response;
@property (readonly) NSData *data;
@property (readonly) BOOL success;
@property (readonly) BOOL complete;
@property (readonly) CGFloat estimatedProgress;
- (id)initWithURLRequest:(NSURLRequest *)aRequest delegate:(id<NSMURLConnectionDelegate>)delegate;
- (void)start;
- (void)cancel;
- (NSString *)stringValue;
@end