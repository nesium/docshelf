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
- (void)_updateValidity;
@end


@implementation FHVLocalImportPickerViewController

#pragma mark -
#pragma mark Initialization & Deallocation

- (id)init{
	if (self = [super init]){
		m_pathIsValid = NO;
	}
	return self;
}

- (void)awakeFromNib{
	[m_nameTextField sendActionOn:NSAnyEventMask];
}

- (void)dealloc{
	[super dealloc];
}



#pragma mark -
#pragma mark Public methods

- (void)reset{
	[super reset];
	m_pathIsValid = NO;
	[self _setSourcePath:nil];
	[m_nameTextField setStringValue:@""];
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
	[self _setDocSetName:[m_nameTextField stringValue]];
	[self _updateValidity];
}



#pragma mark -
#pragma mark Private methods

- (void)_setSourcePath:(NSString *)aPath{
	[self _setURL:nil];
	if (!aPath){
		[m_selectedFolderTextField setStringValue:@"No selection"];
		[m_selectedFolderTextField setTextColor:[NSColor lightGrayColor]];
		[m_selectedFolderTextField setToolTip:nil];
		[m_warningIcon setHidden:YES];
		m_pathIsValid = NO;
	}else{
		[m_selectedFolderTextField setStringValue:[NSString stringWithFormat:@"%@ - %@", 
			[aPath lastPathComponent], [aPath stringByDeletingLastPathComponent]]];
		[m_selectedFolderTextField setToolTip:aPath];
		[m_selectedFolderTextField setTextColor:[NSColor blackColor]];
		
		NSString *path = [aPath stringByAppendingPathComponent:@"package-summary.html"];
		if (![[NSFileManager defaultManager] fileExistsAtPath:path]){
			m_pathIsValid = NO;
			[m_warningIcon setHidden:NO];
			[m_warningIcon setToolTip:@"No valid ASDocs at path!"];
		}else{
			NSError *error = nil;
			FHVPackageSummaryParser *parser = [[FHVPackageSummaryParser alloc] 
				initWithURL:[NSURL fileURLWithPath:[aPath stringByAppendingPathComponent:@"package-summary.html"]] 
				context:nil 
				error:&error];
			NSString *title = parser.title;
			if (!title){
				m_pathIsValid = NO;
				[m_warningIcon setHidden:NO];
				[m_warningIcon setToolTip:@"No valid ASDocs at path!"];
				NDCLog(@"%@", [error localizedDescription]);
			}else{
				[m_nameTextField setStringValue:title];
				[self _setDocSetName:title];
				[m_warningIcon setHidden:YES];
				m_pathIsValid = YES;
				[self _setURL:[NSURL fileURLWithPath:aPath]];
			}
		}
	}
	[self _updateValidity];
}

- (void)_updateValidity{
	NSString *name = [[m_nameTextField stringValue] 
		stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	[self _setValid:(m_pathIsValid && [name length] > 0)];
}
@end