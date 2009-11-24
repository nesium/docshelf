//
//  MultiCellTableColumn.h
//  FlexHelpViewer
//
//  Created by Marc Bauer on 25.11.09.
//  Copyright 2009 nesiumdotcom. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MultiCellTableColumn : NSTableColumn{
}
@end

@interface NSObject (MultiCellTableColumnDelegate)
- (NSCell *)tableView:(NSTableView *)aTableView dataCellForRow:(NSInteger)row 
	ofColumn:(NSTableColumn *)aTableColumn;
@end