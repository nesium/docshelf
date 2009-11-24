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
		initWithStartingColor:[NSColor colorWithDeviceWhite:0.85 alpha:1.0] 
		endingColor:[NSColor colorWithDeviceWhite:0.95 alpha:1.0]];
	
	NSRect gradientFrame = cellFrame;
	gradientFrame.size.width = [controlView bounds].size.width;
	gradientFrame.origin.x = 0;
	gradientFrame.origin.y -= 1.0;
	gradientFrame.size.height += 1.0;	
	[[NSColor whiteColor] drawSwatchInRect:gradientFrame];
	gradientFrame.origin.y += 1.0;
	gradientFrame.size.height -= 1.0;
	[gradient drawInRect:gradientFrame angle:-90.0];
	[super drawWithFrame:cellFrame inView:controlView];
}

- (NSColor *)highlightColorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView{
	return nil;
}

@end