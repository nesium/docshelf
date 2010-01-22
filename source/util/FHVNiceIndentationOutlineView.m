//
//  FHVNiceIndentationOutlineView.m
//  EarthDocs
//
//  Created by Marc Bauer on 22.01.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import "FHVNiceIndentationOutlineView.h"


@implementation FHVNiceIndentationOutlineView

// Changing the indentation of NSOutlineView causes the 0-level items
// to indent possibly large amounts as well, which looks bad.
// Similarly, if the indent is set to small values, disclosure triangles of 
// top level items draw to far to the side and appear in the neighboring column.
#define kMaxFirstLevelIndentation 50
#define kMinFirstLevelIndentation 25

// corrects text and icons (if using ImageAndTextCell)
- (NSRect)frameOfCellAtColumn:(NSInteger)column row:(NSInteger)row{
	NSRect frame = [super frameOfCellAtColumn:column row:row];
	if (column == -1){
		CGFloat indent = [self indentationPerLevel];
		if (indent > kMaxFirstLevelIndentation){
			frame.origin.x -= (indent - kMaxFirstLevelIndentation);
			frame.size.width += (indent - kMaxFirstLevelIndentation);
		}else if (indent < kMinFirstLevelIndentation){
			frame.origin.x += (kMinFirstLevelIndentation - indent);
			frame.size.width -= (kMinFirstLevelIndentation - indent);
		}
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
	if ([[self delegate] respondsToSelector:@selector(outlineViewDidBecomeFirstResponder:)]){
		[(FHVNiceIndentationOutlineViewDelegate *)[self delegate] 
			outlineViewDidBecomeFirstResponder:self];
	}
	return [super becomeFirstResponder];
}
@end