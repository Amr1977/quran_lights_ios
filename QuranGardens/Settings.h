//
//  Settings.h
//  QuranGardens
//
//  Created by Amr Lotfy on 8/19/16.
//  Copyright © 2016 Amr Lotfy. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSInteger const DefaultCycleInterval;

typedef NS_OPTIONS(NSUInteger, SorterType) {
    NormalSuraOrderSort = 0,
    LightSort = 1,
    RevalationOrderSort = 2,
    VersesCountSort = 3,
    WordCountSort = 4,
    CharCountSort = 5,
};

typedef NS_OPTIONS(NSUInteger, SortDirection) {
    Ascending = 0,
    Descending = 1
};

@interface Settings : NSObject

@property (nonatomic) unsigned long fadeTime;
@property (strong, nonatomic) NSString *sortType;

+ (NSArray<NSString *>*)sortTypeList;

@end
