//
//  FHVDocSetModel.h
//  FlexHelpViewer
//
//  Created by Marc Bauer on 19.01.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FHVDocSet.h"
#import "NSString+FHVUtils.h"

@interface FHVDocSetModel : NSObject{
	NSString *m_path;
	NSMutableArray *m_docSets;
	NSArray *m_currentData;
}
@property (readonly) NSArray *currentData;
- (id)initWithDocSetPath:(NSString *)path;
@end