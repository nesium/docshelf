//
//  FHVLocalImportPickerViewController.m
//  EarthDoc
//
//  Created by Marc Bauer on 06.03.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import "FHVLocalImportPickerViewController.h"


@interface FHVLocalImportPickerViewController (Private)
- (void)_setSourcePath:(NSString *)aPath;
@end


@implementation FHVLocalImportPickerViewController

#pragma mark -
#pragma mark Initialization & Deallocation

- (id)init{
	if (self = [super init]){
		NDCLog(@"nameTextField: %@", m_nameTextField);
		[m_nameTextField sendActionOn:NSAnyEventMask];
	}
	return self;
}

- (void)dealloc{
	[super dealloc];
}



#pragma mark -
#pragma mark IB Actions

- (IBAction)chooseDirectory:(id)sender{
	NSOpenPanel *op = [NSOpenPanel openPanel];
	[op setAllowsMultipleSelection:NO];
	[op setCanChooseFiles:NO];
	[op setCanChooseDirectories:YES];
	[op beginSheetModalForWindow:self.view.window 
		completionHandler:^(NSInteger result){
			if (result == NSFileHandlingPanelCancelButton) return;
			[self _setSourcePath:[[[op URLs] objectAtIndex:0] path]];
		}];
}



#pragma mark -
#pragma mark NSTextField notifications

- (void)controlTextDidChange:(NSNotification *)aNotification{
//	[self _updateImportButton];
}



#pragma mark -
#pragma mark Private methods

- (void)_setSourcePath:(NSString *)aPath{
	[self _setURL:[NSURL fileURLWithPath:aPath]];
	if (!aPath){
		[m_selectedFolderTextField setStringValue:@"No selection"];
		[m_selectedFolderTextField setTextColor:[NSColor lightGrayColor]];
		[m_selectedFolderTextField setToolTip:nil];
	}else{
		PackageSummaryParser *parser = [[PackageSummaryParser alloc] 
			initWithFile:[aPath stringByAppendingPathComponent:@"package-summary.html"] 
			context:nil];
		[m_nameTextField setStringValue:parser.title];
		[m_selectedFolderTextField setStringValue:[NSString stringWithFormat:@"%@ - %@", 
			[aPath lastPathComponent], [aPath stringByDeletingLastPathComponent]]];
		[m_selectedFolderTextField setToolTip:aPath];
		[m_selectedFolderTextField setTextColor:[NSColor blackColor]];
	}
//	[self _updateImportButton];
}
@end