//
//  FHVDocSet.h
//  FlexHelpViewer
//
//  Created by Marc Bauer on 19.01.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "sqlite3.h"


@interface FHVDocSet : NSObject{
	NSString *m_path;
	NSString *m_name;
	sqlite3 *m_db;
}
- (id)initWithPath:(NSString *)path;
- (NSArray *)allPackages;
- (NSArray *)allClasses;
@end