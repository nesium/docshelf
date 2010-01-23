#import <Cocoa/Cocoa.h>

@class Filterbar;

@protocol FilterbarDelegate

@required

- (NSArray *)filterbar:(Filterbar *)filterBar
		itemIdentifiersForGroup:(NSString *)groupIdentifier;

- (NSString *)filterbar:(Filterbar *)filterBar
				labelForItemIdentifier:(NSString *)itemIdentifier
				groupIdentifier:(NSString *)groupIdentifier;

@optional

- (NSImage *)filterbar:(Filterbar *)filterBar
				imageForItemIdentifier:(NSString *)itemIdentifier
				groupIdentifier:(NSString *)groupIdentifier;

- (BOOL)filterbar:(Filterbar *)filterBar
			hasMultipleSelection:(NSString *)groupIdentifier;

/* Notification Methods */
- (void)filterbar:(Filterbar *)filterBar
			selectedStateChanged:(BOOL)selected
			fromItem:(NSString *)itemIdentifier
			groupIdentifier:(NSString *)groupIdentifier;

@end

