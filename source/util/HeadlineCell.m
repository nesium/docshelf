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
	NSRect frame = (NSRect){0, NSMinY(cellFrame) - 1, NSWidth([controlView bounds]), NSHeight(cellFrame) + 1};
	[[NSColor colorWithCalibratedRed:0.669 green:0.669 blue:0.669 alpha:1.0] drawSwatchInRect:frame];
	frame = NSInsetRect(frame, 0, 1);
	[[NSColor whiteColor] drawSwatchInRect:frame];
	frame.origin.y += 1.0;
	frame.size.height -= 1.0;
	
	NSGradient *gradient = [[NSGradient alloc] 
		initWithStartingColor:[NSColor colorWithCalibratedRed:0.811 green:0.812 blue:0.811 alpha:1.0] 
		endingColor:[NSColor colorWithCalibratedRed:0.912 green:0.912 blue:0.912 alpha:1.0]];
	[gradient drawInRect:frame angle:-90.0];
	[gradient release];
	
	[super drawWithFrame:cellFrame inView:controlView];
}

- (NSColor *)highlightColorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView{
	return nil;
}
@end