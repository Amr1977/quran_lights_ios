//
//  AMRTools.m
//  QuranGardens
//
//  Created by Amr Lotfy on 3/21/17.
//  Copyright © 2017 Amr Lotfy. All rights reserved.
//

#import "AMRTools.h"

@implementation AMRTools

+ (UIAlertController *)showMenuWithTitle:(NSString *)title handlers:(NSDictionary *)handlers{
    UIAlertController *menu = [UIAlertController alertControllerWithTitle:title
                                                                  message:@""
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

@end
