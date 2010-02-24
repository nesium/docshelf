//
//  DropView.h
//  AS3_Parser
//
//  Created by Marc Bauer on 01.07.08.
//  Copyright 2008 nesiumdotcom. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DropView : NSControl 
{
	float m_phase;
	float m_maxPhase;
	float m_overColor;
	float m_upColor;
	float m_color;
	float m_iconSize;
	SEL m_action;
	id m_target;
	NSImageView *m_iconView;
	NSTimer *m_animationTimer;
	NSString *m_path;
}

@property (retain) NSString *path;
@property (assign) SEL action;
@property (assign) id target;

@end