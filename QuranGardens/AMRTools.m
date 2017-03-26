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

+(NSString *)abbreviateNumber:(NSInteger)num withDecimal:(int)dec {
    
    if (num < 500) {
        return [NSString stringWithFormat:@"%d", num];
    }
    NSString *abbrevNum;
    float number = ((float)num) / 1000.f;
    
    NSString *numberString = [self floatToString:number];
    abbrevNum = [NSString stringWithFormat:@"%@K", numberString];
    
    NSLog(@"%@", abbrevNum);
    
    return abbrevNum;
}

+ (NSString *) floatToString:(float) val {
    
    NSString *ret = [NSString stringWithFormat:@"%.1f", val];
    
    return ret;
}

@end
