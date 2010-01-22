#import "ImageAndTextCell.h"

@implementation ImageAndTextCell

- (id)init{
	if (self = [super init]){
	}
	return self;
}

- (void)dealloc{
	[image release];
	image = nil;
	[super dealloc];
}

- (id)copyWithZone:(NSZone *)zone{
	ImageAndTextCell *cell = (ImageAndTextCell *)[super copyWithZone:zone];
	cell->image = [image retain];
	return cell;
}

- (void)setImage:(NSImage *)anImage{
	[anImage retain];
	[image release];
	image = anImage;
}

- (NSImage *)image{
	return image;
}

- (NSRect)drawingRectForBounds:(NSRect)theRect{
	// Get the parent's idea of where we should draw
	NSRect newRect = [super drawingRectForBounds:theRect];

	// When the text field is being 
	// edited or selected, we have to turn off the magic because it screws up 
	// the configuration of the field editor.  We sneak around this by 
	// intercepting selectWithFrame and editWithFrame and sneaking a 
	// reduced, centered rect in at the last minute.
	if (m_isEditingOrSelecting == NO){
		// Get our ideal size for current text
		NSSize textSize = [self cellSizeForBounds:theRect];

		// Center that in the proposed rect
		float heightDelta = newRect.size.height - textSize.height;	
		if (heightDelta > 0)
		{
			newRect.size.height -= heightDelta;
			newRect.origin.y += (heightDelta / 2);
		}
	}
	return newRect;
}

- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj 
	delegate:(id)anObject event:(NSEvent *)theEvent{
	aRect = [self drawingRectForBounds:aRect];
	m_isEditingOrSelecting = YES;
	NSRect textFrame, imageFrame;
    NSDivideRect(aRect, &imageFrame, &textFrame, 3 + [image size].width, NSMinXEdge);
	[super editWithFrame:textFrame inView:controlView editor:textObj delegate:anObject 
		event:theEvent];
	m_isEditingOrSelecting = NO;
}

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj 
	delegate:(id)anObject start:(int)selStart length:(int)selLength{
	aRect = [self drawingRectForBounds:aRect];
	m_isEditingOrSelecting = YES;
	NSRect textFrame, imageFrame;
	NSDivideRect(aRect, &imageFrame, &textFrame, 3 + [image size].width, NSMinXEdge);
	[super selectWithFrame: textFrame inView: controlView editor:textObj delegate:anObject 
		start:selStart length:selLength];
	m_isEditingOrSelecting = NO;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView{
	if (image != nil){
        NSSize imageSize;
        NSRect imageFrame;
		imageSize = [image size];
		imageSize.width += 3;
		NSDivideRect(cellFrame, &imageFrame, &cellFrame, 6 + imageSize.width, NSMinXEdge);
		
		if ([self drawsBackground]){
			[[self backgroundColor] set];
			NSRectFill(imageFrame);
		}
        imageFrame.origin.x += 6;
        imageFrame.size = imageSize;
        if ([controlView isFlipped])
            imageFrame.origin.y += ceil((cellFrame.size.height + imageFrame.size.height) / 2);
        else
            imageFrame.origin.y += ceil((cellFrame.size.height - imageFrame.size.height) / 2);
        [image compositeToPoint:imageFrame.origin operation:NSCompositeSourceOver];
    }
    [super drawWithFrame:cellFrame inView:controlView];
}

- (NSSize)cellSize{
	NSSize cellSize = [super cellSize];
	cellSize.width += (image ? [image size].width : 0) + 3;
	return cellSize;
}
@end