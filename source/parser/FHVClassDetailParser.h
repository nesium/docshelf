//
//  ClassDetailParser.h
//  FlexHelpViewer
//
//  Created by Marc Bauer on 11.05.08.
//  Copyright 2008 nesiumdotcom. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FHVAbstractXMLTreeParser.h"
#import "utils.h"

typedef enum _ASScope{
	PublicScope,
	ProtectedScope
} ASScope;


@interface FHVClassDetailParser : FHVAbstractXMLTreeParser{
	NSString *m_name;
	NSString *m_ident;
}
- (NSString *)name;
- (NSString *)ident;
- (NSString *)detail;
- (NSArray *)methodsWithScope:(ASScope)scope;
- (NSArray *)propertiesWithScope:(ASScope)scope constants:(BOOL)parseConstants;
- (NSArray *)events;
@end