//
//  Settings.m
//  QuranGardens
//
//  Created by Amr Lotfy on 8/19/16.
//  Copyright © 2016 Amr Lotfy. All rights reserved.
//

#import "Settings.h"

NSInteger const DefaultCycleInterval = 180;//60*24*60*60;

@implementation Settings

+ (NSArray <NSString *>*)sortTypeList{
    static NSArray *sortTypes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sortTypes = @[@"Moshaf Order",
                      @"Light Strength",
                      @"Revelation Order",
                      @"Verses Count",
                      @"Word Count",
                      @"Character Count"
                      ];
    });
    
    return sortTypes;
}

@end
