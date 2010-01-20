//
//  FHVClassParserOperation.h
//  FlexHelpViewer
//
//  Created by Marc Bauer on 15.01.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ClassDetailParser.h"
#import "FHVImportContext.h"


@interface FHVClassParserOperation : NSOperation{
	NSArray *m_classes;
	void (^m_notifier)(void);
	FHVImportContext *m_context;
}
- (id)initWithClasses:(NSArray *)classes notifier:(void (^)(void))block 
	context:(FHVImportContext *)context;
@end