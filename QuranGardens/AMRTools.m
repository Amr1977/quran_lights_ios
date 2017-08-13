//
//  AMRTools.m
//  QuranGardens
//
//  Created by Amr Lotfy on 3/21/17.
//  Copyright © 2017 Amr Lotfy. All rights reserved.
//

#import "AMRTools.h"
#import <AudioToolbox/AudioToolbox.h>

@implementation AMRTools
    
   
    
+ (AVAudioPlayer *)getPlayer {
    static AVAudioPlayer *player;
    static dispatch_once_t once;
    
    dispatch_once(&once, ^
                  {
                      player = [AVAudioPlayer new];
                  });
    
    return player;
}
    
+ (void)play:(NSString *)path {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"SoundOffFlag"]) {
        return;
    }
    NSString *fullPath =[NSString stringWithFormat:@"%@/%@",[[NSBundle mainBundle] resourcePath], path];
        
    NSURL *soundUrl= [NSURL fileURLWithPath:fullPath];
    
    NSLog(@"%@", soundUrl);
    NSData *audioData = [NSData dataWithContentsOfURL:soundUrl];
    NSError *error = nil;
    [[[AMRTools getPlayer] initWithData:audioData error:&error] play];
    
    
    }

+ (UIAlertController *)showMenuWithTitle:(NSString *)title message:(NSString *)message handlers:(NSDictionary *)handlers{
    UIAlertController *menu = [UIAlertController alertControllerWithTitle:title
                                                                  message:message
                                                           preferredStyle:UIAlertControllerStyleAlert];
    
    for (NSString *actionTitle in [handlers allKeys]) {
        UIAlertAction* action = [UIAlertAction actionWithTitle:actionTitle
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action) {
                                                           void (^ block)() = handlers[actionTitle];
                                                           block();
                                                       }];
        [menu addAction:action];
    }
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"OK"
                                                           style:UIAlertActionStyleDefault
                                                         handler:nil];
    
    
    
    [menu addAction:cancelAction];
    
    return menu;
}



+(Boolean) isRTL {
    //TODO refine later to be one call only
    static Boolean result = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray<NSString *> *locales = [[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"];
        result = locales != nil && locales.count > 0 && [locales[0] isEqualToString:@"ar-SA"];
        // Do any other initialisation stuff here
    });
    
    return result;
}

+(void)setLocaleArabic{
    [[NSUserDefaults standardUserDefaults] setObject:@[@"ar-SA"] forKey:@"AppleLanguages"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+(void)setLocaleEnglish{
    [[NSUserDefaults standardUserDefaults] setObject:@[@"en"] forKey:@"AppleLanguages"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}



+(NSString *)abbreviateNumber:(NSInteger)num withDecimal:(int)dec {
    
    if (num < 1000) {
        return [NSString stringWithFormat:@"%ld", (long)num];
    }
    NSString *abbrevNum = @"K";
    NSString *unit = @"K";
    float number = ((float)num) / 1000.f;
    if (number > 1000) {
        number = ((float)num) / 1000000.f;
        unit = @"M";
    }
    NSString *numberString = [self floatToString:number];
    abbrevNum = [NSString stringWithFormat:@"%@%@", numberString, unit];
    
    //NSLog(@"%@", abbrevNum);
    
    return abbrevNum;
}

+ (NSString *) floatToString:(float) val {
    
    NSString *ret = [NSString stringWithFormat:@"%.2f", val];
    
    return ret;
}

+(NSString *)uniqueID {
    NSNumber *updateDate =  [NSNumber numberWithLongLong:[[NSDate new] timeIntervalSince1970]];
    
    return updateDate.stringValue;
}

+(NSTimeInterval)averageIntervalBetweenDatesInArray:(NSArray<NSDate *> *)datesArray {
    NSMutableArray<NSNumber *> *timeIntervalNumbers = @[].mutableCopy;
    NSTimeInterval result = 0;
    
    for (NSInteger i = 1; i < datesArray.count; i = i + 1) {
        NSTimeInterval interval = [datesArray[i] timeIntervalSinceDate:datesArray[i - 1]];
        [timeIntervalNumbers addObject:[NSNumber numberWithInteger:interval]];
    }
    
    for (NSNumber *intervalNumber in timeIntervalNumbers) {
        result = result + [intervalNumber integerValue];
    }
    
    result = result / timeIntervalNumbers.count;
    
    return result;
}

#pragma mark - Email validation

+(BOOL)isValidEmail:(NSString *)checkString
{
    BOOL stricterFilter = NO; // Discussion http://blog.logichigh.com/2010/09/02/validating-an-e-mail-address/
    NSString *stricterFilterString = @"^[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}$";
    NSString *laxString = @"^.+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2}[A-Za-z]*$";
    NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:checkString];
}

#pragma mark - alert message

+ (void)showMenuWithTitle:(NSString *)title
                  message:(NSString *)message
           viewController:(UIViewController *)viewController
                okHandler:(void(^)(UIAlertAction * action))okBlock
            cancelHandler:(void(^)(UIAlertAction * action))cancelBlock
{
    UIAlertController *menu = [UIAlertController alertControllerWithTitle:title
                                                                  message:message
                                                           preferredStyle:UIAlertControllerStyleAlert];
    
    
    UIAlertAction* okAction = [UIAlertAction actionWithTitle: @"OK"
                                                       style:UIAlertActionStyleDefault
                                                     handler:okBlock];
    
    [menu addAction:okAction];
    
    
    if (cancelBlock != nil) {
        UIAlertAction* cancelAction = [UIAlertAction actionWithTitle: @"Cancel"
                                                               style:UIAlertActionStyleCancel
                                                             handler:cancelBlock];
        
        [menu addAction:cancelAction];
    }
    
    
    [viewController presentViewController:menu animated:YES completion:nil];
}

@end
