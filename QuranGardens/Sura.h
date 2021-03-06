//
//  Sura.h
//  QuranGardens
//
//  Created by Amr Lotfy on 1/29/16.
//  Copyright © 2016 Amr Lotfy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PeriodicTask.h"

@interface Sura : PeriodicTask

/** Sura order in mushaf. */
@property (nonatomic) NSInteger order;

+ (NSString *)suraNameToIndexString:(NSString *)suraName;
+ (NSString *)suraIndexFromSuraName:(NSString *)suraName;

+ (NSArray<NSString *> *)suraNames;
+ (NSArray<NSNumber *> *)readNumbersFromFile:(NSString *)fileName;
+ (NSArray<NSString *> *)readLinesFromFile:(NSString *)fileName;

+ (NSArray <NSNumber *> *)suraCharsCount;
+ (NSArray <NSNumber *> *)suraVerseCount;
+ (NSArray <NSNumber *> *)suraWordCount;
+ (NSArray <NSNumber *> *)suraRevalOrder;

@end
