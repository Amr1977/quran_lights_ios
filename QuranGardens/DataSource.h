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

@interface DataSource : NSObject

@property (strong, nonatomic) NSMutableArray<PeriodicTask *> *tasks;
@property (strong, nonatomic) Settings *settings;

@property (strong, nonatomic) NSArray<NSNumber *> *suraCharsCount;
@property (strong, nonatomic) NSArray<NSNumber *> *suraWordCount;
@property (strong, nonatomic) NSArray<NSNumber *> *suraVerseCount;
@property (strong, nonatomic) NSArray<NSNumber *> *suraRevalOrder;

- (void)load;
- (void)save;
- (void)listTasksData;

- (void)loadFromFile:(NSString *)fileName completionBlock:(void(^)(BOOL success))completionBlock;
- (void)saveToFile:(NSString *)fileName completion:(void (^)(BOOL success))completionBlock;

- (void)saveSettings;

- (NSTimeInterval)loadSuraCyclePeriod:(NSString *)suraName;
- (void)saveSuraCyclePeriod:(NSTimeInterval)period suraName:(NSString *)suraName;

- (NSDate *)loadSuraLastRefresh:(NSString *)suraName;
- (void)saveSuraLastRefresh:(NSDate *)lastRefreshDate suraName:(NSString *)suraName;

@end
