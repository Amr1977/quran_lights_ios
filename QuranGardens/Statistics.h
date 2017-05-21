//
//  Statistics.h
//  QuranGardens
//
//  Created by Amr Lotfy on 10/20/16.
//  Copyright © 2016 Amr Lotfy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DataSource.h"

@interface Statistics : NSObject

@property(weak, nonatomic) DataSource* dataSource;

- (instancetype)initWithDataSource:(DataSource *)dataSource;

- (NSDictionary<NSString *, NSNumber *> *)getMemorizationStates;
- (NSDictionary<NSString *, NSNumber *> *)getKhatmaProgress:(NSInteger)khatmaIndex;
- (NSDictionary<NSString *, NSNumber *> *)getTodayReviewReadScores;
- (NSDictionary<NSDate *, NSNumber *> *)getMonthlySumScores;
- (NSInteger)todayScore;
- (NSInteger)yesterdayScore;
- (NSInteger)totalScore;
+ (NSInteger)suraScore:(NSString *)suraName;
- (NSDictionary<NSDate *, NSNumber *> *)scores;
- (NSInteger)memorizedScore;
+ (NSInteger)allSurasScore;

@end
