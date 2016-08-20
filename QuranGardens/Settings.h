//
//  Settings.h
//  QuranGardens
//
//  Created by Amr Lotfy on 8/19/16.
//  Copyright © 2016 Amr Lotfy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Settings : NSObject

/** either a number of days or in the format xdxhxmxs, where x is an integer, d: day, h: hour, m: minute, s: second*/
@property (strong, nonatomic) NSString *fadeTime;

- (double)fadeTimeToSeconds;
- (void)setFadeTimeFromSeconds:(double)seconds;

+ (double)getTimeInSeconds:(NSString *)timeString;
+ (NSString *)getTimeStringFromSeconds:(double)seconds;

@end
