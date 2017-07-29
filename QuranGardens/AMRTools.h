//
//  AMRTools.h
//  QuranGardens
//
//  Created by Amr Lotfy on 3/21/17.
//  Copyright © 2017 Amr Lotfy. All rights reserved.
//

#import <Foundation/Foundation.h>
@import UIKit;
#import <AVFoundation/AVFoundation.h>

@interface AMRTools : NSObject
    
+ (UIAlertController *)showMenuWithTitle:(NSString *)title message:(NSString *)message handlers:(NSDictionary *)handlers;
+(NSString *)abbreviateNumber:(int)num withDecimal:(int)dec;

+(Boolean) isRTL;
+(void)setLocaleArabic;
+(void)setLocaleEnglish;
+ (AVAudioPlayer *)getPlayer;
+(void)play:(NSString *)path;
+(NSString *)uniqueID;
+(NSTimeInterval)averageIntervalBetweenDatesInArray:(NSArray<NSDate *> *)datesArray;

@end
