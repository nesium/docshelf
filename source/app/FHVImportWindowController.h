//
//  FHVImportWindowController.h
//
//  Created by Marc Bauer on 02.02.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FHVDocSetModel.h"
#import "FHVDocParser.h"
#import "NSWindow+NSMAdditions.h"
#import "FHVPackageSummaryParser.h"
#import "NSString+NSMAdditions.h"
#import "FHVLocalImportPickerViewController.h"
#import "FHVRemoteImportPickerViewController.h"
#import "FHVPresetsImportPickerViewController.h"


@interface FHVImportWindowController : NSWindowController <FlexDocsParserConnectionDelegate>{
	IBOutlet FHVLocalImportPickerViewController *m_localPickerController;
	IBOutlet FHVRemoteImportPickerViewController *m_remotePickerController;
	IBOutlet FHVPresetsImportPickerViewController *m_presetsPickerController;
	IBOutlet NSView *m_titleView;
	IBOutlet NSProgressIndicator *m_activityIndicator;
	IBOutlet NSButton *m_startImportButton;
	IBOutlet NSButton *m_cancelButton;
	
	IBOutlet NSWindow *m_progressWindow;
	IBOutlet NSTextField *m_statusLabel;
	IBOutlet NSProgressIndicator *m_progressIndicator;
	
	NSConnection *m_importConnection;
	FHVDocSetModel *m_model;
	FHVDocParser *m_parser;
	NSArray *m_pickerControllers;
	FHVAbstractImportPickerViewController *m_selectedController;
}
- (id)initWithWindowNibName:(NSString *)windowNibName model:(FHVDocSetModel *)model;
- (IBAction)startImport:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)toolbarItem_clicked:(NSToolbarItem *)sender;
- (void)reset;
@end