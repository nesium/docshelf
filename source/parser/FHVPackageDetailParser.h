//
//  PackageDetailParser.h
//  FlexHelpViewer
//
//  Created by Marc Bauer on 10.05.08.
//  Copyright 2008 nesiumdotcom. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FHVAbstractXMLTreeParser.h"
#import "FHVClassDetailParser.h"


@interface FHVPackageDetailParser : FHVAbstractXMLTreeParser{
	NSString *m_name;
}
- (NSString *)name;
- (NSArray *)globalFunctions;
- (NSArray *)classes;
- (NSArray *)interfaces;
- (NSArray *)constants;
@end