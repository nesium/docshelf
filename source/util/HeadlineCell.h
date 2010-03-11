//
//  HeadlineCell.h
//  Calcute Debugger
//
//  Created by Marc Bauer on 30.10.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RSVerticallyCenteredTextFieldCell.h"


@interface HeadlineCell : RSVerticallyCenteredTextFieldCell{
	BOOL m_drawsTopBorder;
	BOOL m_highlighted;
	SEL m_action;
	id m_target;
}
@property (nonatomic, assign) BOOL drawsTopBorder;
@property (nonatomic, assign) SEL action;
@property (nonatomic, assign) id target;
@end