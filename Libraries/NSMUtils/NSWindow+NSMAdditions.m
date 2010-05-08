//
//  NSWindow+NSMAdditions.m
//
//  Created by Marc Bauer on 25.02.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import "NSWindow+NSMAdditions.h"


@implementation NSWindow (NSMAdditions)

- (void)nsm_resizeToFitContentSize:(NSSize)contentSize animated:(BOOL)animated{
	NSRect windowFrame = self.frame;
	CGFloat chromeHeight = NSHeight(windowFrame) - NSHeight([[self contentView] frame]);
	contentSize.height += chromeHeight;
	windowFrame.origin.y -= contentSize.height - NSHeight(windowFrame);
	windowFrame.size = contentSize;
	if (animated)
		[self.animator setFrame:windowFrame display:YES];
	else
		[self setFrame:windowFrame display:YES];
}
@end