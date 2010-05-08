//
//  FHVNiceIndentationOutlineView.h
//
//  Created by Marc Bauer on 22.01.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface FHVNiceIndentationOutlineView : NSOutlineView{
}
@end

@interface FHVNiceIndentationOutlineViewDelegate
- (void)outlineViewArrowLeftKeyWasPressed:(NSOutlineView *)outlineView;
- (void)outlineViewArrowRightKeyWasPressed:(NSOutlineView *)outlineView;
- (void)outlineViewDidBecomeFirstResponder:(NSOutlineView *)outlineView;
@end