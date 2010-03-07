//
//  NSDate+NSMAdditions.m
//  EarthDoc
//
//  Created by Marc Bauer on 03.03.10.
//  Copyright 2010 nesiumdotcom. All rights reserved.
//

#import "NSDate+NSMAdditions.h"


@implementation NSDate (NSMAdditions)

- (NSString *)relativeDateStringFromDate:(NSDate *)date oldDateFormat:(NSString *)oldDateFormat{
	if (date == nil)
		date = [NSDate date];
	
	NSDate *laterDate = [self laterDate:date];
	NSDate *earlierDate = [self earlierDate:date];
	NSTimeInterval difference = [laterDate timeIntervalSinceDate:earlierDate];
	int days = (int)floor((difference / 60 / 60 / 24));
	
	if (days > 7){
		NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
		if (oldDateFormat == nil)
			[formatter setDateStyle:NSDateFormatterShortStyle];
		else
			[formatter setDateFormat:oldDateFormat];
		NSString *dateString = [formatter stringFromDate:self];
		[formatter release];
		return dateString;
	}else if (days > 1){
		return [NSString stringWithFormat:NSLocalizedString(@"%d days ago", @""), days];
	}else if (days == 1){
		return [NSString stringWithFormat:NSLocalizedString(@"%d day ago", @""), days];
	}else{
		difference -= (days * 60 * 60 * 24);
		int hours = (int)floor((difference / 60 / 60));
		
		if (hours > 1){
			return [NSString stringWithFormat:NSLocalizedString(@"%d hours ago", @""), hours];
		}else if (hours == 1){
			return [NSString stringWithFormat:NSLocalizedString(@"%d hour ago", @""), hours];
		}else{
			difference -= (hours * 60 * 60);
			int minutes = (int)floor((difference / 60));
			if (minutes > 1){
				return [NSString stringWithFormat:NSLocalizedString(@"%d minutes ago", @""), 
					minutes];
			}else if (minutes == 1){
				return [NSString stringWithFormat: NSLocalizedString(@"%d minute ago", @""), 
					minutes];
			}else{
				difference -= (minutes * 60);
				int seconds = (int)difference;
				if (seconds <= 15)
					return NSLocalizedString(@"Right now", @"");
				else
					return NSLocalizedString(@"Less than a minute ago", @"");
			}
		}
	}
	return nil;
}

- (NSString *)stringWithDateFormat:(NSString *)aFormat{
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:aFormat];
	NSString *result = [formatter stringFromDate:self];
	[formatter release];
	return result;
}
@end