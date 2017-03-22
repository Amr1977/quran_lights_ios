//
//  AMRTools.m
//  QuranGardens
//
//  Created by Amr Lotfy on 3/21/17.
//  Copyright © 2017 Amr Lotfy. All rights reserved.
//

#import "AMRTools.h"

@implementation AMRTools

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

+(NSString *)abbreviateNumber:(int)num withDecimal:(int)dec {
    
    NSString *abbrevNum;
    float number = (float)num;
    
    NSArray *abbrev = @[@"K", @"M", @""];
    
    for (int i = abbrev.count - 1; i >= 0; i--) {
        
        // Convert array index to "1000", "1000000", etc
        int size = pow(10,(i+1)*3);
        
        if(size <= number) {
            // Here, we multiply by decPlaces, round, and then divide by decPlaces.
            // This gives us nice rounding to a particular decimal place.
            number = round(number*dec/size)/dec;
            
            NSString *numberString = [self floatToString:number];
            
            // Add the letter for the abbreviation
            abbrevNum = [NSString stringWithFormat:@"%@%@", numberString, [abbrev objectAtIndex:i]];
            
            NSLog(@"%@", abbrevNum);
            
        }
        
    }
    
    
    return abbrevNum;
}

+ (NSString *) floatToString:(float) val {
    
    NSString *ret = [NSString stringWithFormat:@"%.1f", val];
    unichar c = [ret characterAtIndex:[ret length] - 1];
    
    while (c == 48 || c == 46) { // 0 or .
        ret = [ret substringToIndex:[ret length] - 1];
        c = [ret characterAtIndex:[ret length] - 1];
    }
    
    return ret;
}

@end
