//
//  FlexHelpViewerApp.m
//  FlexHelpViewer
//
//  Created by Marc Bauer on 09.05.08.
//  Copyright 2008 nesiumdotcom. All rights reserved.
//

#import "FlexHelpViewerApp.h"

@interface FlexHelpViewerApp (Private)
- (void)loadPage:(NSString *)urlString;
- (void)parseFlexDocs;
- (void)startHelpViewer;
@end


@implementation FlexHelpViewerApp

- (void)awakeFromNib{
	m_selectedNode = nil;
	m_history = [[NSMutableArray alloc] init];
	m_historyIndex = 0;
	m_appDelegate = [[AppDelegate alloc] init];
	[NSApp setDelegate:m_appDelegate];
	if (![[NSFileManager defaultManager] fileExistsAtPath:[[m_appDelegate persistentStoreURL] path]]){
		[self parseFlexDocs];
		return;
	}
	[self startHelpViewer];
}

- (IBAction)updateFilter:(id)sender{
	if (![[m_searchField stringValue] length]){
		[m_contentsController setFilterPredicate:nil];
		[m_contentsController setSelectionIndex:0];
		return;
	}
	[m_contentsController setFilterPredicate:[NSPredicate predicateWithFormat:@"name CONTAINS[cd] %@", 
		[m_searchField stringValue]]];
	[m_contentsController setSelectionIndex:0];
}

- (void)controlTextDidChange:(NSNotification *)aNotification{
	[self updateFilter:nil];
}

- (IBAction)navigateInHistory:(id)sender{
	if ([(NSSegmentedControl *)sender selectedSegment] == 0){
		m_historyIndex--;
		[self selectAndLoadClassNode:[m_history objectAtIndex:m_historyIndex]];
	}else{
		m_historyIndex++;
		[self selectAndLoadClassNode:[m_history objectAtIndex:m_historyIndex]];
	}
	[self updateBackForwardControl];
}

- (void)parseFlexDocs{
	NSConnection *conn = [NSConnection defaultConnection];
	[conn setRootObject:self];
	[conn registerName:@"com.nesium.FlexHelpViewer"];

	[m_importWindow makeKeyAndOrderFront:self];
	[m_importWindow center];
	
//	NSString *path = [[[NSBundle mainBundle] resourcePath] 
//		stringByAppendingPathComponent:@"flexdocs"];
	NSString *path = @"/Users/mb/Desktop/flexdocs";
	
	m_parser = [[FlexDocsParser alloc] initWithPath:path];
	[NSThread detachNewThreadSelector:@selector(parse) toTarget:m_parser withObject:nil];
}

- (void)startHelpViewer{

//	NSArray *all = [[m_appDelegate managedObjectContext] fetchObjectsForEntityName:@"PackageNode" 
//		withPredicate:nil];
	
	[m_webView setResourceLoadDelegate:self];
	[m_webView setPolicyDelegate:self];
	[m_searchField setDelegate:self];
	[m_backForwardSegmentedCell setEnabled:NO forSegment:0];
	[m_backForwardSegmentedCell setEnabled:NO forSegment:1];
	
	NSEntityDescription *entityDescription = [NSEntityDescription
		entityForName:[ClassNode className] inManagedObjectContext:[m_appDelegate managedObjectContext]];
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setEntity:entityDescription];
	NSError *error = nil;
	NSArray *all = [[m_appDelegate managedObjectContext] executeFetchRequest:request error:&error];
	
	[m_contentsController addObserver:self forKeyPath:@"selection" 
		options:0 context:NULL];
	[m_treeController addObserver:self forKeyPath:@"selection" 
		options:0 context:NULL];
	
	[m_mainWindow setDelegate:m_appDelegate];
	//[m_contentsController setManagedObjectContext:[m_appDelegate managedObjectContext]];
	[m_contentsController setContent:all];
//	NSLog(@"%@", [m_contentsController arrangedObjects]);
	[m_mainWindow makeKeyAndOrderFront:self];
}

- (NSArray *)treeSortDescriptors{
	return [NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"name"
		ascending:YES] autorelease]];
}

- (NSArray *)packageContentSortDescriptors{
	return [NSArray arrayWithObjects:[[[NSSortDescriptor alloc] initWithKey:@"className" 
		ascending:NO] autorelease], [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES],
		nil];
}

- (NSArray *)signatureSortDescriptors{
	return [NSArray arrayWithObjects:[[[NSSortDescriptor alloc] initWithKey:@"isInherited" 
		ascending:YES] autorelease], [[[NSSortDescriptor alloc] initWithKey:@"className" 
		ascending:NO] autorelease], [[[NSSortDescriptor alloc] initWithKey:@"signature" 
		ascending:YES] autorelease], nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object 
	change:(NSDictionary *)change context:(void *)context{
//	if ([[object selectedObjects] count] < 1){
//		[self loadPage:@"about:blank"];
//		return;
//	}
	if (object == m_contentsController){
		NSObject *selection = [object valueForKeyPath:@"selection.self"];
		if ([selection isMemberOfClass:[ClassNode class]]){
			[self loadPageForClassNode:(ClassNode *)selection];
			[self recordHistoryItem:(ClassNode *)selection];
		}
	}else if (object == m_treeController){
		if ([[m_treeController selectedObjects] count] == 0)
			return;
		NSObject *selection = [object valueForKeyPath:@"selection.self"];
		
		WebScriptObject *window = [m_webView windowScriptObject];
		[window evaluateWebScript:[NSString stringWithFormat:@"location.href='#%@';", 
			[(SignatureNode *)selection anchor]]];
	}
}

- (void)loadPage:(NSString *)urlString{
	NSURL *url = [NSURL URLWithString:urlString];
	NSURLRequest *request = [NSURLRequest requestWithURL:url];
	[[m_webView mainFrame] loadRequest:request];
}


- (NSString *)tableView:(NSTableView *)aTableView toolTipForCell:(NSCell *)aCell 
	rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)row 
	mouseLocation:(NSPoint)mouseLocation{
	return [(SignatureNode *)[[m_signatureController arrangedObjects] objectAtIndex:row] summary];
}

- (void)selectNodeWithURL:(NSURL *)url{
	NSString *lastPathComponent = [[url resourceSpecifier] lastPathComponent];
	NSString *nodeName = [lastPathComponent stringByDeletingPathExtension];
	id obj = [[[[NSApp delegate] managedObjectContext] fetchObjectsForEntityName:@"ClassNode" 
		withPredicate:@"name = %@", nodeName] anyObject];
	[m_contentsController setSelectedObjects:[NSArray arrayWithObject:obj]];
	[m_classListTableView scrollRowToVisible:[m_classListTableView selectedRow]];
}

- (void)selectAndLoadClassNode:(ClassNode *)aNode{
	[m_contentsController removeObserver:self forKeyPath:@"selection"];
	[m_contentsController setSelectedObjects:[NSArray arrayWithObject:aNode]];
	[m_classListTableView scrollRowToVisible:[m_classListTableView selectedRow]];
	[self loadPageForClassNode:aNode];
	[m_contentsController addObserver:self forKeyPath:@"selection" 
		options:0 context:NULL];
}

- (void)loadPageForClassNode:(ClassNode *)aNode{
	if (m_selectedNode == aNode || aNode == nil)
		return;
	m_selectedNode = aNode;
	NSMutableString *html = [NSMutableString stringWithContentsOfFile:[[NSBundle mainBundle] 
		pathForResource:@"class" ofType:@"html"] encoding:NSUTF8StringEncoding error:nil];
	[html replaceOccurrencesOfString:@"%BODY%" withString:[aNode htmlString] 
		options:0 range:(NSRange){0, [html length]}];
	[[m_webView mainFrame] loadHTMLString:html 
		baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath]]];
}

- (void)recordHistoryItem:(ClassNode *)aNode{
	if ([m_history count] && m_historyIndex < [m_history count] - 1){
		[m_history removeObjectsInRange:(NSRange){m_historyIndex + 1, 
			[m_history count] - m_historyIndex - 1}];
	}
	if ([m_history lastObject] != aNode){
		[m_history addObject:aNode];
		m_historyIndex = [m_history count] - 1;
	}
	[self updateBackForwardControl];
}

- (void)updateBackForwardControl{
	[m_backForwardSegmentedCell setEnabled:(m_historyIndex > 0) forSegment:0];
	[m_backForwardSegmentedCell setEnabled:([m_history count] && m_historyIndex < [m_history count] - 1) 
		forSegment:1];
}


#pragma mark -
#pragma mark NSConnection proxy methods called by FlexDocsParser

- (void)setStatusMessage:(NSString *)message{
	[m_progressLabel setStringValue:message];
}

- (void)setProgressIsIndeterminate:(BOOL)bFlag{
	[m_progressIndicator setIndeterminate:bFlag];
}

- (void)setMaxProgressValue:(double)value{
	[m_progressIndicator setMaxValue:value];
}

- (void)setProgress:(double)progress{
	[m_progressIndicator setDoubleValue:progress];
}

- (void)parsingComplete{
	[m_importWindow orderOut:self];
	[self startHelpViewer];
}


#pragma mark -
#pragma WebResourceLoadDelegate Prototcol

- (NSURLRequest *)webView:(WebView *)sender resource:(id)identifier 
	willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse 
	fromDataSource:(WebDataSource *)dataSource{
	if ([[[[request URL] resourceSpecifier] lastPathComponent] isEqualToString:@"inherit-arrow.gif"]){
		return [NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] 
			pathForResource:@"inherit-arrow" ofType:@"gif"]]];
	}
	return request;
}

- (void)webView:(WebView *)webView decidePolicyForNavigationAction:(NSDictionary *)actionInformation 
	request:(NSURLRequest *)request frame:(WebFrame *)frame 
	decisionListener:(id <WebPolicyDecisionListener>)listener{
	NSString *lastPathComponent = [[[request URL] resourceSpecifier] lastPathComponent];
	if ([[lastPathComponent pathExtension] isEqualToString:@"html"]){
		[self performSelector:@selector(selectNodeWithURL:) withObject:[request URL] afterDelay:0.0];
		[listener ignore];
		return;
	}
	[listener use];
}
@end