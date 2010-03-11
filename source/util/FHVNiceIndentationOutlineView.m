//
//  FHVNiceIndentationOutlineView.m
//  EarthDocs
//
//  Created by Marc Bauer on 22.01.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import "FHVNiceIndentationOutlineView.h"


@implementation FHVNiceIndentationOutlineView

// corrects text and icons (if using ImageAndTextCell)
- (NSRect)frameOfCellAtColumn:(NSInteger)column row:(NSInteger)row{
	NSRect frame = [super frameOfCellAtColumn:column row:row];
	CGFloat indent = [self indentationPerLevel];
	
	if (column == -1 || (indent > 0 && column == 0 && [self levelForRow:row] == 1)){
		frame.size.width += frame.origin.x - 21;
		frame.origin.x = 21;
	}
	return frame;
}

// corrects disclosure control icon
- (NSRect)frameOfOutlineCellAtRow:(NSInteger)row{
	NSRect frame = [super frameOfOutlineCellAtRow:row];
	frame.origin.x = 8;
	return frame;
}

- (void)keyDown:(NSEvent *)theEvent{
	id item = [self itemAtRow:[self selectedRow]];
	if ([self isExpandable:item] && ([theEvent keyCode] == 124 || 
		([theEvent keyCode] == 123 && [self isItemExpanded:item]))){
		[super keyDown:theEvent];
		return;
	}
	switch ([theEvent keyCode]){
		case 123: // left
			if ([[self delegate] respondsToSelector:@selector(outlineViewArrowLeftKeyWasPressed:)]){
				[(FHVNiceIndentationOutlineViewDelegate *)[self delegate] 
					outlineViewArrowLeftKeyWasPressed:self];
			}
			break;
		case 124: // right
			if ([[self delegate] respondsToSelector:@selector(outlineViewArrowRightKeyWasPressed:)]){
				[(FHVNiceIndentationOutlineViewDelegate *)[self delegate] 
					outlineViewArrowRightKeyWasPressed:self];
			}
			break;
		default:
			[super keyDown:theEvent];
	}
}

- (BOOL)becomeFirstResponder{
	NSEvent *currentEvent = [[self window] currentEvent];
	if ((currentEvent.type == NSKeyDown || currentEvent.type == NSKeyUp) && 
		[[self delegate] respondsToSelector:@selector(outlineViewDidBecomeFirstResponder:)]){
		[(FHVNiceIndentationOutlineViewDelegate *)[self delegate] 
			outlineViewDidBecomeFirstResponder:self];
	}
	return [super becomeFirstResponder];
}
@end