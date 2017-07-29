//
//  DataSource.h
//  QuranGardens
//
//  Created by Amr Lotfy on 8/16/16.
//  Copyright © 2016 Amr Lotfy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PeriodicTask.h"
#import "Settings.h"
#import "User.h"

@interface DataSource : NSObject

@property (strong, nonatomic) NSMutableArray<PeriodicTask *> *tasks;
@property (strong, nonatomic) Settings *settings;
@property (strong, nonatomic) NSMutableArray<User *> *users;

@property (strong, nonatomic) NSArray<NSNumber *> *suraCharsCount;
@property (strong, nonatomic) NSArray<NSNumber *> *suraWordCount;
@property (strong, nonatomic) NSArray<NSNumber *> *suraVerseCount;
@property (strong, nonatomic) NSArray<NSNumber *> *suraRevalOrder;

- (void)load:(void(^)(void))completion;
- (void)save;
- (void)listTasksData;

- (void)loadFromFile:(NSString *)fileName completionBlock:(void(^)(BOOL success))completionBlock;
- (void)saveToFile:(NSString *)fileName completion:(void (^)(BOOL success))completionBlock;

- (NSMutableArray<NSDate *>*)loadRefreshHistoryForSuraName:(NSString *)suraName;
- (void)setHistory:(NSString *)suraName history:(NSArray<NSDate *> *)history;

- (NSInteger)loadMemorizedStateForSura:(NSString *)suraName;
- (void)saveMemorizedStateForSura:(NSString *)suraName;
- (void)saveMemorizedStateForTask:(PeriodicTask *)task;
- (void)setMemorizedStateForSura:(NSString *)suraName state:(NSInteger)state upload:(Boolean)upload;
- (void)setMemorizedStateForSura:(NSString *)suraName state:(NSInteger)state;

- (void)saveSuraMemorizationDate:(NSDate *)date suraName:(NSString *)suraName;
- (NSDate *)getSuraMemorizationDate:(NSString *)suraName;

- (void)saveSettings;

- (NSTimeInterval)loadSuraCyclePeriod:(NSString *)suraName;
- (void)saveSuraCyclePeriod:(NSTimeInterval)period suraName:(NSString *)suraName;

- (NSDate *)loadSuraLastRefresh:(NSString *)suraName;
- (void)saveSuraLastRefresh:(NSDate *)lastRefreshDate suraName:(NSString *)suraName upload:(Boolean)upload;
- (void)saveSuraLastRefresh:(NSDate *)lastRefreshDate suraName:(NSString *)suraName;

@property (strong, nonatomic) User *currentUser;

- (void)addUser:(NSString *)userName;
- (void)removeUser:(NSString *)userName;
- (void)renameUserOldName:(NSString *)oldName newName:(NSString *)newName;

- (void)setCurrentUser:(User *)currentUser;
- (User *)getCurrentUser;
- (NSMutableArray *)getUsers;
- (NSString *)userKey:(NSString *)key;

+(DataSource *)shared;
@end
