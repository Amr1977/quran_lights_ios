//
//  Statistics.m
//  QuranGardens
//
//  Created by Amr Lotfy on 10/20/16.
//  Copyright © 2016 Amr Lotfy. All rights reserved.
//

#import "Statistics.h"
#import "Sura.h"
#import "NSString+Localization.h"

@implementation Statistics

- (instancetype)initWithDataSource:(DataSource *)dataSource{
    self = [super init];
    if (self) {
        _dataSource = dataSource;
    }
    
    return self;
}

- (NSDictionary<NSString *, NSNumber *> *)getKhatmaProgress:(NSInteger)khatmaIndex {
    NSMutableDictionary <NSString *, NSNumber *> *result = @{}.mutableCopy;
    NSInteger completed = 0;
    NSInteger remaining = 0;
    
    
    
    for (PeriodicTask *task in self.dataSource.tasks) {
        NSInteger suraIndex = [Sura.suraNames indexOfObject:task.name];
        NSNumber *charCount = [[Sura suraCharsCount] objectAtIndex:suraIndex];
        NSInteger taskScore = [charCount integerValue];
        
        if (task.history.count >= khatmaIndex) {
            completed += taskScore;
        } else {
            remaining += taskScore;
        }
    }
    
    if (completed != 0) {
        result[[@"Completed" localize]] = [NSNumber numberWithInteger:completed];
    }
    
    if (remaining != 0) {
        result[[@"Remaining" localize]] = [NSNumber numberWithInteger:remaining];
    }
    
    return result;
}

- (NSDictionary<NSString *, NSNumber *> *)getMemorizationStates {
    NSMutableDictionary <NSString *, NSNumber *> *result = @{}.mutableCopy;
    
    NSInteger memorized = 0;
    NSInteger beingMemorized = 0;
    NSInteger wasMemorized = 0;
    NSInteger notMemorized = 0;
    
    for (PeriodicTask *task in self.dataSource.tasks) {
        NSInteger suraIndex = [Sura.suraNames indexOfObject:task.name];
        NSNumber *charCount = [[Sura suraCharsCount] objectAtIndex:suraIndex];
        NSInteger taskScore = [charCount integerValue];
        
        switch (task.memorizedState) {
            case MEMORIZED:
                memorized += taskScore;
                break;
                
            case NOT_MEMORIZED:
                notMemorized += taskScore;
                break;
                
            case BEING_MEMORIZED:
                beingMemorized += taskScore;
                break;
                
            case WAS_MEMORIZED:
                wasMemorized += taskScore;
                break;
                
            default:
                break;
        }
    }
    
    if (memorized != 0) {
        result[[@"Memorized" localize]] = [NSNumber numberWithInteger:memorized];
    }
    
    if (beingMemorized != 0) {
        result[[@"Being Memorized" localize]] = [NSNumber numberWithInteger:beingMemorized];
    }
    
    if (wasMemorized != 0) {
        result[[@"Was Memorized" localize]] = [NSNumber numberWithInteger:wasMemorized];
    }
    
    if (notMemorized != 0) {
        result[[@"Not Memorized" localize]] = [NSNumber numberWithInteger:notMemorized];

    }
    
    return result;
}

- (NSInteger)memorizedScore {
    NSInteger result = 0;
    
    for (PeriodicTask *task in self.dataSource.tasks) {
        if (task.memorizedState == MEMORIZED) {
            NSInteger suraIndex = [Sura.suraNames indexOfObject:task.name];
            NSNumber *charCount = [[Sura suraCharsCount] objectAtIndex:suraIndex];
            NSInteger taskScore = [charCount integerValue];
            
            result += taskScore;
        }
    }
    
    return result;
}

+ (NSInteger)allSurasScore {
    static NSInteger result = 0;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        for (NSInteger i = 0; i < 114; i++) {
            NSNumber *charCount = [[Sura suraCharsCount] objectAtIndex:i];
            NSInteger taskScore = [charCount integerValue];
            result += taskScore;
        }
    } );
    
    return result;
}

    
- (NSInteger)scoreForDate:(NSDate *)date {
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [cal components:( NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond ) fromDate:[[NSDate alloc] init]];
    
    [components setHour:-[components hour]];
    [components setMinute:-[components minute]];
    [components setSecond:-[components second]];
    NSDate *endDay = [[NSCalendar currentCalendar] startOfDayForDate:date];
    
    [components setHour:-24];
    [components setMinute:0];
    [components setSecond:0];
    NSDate *startDay = [cal dateByAddingComponents:components toDate: endDay options:0];
    
    NSInteger result = 0;
    
    for (PeriodicTask *task in self.dataSource.tasks) {
        NSInteger suraIndex = [Sura.suraNames indexOfObject:task.name];
        NSNumber *charCount = [[Sura suraCharsCount] objectAtIndex:suraIndex];
        NSInteger taskScore = [charCount integerValue];
        
        for (NSInteger i = 0; i < task.history.count ; i++) {
            NSDate *date = task.history[i];
            if ([date compare:endDay] == NSOrderedAscending && [date compare:startDay] == NSOrderedDescending) {
                result += taskScore;
            }
        }
    }
    
    return result;
}
    
- (NSDictionary<NSDate *, NSNumber *> *)scores {
    NSMutableDictionary<NSDate *, NSNumber *> * result = @{}.mutableCopy;
    
    for (PeriodicTask *task in self.dataSource.tasks) {
        NSInteger suraIndex = [Sura.suraNames indexOfObject:task.name];
        NSNumber *charCount = [[Sura suraCharsCount] objectAtIndex:suraIndex];
        NSInteger taskScore = [charCount integerValue];
        
        for (NSInteger i = 0; i < task.history.count ; i++) {
            NSDate *date = [[[NSCalendar currentCalendar] startOfDayForDate:task.history[i]] dateByAddingTimeInterval:12 * 60 * 60];
            result[date] = result[date] != nil ?
            [NSNumber numberWithInteger:((result[date]).integerValue + taskScore)] :
            [NSNumber numberWithInteger:taskScore];
        }
    }
    
    NSMutableArray<NSDate *> * ordered = result.allKeys.mutableCopy;
    
    [ordered sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSDate *d1 = (NSDate *)obj1;
        NSDate *d2 = (NSDate *)obj2;
        return [d1 compare:d2];
    }];
    
    for (NSDate *date in ordered) {
        NSLog(@"date %@", date);
    }
    
    //NSMutableArray <NSDate *>* allDates = ordered;//[result allKeys].mutableCopy;
    
    NSDate *minDate = [ordered firstObject];
    NSDate *LastDate =  [[NSCalendar currentCalendar] startOfDayForDate:[NSDate new]];
    
    if (minDate != nil) {
        NSInteger numberOfDays = [Statistics daysBetweenDate:minDate andDate:LastDate];
        
        NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
        dayComponent.day = 1;
        //dayComponent.hour = 12;
        NSCalendar *theCalendar = [NSCalendar currentCalendar];
        
        NSDate *nextDate = minDate;
        
        //fill zeros in dates without score
        for (NSInteger i = 1; i < numberOfDays; i++) {
            nextDate = [theCalendar dateByAddingComponents:dayComponent toDate:nextDate options:0];
            if (![ordered containsObject:nextDate]) {
                result[nextDate] = [NSNumber numberWithInteger:0];
                NSLog(@"Added zero scoe for date %@", nextDate);
            }
        }
    }
    
    return result;
}
    
    + (NSInteger)daysBetweenDate:(NSDate*)fromDateTime andDate:(NSDate*)toDateTime
    {
        NSDate *fromDate;
        NSDate *toDate;
        
        NSCalendar *calendar = [NSCalendar currentCalendar];
        
        [calendar rangeOfUnit:NSCalendarUnitDay startDate:&fromDate
                     interval:NULL forDate:fromDateTime];
        [calendar rangeOfUnit:NSCalendarUnitDay startDate:&toDate
                     interval:NULL forDate:toDateTime];
        
        NSDateComponents *difference = [calendar components:NSCalendarUnitDay
                                                   fromDate:fromDate toDate:toDate options:0];
        
        
        NSInteger result = [difference day];
        
        NSLog(@"difference %ld", (long)result);
        
        return result;
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
