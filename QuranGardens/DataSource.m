//
//  DataSource.m
//  QuranGardens
//
//  Created by Amr Lotfy on 8/16/16.
//  Copyright © 2016 Amr Lotfy. All rights reserved.
//

#import "DataSource.h"
#import "Sura.h"

NSString * const IntervalKeySuffix = @"interval";
NSString * const LastRefreshKeySuffix = @"lastRefresh";

NSString * const GlobalRefreshIntervaKey = @"GlobalRefreshIntervaKey";
NSString * const SortDirectionKey = @"SortDirectionKey";
NSString * const SortTypeKey = @"SortTypeKey";

@implementation DataSource

- (void)listTasksData{
    for (PeriodicTask *sura in self.tasks) {
        NSLog(@"%@, CycleInterval: %f , last Refresh: %@",sura.name, sura.cycleInterval, sura.lastOccurrence);
    }
}

- (void)load{
        self.tasks = @[].mutableCopy;
        for (NSString *suraName in [Sura suraNames]) {
            NSTimeInterval interval = [[[NSUserDefaults standardUserDefaults] objectForKey:[self cyclePeriodKeyForSuraName:suraName]] doubleValue];
            NSDate *lastRefresh = [[NSUserDefaults standardUserDefaults] objectForKey:[self lastRefreshKeyForSuraName:suraName]];
            PeriodicTask *task = [[PeriodicTask alloc] init];
            task.name = suraName;
            if (!interval) {
                interval = DefaultCycleInterval;
            }
            task.cycleInterval = interval;
            if (!lastRefresh) {
                lastRefresh = [NSDate dateWithTimeIntervalSince1970:0];
            }
            task.lastOccurrence = lastRefresh;
            [self.tasks addObject:task];
        }
    NSLog(@"Load completed.");
    [self listTasksData];
    [self loadSettings];
}

- (void)save{
    NSLog(@"Saving...");
    [self listTasksData];
    for (PeriodicTask *task in self.tasks) {
        //period
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithDouble:task.cycleInterval] forKey:[self cyclePeriodKeyForSuraName:task.name]];
        
        //last refresh
        [[NSUserDefaults standardUserDefaults] setObject:task.lastOccurrence forKey:[self lastRefreshKeyForSuraName:task.name]];
    }
    
    //TODO: save settings
    
    
}

- (NSString *)cyclePeriodKeyForSuraName:(NSString *)suraName{
    return [NSString stringWithFormat:@"%@_%@",suraName,IntervalKeySuffix];
}

- (NSString *)lastRefreshKeyForSuraName:(NSString *)suraName{
    return [NSString stringWithFormat:@"%@_%@",suraName,LastRefreshKeySuffix];
}

- (NSTimeInterval)loadSuraCyclePeriod:(NSString *)suraName{
    NSTimeInterval result = DefaultCycleInterval;
    NSString *suraIntervalKey = [NSString stringWithFormat:@"%@_%@",suraName,IntervalKeySuffix];
    NSNumber *intervalObject = [[NSUserDefaults standardUserDefaults] objectForKey:suraIntervalKey];
    
    if (intervalObject) {
        result = [intervalObject doubleValue];
    }
    
    return result;
}

- (void)saveSuraCyclePeriod:(NSTimeInterval)period suraName:(NSString *)suraName{
    [[NSUserDefaults standardUserDefaults] setDouble:period forKey:[self cyclePeriodKeyForSuraName:suraName]];
    NSLog(@"saved for %@ cycle: %f",suraName,period);
}

- (NSDate *)loadSuraLastRefresh:(NSString *)suraName{
    NSDate *result = [NSDate dateWithTimeIntervalSince1970:0];
    NSString *suraLastRefreshKey = [NSString stringWithFormat:@"%@_%@",suraName,LastRefreshKeySuffix];
    NSDate *lastRefresh = [[NSUserDefaults standardUserDefaults] objectForKey:suraLastRefreshKey];
    
    if (lastRefresh) {
        result = lastRefresh;
    }
    
    return result;
}

- (void)saveSuraLastRefresh:(NSDate *)lastRefreshDate suraName:(NSString *)suraName{
    [[NSUserDefaults standardUserDefaults] setObject:lastRefreshDate forKey:[self lastRefreshKeyForSuraName:suraName]];
    NSLog(@"saved for %@ refreshed at: %@",suraName,lastRefreshDate);
}

- (void)saveSettings{
    [[NSUserDefaults standardUserDefaults] setBool:self.settings.descendingSort forKey:SortDirectionKey];
    [[NSUserDefaults standardUserDefaults] setDouble:self.settings.fadeTime forKey:GlobalRefreshIntervaKey];
    [[NSUserDefaults standardUserDefaults] setInteger:self.settings.sortType forKey:SortTypeKey];
}

- (void)loadSettings{
    //TODO: load defaults if keys do not exist    
    self.settings.descendingSort = [[NSUserDefaults standardUserDefaults] boolForKey:SortDirectionKey];
    self.settings.fadeTime = [[NSUserDefaults standardUserDefaults] doubleForKey:GlobalRefreshIntervaKey];
    self.settings.sortType = (SorterType) [[NSUserDefaults standardUserDefaults] integerForKey:SortTypeKey];
}

@end
