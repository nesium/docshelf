#import "FHVConstants.h"

NSString *const FHVErrorDomain = @"FHVErrorDomain";
NSString *const FHVSQLiteErrorDomain = @"FHVSQLiteErrorDomain";

OSStatus const FHVMissingSummaryFileError = 1001;

NSString *FHVApplicationSupportFolder(){
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, 
		NSUserDomainMask, YES);
	NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
	return [basePath stringByAppendingPathComponent:@"EarthDoc"];
}

NSString *FHVDocSetsFolder(){
	return [FHVApplicationSupportFolder() stringByAppendingPathComponent:@"DocSets"];
}