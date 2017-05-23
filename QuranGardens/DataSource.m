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
#import "AMRTools.h"

NSString * const IntervalKeySuffix = @"interval";
NSString * const LastRefreshKeySuffix = @"lastRefresh";
NSString * const MemorizedKeySuffix = @"memorized";
NSString * const RefreshHistoryKeySuffix = @"RefreshHistory";

NSString * const GlobalRefreshIntervalKey = @"GlobalRefreshIntervalKey";
NSString * const SortDirectionKey = @"SortDirectionKey";
NSString * const SortTypeKey = @"SortTypeKey";

NSString * const ShowVerseCountKey = @"ShowVerseCountKey";
NSString * const ShowMemorizationStateKey = @"ShowMemorizationStateKey";
NSString * const ShowSuraIndexKey = @"ShowSuraIndexKey";
NSString * const ShowRefreshCountKey = @"ShowRefreshCountKey";
NSString * const ShowCharacterCountKey = @"ShowCharacterCountKey";
NSString * const ShowElapsedDaysKey = @"ShowElapsedDaysKey";

@implementation DataSource

@synthesize currentUser = _currentUser;

- (Settings *)settings {
    if (!_settings) {
        _settings = [[Settings alloc] init];
        _settings.fadeTime = DefaultCycleInterval;
        _settings.sortType = NormalSuraOrderSort;
        _settings.descendingSort = NO;
        
        _settings.showVerseCount = NO;
        _settings.showMemorizationMark = YES;
        
        _settings.showSuraIndex = YES;
        _settings.showRefreshCount = NO;
        
        _settings.showCharacterCount = NO;
        _settings.showElapsedDaysCount = NO;
        
    }
    
    return _settings;
}

- (void)listTasksData{
    for (PeriodicTask *sura in self.tasks) {
        NSLog(@"%@, CycleInterval: %f , last Refresh: %@",sura.name, sura.cycleInterval, [sura.history lastObject]);
    }
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
    [self loadUsers];
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
//    [Sura readNumbersFromFile:@"versecount"];
//    [Sura readNumbersFromFile:@"charcount"];
//    [Sura readNumbersFromFile:@"wordcount"];
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
    [self saveUsers];
    [[NSUserDefaults standardUserDefaults] synchronize];
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
    return [NSString stringWithFormat:@"%@_%@",suraName,[self userKey:IntervalKeySuffix]];
}

- (NSString *)memorizedKeyForSuraName:(NSString *)suraName{
    return [NSString stringWithFormat:@"%@_%@",suraName,[self userKey:MemorizedKeySuffix]];
}

- (NSString *)lastRefreshKeyForSuraName:(NSString *)suraName{
    return [NSString stringWithFormat:@"%@_%@",suraName,[self userKey:LastRefreshKeySuffix]];
}

- (NSString *)refreshHistoryKeyForSuraName:(NSString *)suraName{
    return [NSString stringWithFormat:@"%@_%@",suraName,[self userKey:RefreshHistoryKeySuffix]];
}

- (NSTimeInterval)loadSuraCyclePeriod:(NSString *)suraName{
    NSTimeInterval result = DefaultCycleInterval;
    NSString *suraIntervalKey = [NSString stringWithFormat:@"%@_%@",suraName,[self userKey:IntervalKeySuffix]];
    NSNumber *intervalObject = [[NSUserDefaults standardUserDefaults] objectForKey:suraIntervalKey];
    
    if (intervalObject) {
        result = [intervalObject doubleValue];
    }
    
    return result;
}

- (void)saveSuraCyclePeriod:(NSTimeInterval)period suraName:(NSString *)suraName{
    [[NSUserDefaults standardUserDefaults] setDouble:period forKey:[self cyclePeriodKeyForSuraName:suraName]];
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSLog(@"saved for %@ cycle: %f",suraName,period);
}

- (NSDate *)loadSuraLastRefresh:(NSString *)suraName{
    NSDate *result = [NSDate dateWithTimeIntervalSince1970:0];
    NSString *suraLastRefreshKey = [NSString stringWithFormat:@"%@_%@",suraName,[self userKey:[self userKey:LastRefreshKeySuffix]]];
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
    
    NSNumber *updateDate =  [NSNumber numberWithLongLong:[[NSDate new] timeIntervalSince1970]];
    [[NSUserDefaults standardUserDefaults] setObject:updateDate forKey:@"LastUpdateTimeStamp"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
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
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)saveSettings{
    [[NSUserDefaults standardUserDefaults] setBool:self.settings.descendingSort
                                            forKey:[self userKey: SortDirectionKey]];
    
    [[NSUserDefaults standardUserDefaults] setDouble:self.settings.fadeTime
                                              forKey:[self userKey:GlobalRefreshIntervalKey]];
    
    [[NSUserDefaults standardUserDefaults] setInteger:self.settings.sortType
                                               forKey:[self userKey: SortTypeKey]];
    
    [[NSUserDefaults standardUserDefaults] setBool:self.settings.showVerseCount
                                            forKey:[self userKey:ShowVerseCountKey]];
    
    [[NSUserDefaults standardUserDefaults] setBool:self.settings.showMemorizationMark
                                            forKey:[self userKey:ShowMemorizationStateKey]];
    
    
    [[NSUserDefaults standardUserDefaults] setBool:self.settings.showSuraIndex
                                            forKey:[self userKey:ShowSuraIndexKey]];
    
    
    [[NSUserDefaults standardUserDefaults] setBool:self.settings.showRefreshCount
                                            forKey:[self userKey:ShowRefreshCountKey]];
    
    [[NSUserDefaults standardUserDefaults] setBool:self.settings.showCharacterCount
                                            forKey:[self userKey:ShowCharacterCountKey]];
    
    [[NSUserDefaults standardUserDefaults] setBool:self.settings.showElapsedDaysCount
                                            forKey:[self userKey:ShowElapsedDaysKey]];
    
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)loadSettings{
    NSLog(@"Loading Settings...");
    if ([[NSUserDefaults standardUserDefaults] objectForKey:[self userKey:SortDirectionKey]]) {
        self.settings.descendingSort = [[NSUserDefaults standardUserDefaults] boolForKey:[self userKey:SortDirectionKey]];
    } else {
        self.settings.descendingSort = NO;
        [[NSUserDefaults standardUserDefaults] setBool:self.settings.descendingSort forKey:[self userKey:SortDirectionKey]];
    }
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:[self userKey:GlobalRefreshIntervalKey]]) {
        self.settings.fadeTime = [[NSUserDefaults standardUserDefaults] doubleForKey:[self userKey:GlobalRefreshIntervalKey]];
        if (!self.settings.fadeTime) {
            self.settings.fadeTime = DefaultCycleInterval;
            [[NSUserDefaults standardUserDefaults] setDouble:self.settings.fadeTime
                                                      forKey:[self userKey:GlobalRefreshIntervalKey]];
        }
    } else {
        self.settings.fadeTime = DefaultCycleInterval;
        [[NSUserDefaults standardUserDefaults] setDouble:self.settings.fadeTime
                                                  forKey:[self userKey:GlobalRefreshIntervalKey]];
    }
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:SortTypeKey]) {
        self.settings.sortType = (SorterType) [[NSUserDefaults standardUserDefaults] integerForKey:[self userKey:SortTypeKey]];
    } else {
        self.settings.sortType = NormalSuraOrderSort;
        [[NSUserDefaults standardUserDefaults] setInteger:self.settings.sortType
                                                   forKey:[self userKey:SortTypeKey]];
    }
    
    
    self.settings.showVerseCount = [[NSUserDefaults standardUserDefaults] boolForKey:[self userKey:ShowVerseCountKey]];
    
    self.settings.showMemorizationMark = [[NSUserDefaults standardUserDefaults] boolForKey:[self userKey:ShowMemorizationStateKey]];
    
    self.settings.showSuraIndex = [[NSUserDefaults standardUserDefaults] boolForKey:[self userKey:ShowSuraIndexKey]];
    
    
    self.settings.showRefreshCount = [[NSUserDefaults standardUserDefaults] boolForKey:[self userKey:ShowRefreshCountKey]];
    
    self.settings.showCharacterCount = [[NSUserDefaults standardUserDefaults] boolForKey:[self userKey:ShowCharacterCountKey]];
    
    self.settings.showElapsedDaysCount = [[NSUserDefaults standardUserDefaults] boolForKey:[self userKey:ShowElapsedDaysKey]];
    
    NSLog(@"Loaded Settings: %@", self.settings);
}

- (NSInteger)loadMemorizedStateForSura:(NSString *)suraName{
    return [[NSUserDefaults standardUserDefaults] integerForKey:[self memorizedKeyForSuraName:suraName]];
}

- (void)saveMemorizedStateForSura:(NSString *)suraName{
    PeriodicTask* sura = [self getTaskWithSuraName:suraName];
    [[NSUserDefaults standardUserDefaults] setInteger:sura.memorizedState forKey:[self memorizedKeyForSuraName:suraName]];
    [((AppDelegate *)[UIApplication sharedApplication].delegate) refreshSura:suraName withMemorization:sura.memorizedState];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setMemorizedStateForSura:(NSString *)suraName state:(NSInteger)state {
    [[NSUserDefaults standardUserDefaults] setInteger:state forKey:[self memorizedKeyForSuraName:suraName]];
    [((AppDelegate *)[UIApplication sharedApplication].delegate) refreshSura:suraName withMemorization:state];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)saveMemorizedStateForTask:(PeriodicTask *)task{
    if (task) {
        [[NSUserDefaults standardUserDefaults] setInteger:task.memorizedState forKey:[self memorizedKeyForSuraName:task.name]];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [((AppDelegate *)[UIApplication sharedApplication].delegate) refreshSura:task.name withMemorization:task.memorizedState];
    }
}

#pragma mark - Users

- (NSString *)userKey:(NSString *)key {
    NSString *result = [NSString stringWithFormat:@"%@%@",[self getCurrentUser].userId,key];
    NSLog(@"converted key: [%@] to: [%@]", key, result);
    return result;
}

- (void)addUser:(NSString *)userName {
    User *user = [[User alloc] init];
    user.userId = [AMRTools uniqueID];
    user.name = userName;
    [self.users addObject:user];
}

#define UsersHashKey @"UsersHashKey"

- (void)saveUsers {
    NSMutableDictionary <NSString *, NSString *> *usersHash = @{}.mutableCopy;
    
    for (User *user in self.users) {
        usersHash[user.userId] = user.name;
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:usersHash forKey:UsersHashKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)loadUsers {
    NSDictionary *usersHash = [[NSUserDefaults standardUserDefaults] objectForKey:UsersHashKey];
    self.users = @[].mutableCopy;
    if (usersHash != nil) {
        for (NSString *userId in usersHash.allKeys) {
            User *user = [User new];
            user.userId = userId;
            user.name = usersHash[userId];
            [self.users addObject:user];
        }
    }
    
    if (self.users.count == 1) {
        [self addUser:@"Secondary"];
        [self saveUsers];
    }
}

- (void)removeUser:(NSString *)userName {
    //TODO !!
}

- (void)renameUserOldName:(NSString *)oldName newName:(NSString *)newName {
    //TODO !!
}

#define CurrentUserID @"CurrentUserID"

- (User *)getCurrentUser {
    if (_currentUser == nil) {
        NSString *currentUserId = [[NSUserDefaults standardUserDefaults] stringForKey:CurrentUserID];
        if (currentUserId != nil) {
            for (User *user in self.users) {
                if ([currentUserId isEqualToString:user.userId]) {
                    return user;
                }
            }
        }
        _currentUser = [[User alloc] init];
        _currentUser.userId = @"";//[AMRTools uniqueID];
        _currentUser.name = @"Master";
        _users = @[_currentUser].mutableCopy;
        [self addUser:@"Secondary"];
        [self saveUsers];
    }
    
    return _currentUser;
}

- (void)setCurrentUser:(User *)currentUser {
    _currentUser = currentUser;
    [[NSUserDefaults standardUserDefaults] setObject:_currentUser.userId forKey:CurrentUserID];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self load];
}

+(DataSource *)shared {
    static DataSource *dataSource;
    static dispatch_once_t once;
    
    dispatch_once(&once, ^
                  {
                      dataSource = [DataSource new];
                  });
    
    return dataSource;
}

- (NSMutableArray *)getUsers {
    if (_users == nil) {
        _users = @[[self getCurrentUser]].mutableCopy;
        [self saveUsers];
    }
    
    return _users;
}

@end
