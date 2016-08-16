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

extern NSInteger const DefaultCycleInterval;
extern NSTimeInterval const DemoTimeInterval;

/** Sura order in mushaf. */
@property (nonatomic) NSInteger order;

+ (NSArray<NSString *> *)suraNames;

@end
