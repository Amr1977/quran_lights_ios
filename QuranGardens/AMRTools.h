//
//  AMRTools.h
//  QuranGardens
//
//  Created by Amr Lotfy on 3/21/17.
//  Copyright © 2017 Amr Lotfy. All rights reserved.
//

#import <Foundation/Foundation.h>
@import UIKit;

@interface AMRTools : NSObject

+ (UIAlertController *)showMenuWithTitle:(NSString *)title message:(NSString *)message handlers:(NSDictionary *)handlers;
+(NSString *)abbreviateNumber:(int)num withDecimal:(int)dec;

@end
