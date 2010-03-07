//
//  FHVPresetsImportPickerViewController.h
//  EarthDoc
//
//  Created by Marc Bauer on 06.03.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <YAJL/YAJL.h>
#import "FHVAbstractImportPickerViewController.h"
#import "NSMURLConnection.h"


@interface FHVPresetsImportPickerViewController : FHVAbstractImportPickerViewController
	<NSMURLConnectionDelegate>{
	IBOutlet NSArrayController *m_presetsArrayController;
	NSMURLConnection *m_presetsURLConnection;
}
@end