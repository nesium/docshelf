//
//  FHVRemoteImportPickerViewController.h
//  EarthDoc
//
//  Created by Marc Bauer on 06.03.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FHVAbstractImportPickerViewController.h"
#import "NSMURLConnection.h"
#import "FHVPackageSummaryParser.h"
#import "NSString+NSMAdditions.h"


@interface FHVRemoteImportPickerViewController : FHVAbstractImportPickerViewController 
	<NSMURLConnectionDelegate>{
	IBOutlet NSTextField *m_nameTextField;
	IBOutlet NSTextField *m_remoteAddressTextField;
	IBOutlet NSImageView *m_warningIcon;
	NSMURLConnection *m_connection;
	BOOL m_urlIsValid;
}
- (void)setURLString:(NSString *)aString;
- (IBAction)addressTextField_didEndEditing:(id)sender;
@end