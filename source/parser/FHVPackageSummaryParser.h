//
//  PackageSummaryParser.h
//  FlexHelpViewer
//
//  Created by Marc Bauer on 09.05.08.
//  Copyright 2008 nesiumdotcom. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "FHVAbstractXMLTreeParser.h"


@interface FHVPackageSummaryParser : FHVAbstractXMLTreeParser{
}
- (NSString *)title;
- (NSArray *)packages;
@end