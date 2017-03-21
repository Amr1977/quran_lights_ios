//
//  DataSource.m
//  QuranGardens
//
//  Created by Amr Lotfy on 8/16/16.
//  Copyright © 2016 Amr Lotfy. All rights reserved.
//

#import "DataSource.h"
#import "Sura.h"
#import "Statistics.h"
#import "AppDelegate.h"

NSString * const IntervalKeySuffix = @"interval";
NSString * const LastRefreshKeySuffix = @"lastRefresh";
NSString * const MemorizedKeySuffix = @"memorized";
NSString * const RefreshHistoryKeySuffix = @"RefreshHistory";

NSString * const GlobalRefreshIntervalKey = @"GlobalRefreshIntervalKey";
NSString * const SortDirectionKey = @"SortDirectionKey";
NSString * const SortTypeKey = @"SortTypeKey";

@implementation DataSource

- (Settings *)settings {
    if (!_settings) {
        _settings = [[Settings alloc] init];
        _settings.fadeTime = DefaultCycleInterval;
        _settings.sortType = NormalSuraOrderSort;
        _settings.descendingSort = NO;
    }
    
    return _settings;
}

- (void)listTasksData{
//    for (PeriodicTask *sura in self.tasks) {
//        NSLog(@"%@, CycleInterval: %f , last Refresh: %@",sura.name, sura.cycleInterval, sura.lastOccurrence);
//    }
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)onFirebaseSignIn{
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"UploadedToFireBase"]) {
        for (PeriodicTask *task in self.tasks) {
            [((AppDelegate *)[UIApplication sharedApplication].delegate) refreshSura:[self suraIndexFromSuraName:task.name] withHistory:task.history];
        }
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"UploadedToFireBase"];
    }
    
}

- (void)load{
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onFirebaseSignIn) name:FireBaseSignInNotification object:nil];
    
    self.tasks = @[].mutableCopy;
    for (NSString *suraName in [Sura suraNames]) {
        NSTimeInterval interval = [[[NSUserDefaults standardUserDefaults] objectForKey:[self cyclePeriodKeyForSuraName:suraName]] doubleValue];

        PeriodicTask *task = [[PeriodicTask alloc] init];
        task.name = suraName;
        task.memorizedState = [self loadMemorizedStateForSura:suraName];
        if (!interval) {
            interval = DefaultCycleInterval;
        }
        task.cycleInterval = interval;
        
        task.history = [self loadRefreshHistoryForSuraName:suraName];
        
        [self.tasks addObject:task];
    }
    
    NSLog(@"Load completed.");
    [self listTasksData];
    [self loadSettings];
    [Sura readNumbersFromFile:@"versecount"];
    [Sura readNumbersFromFile:@"charcount"];
    [Sura readNumbersFromFile:@"wordcount"];
}

- (void)save{
    NSLog(@"Saving...");
    [self listTasksData];
    for (PeriodicTask *task in self.tasks) {
        //period
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithDouble:task.cycleInterval] forKey:[self cyclePeriodKeyForSuraName:task.name]];
        
        //last refresh
        //[[NSUserDefaults standardUserDefaults] setObject:task.lastOccurrence forKey:[self lastRefreshKeyForSuraName:task.name]];
    }
    
    //TODO: save settings
}


#pragma mark - import and export to file

- (NSString *)fullFilePath:(NSString *)fileName{
    //Creating a file path under iOS:
    //1) Search for the app's documents directory (copy+paste from Documentation)
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    //2) Create the full file path by appending the desired file name
    return [documentsDirectory stringByAppendingPathComponent:fileName];
}

- (void)loadFromFile:(NSString *)fileName completionBlock:(void(^)(BOOL success))completionBlock{
    NSString *fullFilePath = [self fullFilePath:fileName];
    NSArray *plistArray = [[NSArray alloc] initWithContentsOfFile:fullFilePath];
    
    if (!plistArray) {
        completionBlock(NO);
        return;
    }
    
    NSMutableArray *tasks = @[].mutableCopy;
    
    for (NSDictionary *plist in plistArray) {
        PeriodicTask *task = [[PeriodicTask alloc] initWithPList:plist];
        [tasks addObject:task];
    }
    
    self.tasks = tasks;
    
    completionBlock(YES);
}

- (void)saveToFile:(NSString *)fileName completion:(void (^)(BOOL success))completionBlock{
    NSString *fullFilePath = [self fullFilePath:fileName];
    
    NSMutableArray *tasksPListArray = @[].mutableCopy;
    
    for (PeriodicTask *task in self.tasks) {
        [tasksPListArray addObject:task.toPList];
    }
    
    BOOL success = [tasksPListArray writeToFile:fullFilePath atomically:YES];
    completionBlock(success);
}

- (NSString *)cyclePeriodKeyForSuraName:(NSString *)suraName{
    return [NSString stringWithFormat:@"%@_%@",suraName,IntervalKeySuffix];
}

- (NSString *)memorizedKeyForSuraName:(NSString *)suraName{
    return [NSString stringWithFormat:@"%@_%@",suraName,MemorizedKeySuffix];
}

- (NSString *)lastRefreshKeyForSuraName:(NSString *)suraName{
    return [NSString stringWithFormat:@"%@_%@",suraName,LastRefreshKeySuffix];
}

- (NSString *)refreshHistoryKeyForSuraName:(NSString *)suraName{
    return [NSString stringWithFormat:@"%@_%@",suraName,RefreshHistoryKeySuffix];
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

- (PeriodicTask *)getTaskWithSuraName:(NSString *)suraName{
    for (PeriodicTask *task in self.tasks) {
        if ([task.name isEqualToString:suraName]) {
            return task;
        }
    }
    
    return nil;
}

- (void)saveSuraLastRefresh:(NSDate *)lastRefreshDate suraName:(NSString *)suraName{

    //local
    [[NSUserDefaults standardUserDefaults] setObject:lastRefreshDate forKey:[self lastRefreshKeyForSuraName:suraName]];
    NSLog(@"saved for %@ refreshed at: %@",suraName,lastRefreshDate);
    PeriodicTask *task = [self getTaskWithSuraName:suraName];
    NSMutableArray<NSDate *> * oldHistory = task.history.mutableCopy;
    [oldHistory addObject:lastRefreshDate];
    task.history = oldHistory;
    [[NSUserDefaults standardUserDefaults] setObject:task.history forKey:[self refreshHistoryKeyForSuraName:suraName]];
    
    //remote
    NSNumber *dateStamp = [NSNumber numberWithLongLong:[lastRefreshDate timeIntervalSince1970]];
    [((AppDelegate *)[UIApplication sharedApplication].delegate) refreshSura:suraName withDate:dateStamp];
}

- (NSString *)suraIndexFromSuraName:(NSString *)suraName{
    return [NSString stringWithFormat:@"%lu",((unsigned long) [Sura.suraNames indexOfObject:suraName] + 1)];
}

- (NSMutableArray<NSDate *>*)loadRefreshHistoryForSuraName:(NSString *)suraName{
    NSMutableArray<NSDate *>* history = [[NSUserDefaults standardUserDefaults] objectForKey:[self refreshHistoryKeyForSuraName:suraName]];
    if(!history){
        history = @[].mutableCopy;
    }
    return history;
}

- (void)setHistory:(NSString *)suraName history:(NSArray<NSDate *> *)history{
    [[NSUserDefaults standardUserDefaults] setObject:history forKey:[self refreshHistoryKeyForSuraName:suraName]];
}

- (void)saveSettings{
    [[NSUserDefaults standardUserDefaults] setBool:self.settings.descendingSort forKey:SortDirectionKey];
    [[NSUserDefaults standardUserDefaults] setDouble:self.settings.fadeTime forKey:GlobalRefreshIntervalKey];
    [[NSUserDefaults standardUserDefaults] setInteger:self.settings.sortType forKey:SortTypeKey];
}

- (void)loadSettings{
    NSLog(@"Loading Settings...");
    if ([[NSUserDefaults standardUserDefaults] objectForKey:SortDirectionKey]) {
        self.settings.descendingSort = [[NSUserDefaults standardUserDefaults] boolForKey:SortDirectionKey];
    } else {
        self.settings.descendingSort = NO;
        [[NSUserDefaults standardUserDefaults] setBool:self.settings.descendingSort forKey:SortDirectionKey];
    }
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:GlobalRefreshIntervalKey]) {
        self.settings.fadeTime = [[NSUserDefaults standardUserDefaults] doubleForKey:GlobalRefreshIntervalKey];
        if (!self.settings.fadeTime) {
            self.settings.fadeTime = DefaultCycleInterval;
            [[NSUserDefaults standardUserDefaults] setDouble:self.settings.fadeTime forKey:GlobalRefreshIntervalKey];
        }
    } else {
        self.settings.fadeTime = DefaultCycleInterval;
        [[NSUserDefaults standardUserDefaults] setDouble:self.settings.fadeTime forKey:GlobalRefreshIntervalKey];
    }
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:SortTypeKey]) {
        self.settings.sortType = (SorterType) [[NSUserDefaults standardUserDefaults] integerForKey:SortTypeKey];
    } else {
        self.settings.sortType = NormalSuraOrderSort;
        [[NSUserDefaults standardUserDefaults] setInteger:self.settings.sortType forKey:SortTypeKey];
    }
    
    NSLog(@"Loaded Settings: %@", self.settings);
}

- (NSInteger)loadMemorizedStateForSura:(NSString *)suraName{
    return [[NSUserDefaults standardUserDefaults] integerForKey:[self memorizedKeyForSuraName:suraName]];
}

- (void)saveMemorizedStateForSura:(NSString *)suraName{
    PeriodicTask* sura = [self getTaskWithSuraName:suraName];
    [[NSUserDefaults standardUserDefaults] setInteger:sura.memorizedState forKey:[self memorizedKeyForSuraName:suraName]];
    [((AppDelegate *)[UIApplication sharedApplication].delegate) refreshSura:suraName withMemorization:sura.memorizedState];
}

- (void)saveMemorizedStateForTask:(PeriodicTask *)task{
    if (task) {
        [[NSUserDefaults standardUserDefaults] setInteger:task.memorizedState forKey:[self memorizedKeyForSuraName:task.name]];
        [((AppDelegate *)[UIApplication sharedApplication].delegate) refreshSura:task.name withMemorization:task.memorizedState];
    }
}

@end
