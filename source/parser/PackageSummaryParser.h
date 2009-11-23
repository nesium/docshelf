//
//  PackageSummaryParser.h
//  FlexHelpViewer
//
//  Created by Marc Bauer on 09.05.08.
//  Copyright 2008 nesiumdotcom. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "PackageNode.h"
#import "AbstractXMLTreeParser.h"


@interface PackageSummaryParser : AbstractXMLTreeParser{
	NSManagedObjectContext *m_context;
}
- (id)initWithFile:(NSString *)file context:(NSManagedObjectContext *)context;
@end