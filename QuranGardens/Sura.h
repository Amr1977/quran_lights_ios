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

/** Calculates remaining hours */
- (NSInteger)remainingTimeForNextReview;
+ (NSArray<NSString *> *)suraNames;

@end
