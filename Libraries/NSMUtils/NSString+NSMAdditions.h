//
//  NSString+PSAdditions.h
//  ProSieben
//
//  Created by Marc Bauer on 17.02.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RegexKitLite.h"


@interface NSString (NSMAdditions)
+ (NSString *)nsm_uuid;
- (NSString *)nsm_stringByEscapingHTMLEntities;
- (NSString *)nsm_normalizedFilename;
- (BOOL)nsm_isURL;
@end