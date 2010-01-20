//
//  PackageDetailParser.h
//  FlexHelpViewer
//
//  Created by Marc Bauer on 10.05.08.
//  Copyright 2008 nesiumdotcom. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AbstractXMLTreeParser.h"
#import "ClassDetailParser.h"


@interface PackageDetailParser : AbstractXMLTreeParser{
	NSString *m_name;
}
- (NSString *)name;
- (NSArray *)globalFunctions;
- (NSArray *)classes;
- (NSArray *)interfaces;
- (NSArray *)constants;
@end