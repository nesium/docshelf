//
//  FHVLocalImportPickerViewController.h
//  EarthDoc
//
//  Created by Marc Bauer on 06.03.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FHVAbstractImportPickerViewController.h"
#import "PackageSummaryParser.h"


@interface FHVLocalImportPickerViewController : FHVAbstractImportPickerViewController{
	IBOutlet NSTextField *m_nameTextField;
	IBOutlet NSTextField *m_selectedFolderTextField;
}
- (IBAction)chooseDirectory:(id)sender;
@end