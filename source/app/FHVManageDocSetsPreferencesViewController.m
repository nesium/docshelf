//
//  FHVManageDocSetsPreferencesViewController.m
//
//  Created by Marc Bauer on 10.03.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import "FHVManageDocSetsPreferencesViewController.h"


@implementation FHVManageDocSetsPreferencesViewController

#pragma mark -
#pragma mark Initialization & Deallocation

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil 
	model:(FHVDocSetModel *)model{
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]){
		m_model = model;
	}
	return self;
}

- (void)awakeFromNib{
	[m_docSetsController bind:@"content" toObject:m_model withKeyPath:@"docSets" options:nil];
	
	// style large button in the no-docsets-view
	NSShadow *titleShadow = [[NSShadow alloc] init];
	[titleShadow setShadowColor:[NSColor whiteColor]];
	[titleShadow setShadowOffset:(NSSize){0.0f, -1.0f}];
	NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
	[paragraphStyle setAlignment:NSCenterTextAlignment];
	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
		titleShadow, NSShadowAttributeName, 
		[NSFont boldSystemFontOfSize:8.0f], NSFontAttributeName, 
		[NSColor colorWithDeviceWhite:0.4f alpha:1.0f], NSForegroundColorAttributeName, 
		paragraphStyle, NSParagraphStyleAttributeName, 
		nil];
	NSAttributedString *cellTitle = [[NSAttributedString alloc] initWithString:@"REMOVE" 
		attributes:attributes];
	NSButtonCell *cell = (NSButtonCell *)[[m_tableView tableColumnWithIdentifier:@"buttonColumn"] 
		dataCell];
	[cell setAttributedTitle:cellTitle];
	[titleShadow release];
	[paragraphStyle release];
	[cellTitle release];
}



#pragma mark -
#pragma mark NSViewController methods

- (NSString *)title{
	return @"DocSets";
}



#pragma mark -
#pragma mark Actions methods

- (void)deleteDocSetWithDocSetId:(NSArray *)docSetIds{
	NSString *docSetId = [docSetIds objectAtIndex:0];
	FHVDocSet *docSet = [m_model docSetForDocSetId:docSetId];
	NSBeginAlertSheet(@"Delete DocSet", @"No", @"Yes", nil, [self.view window], self, 
		@selector(sheetDidEnd:returnCode:contextInfo:), 
		@selector(sheetDidDismiss:returnCode:contextInfo:), 
		(void *)[docSetId copy], 
		@"Are you sure you want to delete the DocSet %@? This is action cannot be undone.", 
			docSet.name);
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo{
	NSString *docSetId = (NSString *)contextInfo;
	FHVDocSet *docSet = [m_model docSetForDocSetId:docSetId];
	if (returnCode == NSAlertAlternateReturn){
		[[NSWorkspace sharedWorkspace] recycleURLs:[NSArray arrayWithObject:
			[NSURL fileURLWithPath:docSet.path]] 
			completionHandler:^(NSDictionary *newURLs, NSError *error){
			if (error){
				NSLog(@"Could not delete docset. %@", error);
			}else{
				[m_model reloadDocSets];
			}
		}];
	}
}

- (void)sheetDidDismiss:(NSWindow *)sheet returnCode:(int)returnCode 
	contextInfo:(void *)contextInfo{
	NSString *docSetId = (NSString *)contextInfo;
	[docSetId release];
}



//#pragma mark -
//#pragma mark NSOutlineViewDelegate Protocol
//
//static HeadlineCell *g_headlineCell = nil;
//
//- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell 
//	forTableColumn:(NSTableColumn *)tableColumn item:(id)item{
//	if ([[tableColumn identifier] isEqualToString:@"buttonColumn"]){
//		[(NSButtonCell *)cell setAttributedTitle:
//	}
//}
@end