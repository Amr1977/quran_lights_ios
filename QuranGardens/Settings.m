//
//  Settings.m
//  QuranGardens
//
//  Created by Amr Lotfy on 8/19/16.
//  Copyright © 2016 Amr Lotfy. All rights reserved.
//

#import "Settings.h"

NSInteger const DefaultCycleInterval = 30*24*60*60;

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

- (NSString *)description{
    return [NSString stringWithFormat:@"fadeTime: %f , sortType: %lu, Descendingsort: %u", self.fadeTime, self.sortType, self.descendingSort];
}

- (id)copyWithZone:(NSZone *)zone {
    Settings *settingsCopy = [[Settings alloc] init];
    
    settingsCopy.fadeTime = self.fadeTime;
    settingsCopy.descendingSort = self.descendingSort;
    settingsCopy.sortType = self.sortType;
    
    return settingsCopy;
}


- (BOOL)isEqual:(Settings *)settings{
    return ((self.fadeTime == [settings fadeTime]) && (self.descendingSort == settings.descendingSort) && (self.sortType == settings.sortType));
}

@end
