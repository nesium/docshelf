//
//  FHVLocalImportPickerViewController.h
//
//  Created by Marc Bauer on 06.03.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FHVAbstractImportPickerViewController.h"
#import "FHVPackageSummaryParser.h"


@interface FHVLocalImportPickerViewController : FHVAbstractImportPickerViewController{
	IBOutlet NSTextField *m_nameTextField;
	IBOutlet NSTextField *m_selectedFolderTextField;
	IBOutlet NSImageView *m_warningIcon;
	BOOL m_pathIsValid;
}
- (IBAction)chooseDirectory:(id)sender;
@end