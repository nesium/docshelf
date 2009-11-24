//
//  MultiCellTableColumn.m
//  FlexHelpViewer
//
//  Created by Marc Bauer on 25.11.09.
//  Copyright 2009 nesiumdotcom. All rights reserved.
//

#import "MultiCellTableColumn.h"


@implementation MultiCellTableColumn

- (id)dataCellForRow:(NSInteger)row{
	id cell = nil;
	id tv = [self tableView];
	id delegate = [tv delegate];
	if (delegate){
		SEL selector = @selector(tableView:dataCellForRow:ofColumn:);
		if ([delegate respondsToSelector:selector]){
			cell = [delegate tableView:tv dataCellForRow:row ofColumn:self];
		}
	}
	return cell ? cell : [self dataCell];
}

@end