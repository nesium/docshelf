//
//  FHVImportPickerViewController.h
//  EarthDoc
//
//  Created by Marc Bauer on 06.03.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface FHVAbstractImportPickerViewController : NSViewController{
	BOOL m_valid;
	BOOL m_busy;
	NSURL *m_url;
}
@property (readonly) BOOL valid;
@property (readonly) BOOL busy;
@property (readonly) NSURL *URL;
- (void)reset;
@end


@interface FHVAbstractImportPickerViewController (Protected)
- (void)_setURL:(NSURL *)anURL;
- (void)_setBusy:(BOOL)bFlag;
- (void)_setValid:(BOOL)bFlag;
@end