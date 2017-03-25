//
//  Statistics.m
//  QuranGardens
//
//  Created by Amr Lotfy on 10/20/16.
//  Copyright © 2016 Amr Lotfy. All rights reserved.
//

#import "Statistics.h"
#import "Sura.h"

@implementation Statistics

- (instancetype)initWithDataSource:(DataSource *)dataSource{
    self = [super init];
    if (self) {
        _dataSource = dataSource;
    }
    
    return self;
}

- (NSInteger)todayScore{
    NSInteger result = 0;
    NSDate *todayStart = [[NSCalendar currentCalendar] startOfDayForDate:[NSDate new]];
    
    for (PeriodicTask *task in self.dataSource.tasks) {
        NSInteger suraIndex = [Sura.suraNames indexOfObject:task.name];
        NSNumber *charCount = [[Sura suraCharsCount] objectAtIndex:suraIndex];
        NSInteger taskScore = [charCount integerValue];
        
        for (NSInteger i = 0; i < task.history.count ; i++) {
            NSDate *date = task.history[i];
            if ([date compare:todayStart] == NSOrderedDescending) {
                result += taskScore;
            }
        }
    }
    
    return result;
}

+ (NSInteger)suraScore:(NSString *)suraName {
    NSInteger suraIndex = [Sura.suraNames indexOfObject:suraName];
    if (suraIndex != NSNotFound) {
    NSNumber *charCount = [[Sura suraCharsCount] objectAtIndex:suraIndex];
        return charCount.integerValue;
    } else {
        return 0;
    }
}

- (NSInteger)yesterdayScore{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [cal components:( NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond ) fromDate:[[NSDate alloc] init]];
    
    [components setHour:-[components hour]];
    [components setMinute:-[components minute]];
    [components setSecond:-[components second]];
    NSDate *today = [[NSCalendar currentCalendar] startOfDayForDate:[NSDate new]];
    //This variable should now be pointing at a date object that is the start of today (midnight);
    
    [components setHour:-24];
    [components setMinute:0];
    [components setSecond:0];
    NSDate *yesterday = [cal dateByAddingComponents:components toDate: today options:0];
    
    NSInteger result = 0;
    
    for (PeriodicTask *task in self.dataSource.tasks) {
        NSInteger suraIndex = [Sura.suraNames indexOfObject:task.name];
        NSNumber *charCount = [[Sura suraCharsCount] objectAtIndex:suraIndex];
        NSInteger taskScore = [charCount integerValue];
        
        for (NSInteger i = 0; i < task.history.count ; i++) {
            NSDate *date = task.history[i];
            if ([date compare:today] == NSOrderedAscending && [date compare:yesterday] == NSOrderedDescending) {
                result += taskScore;
            }
        }
    }
    
    return result;
}

- (NSInteger)totalScore{
    NSInteger result = 0;
    
    for (PeriodicTask *task in self.dataSource.tasks) {
        NSInteger suraIndex = [Sura.suraNames indexOfObject:task.name];
        NSNumber *charCount = [[Sura suraCharsCount] objectAtIndex:suraIndex];
        NSInteger taskScore = [charCount integerValue];
        //TODO: fix issue of redundant initial history date then remove this -1
        result = result + ((task.history.count) * taskScore);
    }
    
    return result;
}

- (NSInteger)scoreBetweenStartDate:(NSDate *)startDate endDate:(NSDate *)endDate{
    //TODO: do it !
    return 0;
}

@end
