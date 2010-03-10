//
//  FHVManageDocSetsPreferencesViewController.h
//  EarthDoc
//
//  Created by Marc Bauer on 10.03.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FHVDocSetModel.h"


@interface FHVManageDocSetsPreferencesViewController : NSViewController{
	IBOutlet NSArrayController *m_docSetsController;
	FHVDocSetModel *m_model;
}
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil 
	model:(FHVDocSetModel *)model;
@end