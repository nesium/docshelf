//
//  DropView.m
//  AS3_Parser
//
//  Created by Marc Bauer on 01.07.08.
//  Copyright 2008 nesiumdotcom. All rights reserved.
//

#import "DropView.h"


@interface DropView (Private)
- (void)drawRoundRect:(CGRect)rect inContext:(CGContextRef)ctx withRadius:(CGFloat)radius;
- (void)startAnimation;
- (void)stopAnimation;
@end


@implementation DropView

@synthesize path=m_path;
@synthesize action=m_action;
@synthesize target=m_target;

#pragma mark -
#pragma mark Initialization & Deallocation

- (id)initWithFrame:(NSRect)frame 
{
	self = [super initWithFrame:frame];
	
	m_phase = 0;
	m_maxPhase = 12.0;
	m_overColor = 0.6;
	m_upColor = m_color = 0.75;
	m_animationTimer = nil;
	m_iconSize = 48;
	m_iconView = [[NSImageView alloc] initWithFrame:
		NSMakeRect(([self bounds].size.width - m_iconSize) / 2, 
					([self bounds].size.height - m_iconSize) / 2, 
					m_iconSize, m_iconSize)];
	[m_iconView setWantsLayer:YES];
	[m_iconView setAlphaValue:0.0];
	[m_iconView setEditable:NO];
	[m_iconView unregisterDraggedTypes];
	[self addSubview:m_iconView];
	
	[self registerForDraggedTypes:[NSArray arrayWithObjects: NSFilenamesPboardType, nil]];
	
	return self;
}

- (void)dealloc
{
	[self stopAnimation];
	[super dealloc];
}



#pragma mark -
#pragma mark Drawing

- (void)drawRect:(NSRect)rect 
{
	NSRect bounds = NSInsetRect([self bounds], 10, 10);
	CGFloat radius = 18.0;
	CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
	CGContextSetGrayStrokeColor(context, m_color, 1.0);
	CGContextSetLineWidth(context, 4.0 / radius);
	CGContextSetLineDash(context, m_phase, (float[]){20 / radius, 5 / radius}, 2);
	[self drawRoundRect:NSRectToCGRect(bounds) inContext:context withRadius:radius];
	CGContextStrokePath(context);
}

- (void)drawRoundRect:(CGRect)rect inContext:(CGContextRef)ctx withRadius:(CGFloat)radius
{
	float width = CGRectGetWidth(rect);
	float height = CGRectGetHeight(rect);
	float fw = width / radius;
	float fh = height / radius;

	CGContextTranslateCTM(ctx, CGRectGetMinX(rect), CGRectGetMinY(rect));
	CGContextScaleCTM(ctx, radius, radius);
	CGContextMoveToPoint(ctx, fw, fh/2);
	CGContextAddArcToPoint(ctx, fw, fh, fw/2, fh, 1);
	CGContextAddArcToPoint(ctx, 0, fh, 0, fh/2, 1);
	CGContextAddArcToPoint(ctx, 0, 0, fw/2, 0, 1);
	CGContextAddArcToPoint(ctx, fw, 0, fw, fh/2, 1);
    CGContextClosePath(ctx);
}



#pragma mark -
#pragma mark Drag & Drop

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	if ((NSDragOperationLink & [sender draggingSourceOperationMask]) == NSDragOperationLink)
	{
		m_color = m_overColor;
		[self startAnimation];
		return NSDragOperationGeneric;
	}
	else
	{
		return NSDragOperationNone;
	}
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
	m_color = m_upColor;
	[self stopAnimation];
	[self setNeedsDisplay:YES];
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
	return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	NSPasteboard *pboard = [sender draggingPasteboard];
	NSArray *types = [NSArray arrayWithObjects: NSFilenamesPboardType, nil];
	NSString *desiredType = [pboard availableTypeFromArray:types];
	NSData *carriedData	= [pboard dataForType: desiredType];
	
	if (carriedData == nil)
	{
		return NO;
	}
	else 
	{
		if ([desiredType isEqualToString:NSFilenamesPboardType])
		{
			NSArray *fileArray = [pboard propertyListForType:@"NSFilenamesPboardType"];
			NSString *path = [fileArray objectAtIndex:0];
			NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:path];
			[m_iconView setAlphaValue:0];
			[m_iconView setImage:icon];
			[[m_iconView animator] setAlphaValue:1.0];
			[self setPath:path];
			[self sendAction:[self action] to:[self target]];
		}
		else
		{
			return NO;
		}
	}
	
	m_color = m_upColor;
	[self stopAnimation];
	[self setNeedsDisplay:YES];
	return YES;
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
	return YES;
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
	[self setNeedsDisplay:YES];
}



#pragma mark -
#pragma mark Controlling animation

- (void)startAnimation
{
	if (m_animationTimer)
	{
		return;
	}
	m_animationTimer = [[NSTimer scheduledTimerWithTimeInterval:0.04 target:self 
		selector:@selector(animation_tick:) userInfo:nil repeats:YES] retain];
}

- (void)stopAnimation
{
	[m_animationTimer invalidate];
	[m_animationTimer release];
	m_animationTimer = nil;
}

- (void)animation_tick:(NSTimer *)timer
{
	m_phase += 0.2;
	if (m_phase > m_maxPhase)
	{
		m_phase = 0;
	}
	[self setNeedsDisplay:YES];
}

@end