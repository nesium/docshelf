//
//  HeadlineCell.m
//  Calcute Debugger
//
//  Created by Marc Bauer on 30.10.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "HeadlineCell.h"


@implementation HeadlineCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView*)controlView{
	NSGradient *gradient = [[NSGradient alloc] 
		initWithStartingColor:[NSColor colorWithCalibratedRed:0.855 green:0.855 blue:0.855 alpha:1.0] 
		endingColor:[NSColor colorWithCalibratedRed:0.929 green:0.929 blue:0.929 alpha:1.0]];
	
	NSRect frame = (NSRect){0, NSMinY(cellFrame) - 1, NSWidth([controlView bounds]), NSHeight(cellFrame) + 1};
	[[NSColor colorWithCalibratedRed:0.725 green:0.725 blue:0.725 alpha:1.0] drawSwatchInRect:frame];
	frame = NSInsetRect(frame, 0, 1);
	[[NSColor whiteColor] drawSwatchInRect:frame];
	frame.origin.y += 1.0;
	frame.size.height -= 1.0;
	[gradient drawInRect:frame angle:-90.0];
	[super drawWithFrame:cellFrame inView:controlView];
}

- (NSColor *)highlightColorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView{
	return nil;
}
@end