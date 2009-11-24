//
//  SignatureNode.m
//  FlexHelpViewer
//
//  Created by Marc Bauer on 18.05.08.
//  Copyright 2008 nesiumdotcom. All rights reserved.
//

#import "SignatureNode.h"


@implementation SignatureNode
@dynamic signature;
@dynamic isInherited;

- (NSSet *)children{
	return nil;
}

- (NSUInteger)numChildren{
	return 0;
}

- (BOOL)isLeaf{
	return YES;
}

- (NSString *)anchor{
	return [[NSURL URLWithString:self.filepath] fragment];
}

- (NSString *)htmlString{
	NSMutableString *htmlString = [NSMutableString string];
	[htmlString appendFormat:@"<a name='%@'></a>", self.anchor];
	if (self.signature != nil)
		[htmlString appendFormat:@"<h3>%@</h3>", self.signature];
	if (self.detail != nil)
		[htmlString appendString:self.detail];
	else if (self.summary != nil)
		[htmlString appendString:self.summary];
	return htmlString;
}
@end