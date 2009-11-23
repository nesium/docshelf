//
//  FlexDocsParser.h
//  FlexHelpViewer
//
//  Created by Marc Bauer on 10.05.08.
//  Copyright 2008 nesiumdotcom. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AbstractXMLTreeParser.h"
#import "PackageSummaryParser.h"
#import "PackageDetailParser.h"
#import "PackageNode.h"


@interface FlexDocsParser : NSObject 
{
	NSString *m_path;
	NSManagedObjectContext *m_context;
}

@property (retain) NSString *path;

- (id)initWithPath:(NSString *)path;
- (void)parse;

@end