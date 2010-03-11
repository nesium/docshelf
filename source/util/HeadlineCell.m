//
//  HeadlineCell.m
//  Calcute Debugger
//
//  Created by Marc Bauer on 30.10.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "HeadlineCell.h"


@implementation HeadlineCell

@synthesize drawsTopBorder=m_drawsTopBorder, 
			target=m_target, 
			action=m_action;

- (id)init{
	if (self = [super init]){
		m_drawsTopBorder = NO;
		m_highlighted = NO;
		m_action = nil;
		m_target = nil;
	}
	return self;
}

- (id)copyWithZone:(NSZone *)zone{
	HeadlineCell *cell = [[[self class] alloc] init];
	cell.drawsTopBorder = m_drawsTopBorder;
	cell.font = self.font;
	cell.target = self.target;
	cell.action = self.action;
	cell.tag = self.tag;
	cell.lineBreakMode = self.lineBreakMode;
	cell->m_highlighted = m_highlighted;
	return cell;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView{
	NSRect frame = (NSRect){0, NSMinY(cellFrame), NSWidth([controlView bounds]), NSHeight(cellFrame)};
	[[NSColor colorWithCalibratedRed:0.669 green:0.669 blue:0.669 alpha:1.0] drawSwatchInRect:frame];
	if (m_drawsTopBorder){
		frame = NSInsetRect(frame, 0, 1);
	}else{
		frame.size.height -= 1.0f;
	}
	
	if (!m_highlighted){
		[[NSColor whiteColor] drawSwatchInRect:frame];
		frame.origin.y += 1.0;
		frame.size.height -= 1.0;
	
		NSGradient *gradient = [[NSGradient alloc] 
			initWithStartingColor:[NSColor colorWithCalibratedRed:0.811 green:0.812 blue:0.811 alpha:1.0] 
			endingColor:[NSColor colorWithCalibratedRed:0.912 green:0.912 blue:0.912 alpha:1.0]];
		[gradient drawInRect:frame angle:-90.0];
		[gradient release];
	}else{
		[[NSColor colorWithCalibratedRed:0.886 green:0.886 blue:0.886 alpha:1.0] drawSwatchInRect:frame];
	}
	
	NSGraphicsContext *ctx = [NSGraphicsContext currentContext];
	[ctx saveGraphicsState];
	NSShadow *shadow = [[NSShadow alloc] init];
	[shadow setShadowColor:[NSColor whiteColor]];
	[shadow setShadowOffset:(NSSize){0.0f, -1.0f}];
	[shadow set];
	[super drawWithFrame:cellFrame inView:controlView];
	[shadow release];
	[ctx restoreGraphicsState];
}

- (NSColor *)highlightColorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView{
	return nil;
}

- (BOOL)trackMouse:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView 
	untilMouseUp:(BOOL)untilMouseUp{
	NSEvent *currentEvent = theEvent;
	BOOL mouseIsOver = NSPointInRect([controlView convertPoint:[currentEvent locationInWindow] 
			fromView:nil], cellFrame);
	NSRect redrawFrame = (NSRect){0, NSMinY(cellFrame), NSWidth([controlView bounds]), 
		NSHeight(cellFrame)};
	do{
		if ([currentEvent type] == NSLeftMouseUp){
			break;
		}
		mouseIsOver = NSPointInRect([controlView convertPoint:[currentEvent locationInWindow] 
			fromView:nil], cellFrame);
		if (m_highlighted != mouseIsOver){
			m_highlighted = mouseIsOver;
			[(NSControl *)controlView setNeedsDisplayInRect:redrawFrame];
		}
	}while (currentEvent = [[controlView window] nextEventMatchingMask:(NSLeftMouseUpMask | NSLeftMouseDraggedMask) 
		untilDate:[NSDate distantFuture] inMode:NSEventTrackingRunLoopMode dequeue:YES]);
	if (m_highlighted){
		m_highlighted = NO;
		[(NSControl *)controlView setNeedsDisplayInRect:redrawFrame];
	}
	if (mouseIsOver){
		if (m_target && m_action){
			objc_msgSend(m_target, m_action, self);
		}
	}
	return YES;
}
@end