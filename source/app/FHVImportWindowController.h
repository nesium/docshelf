//
//  FHVImportWindowController.h
//  EarthDocs
//
//  Created by Marc Bauer on 02.02.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FHVDocSetModel.h"
#import "FlexDocsParser.h"


@interface FHVImportWindowController : NSWindowController <FlexDocsParserConnectionDelegate>{
	IBOutlet NSView *m_pickerView;
	IBOutlet NSTextField *m_nameTextField;
	IBOutlet NSTextField *m_selectedFolderTextField;
	IBOutlet NSButton *m_cancelButton;
	IBOutlet NSButton *m_startImportButton;
	IBOutlet NSView *m_progressView;
	IBOutlet NSProgressIndicator *m_progressIndicator;
	IBOutlet NSTextField *m_statusLabel;
	NSString *m_sourcePath;
	NSConnection *m_importConnection;
}
- (id)initWithWindowNibName:(NSString *)windowNibName;
- (IBAction)chooseDirectory:(id)sender;
- (IBAction)startImport:(id)sender;
- (IBAction)cancel:(id)sender;
@end