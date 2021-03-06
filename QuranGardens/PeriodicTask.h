//
//  PeriodicTask.h
//  QuranGardens
//
//  Created by Amr Lotfy on 1/30/16.
//  Copyright © 2016 Amr Lotfy. All rights reserved.
//

#import <Foundation/Foundation.h>

#define Demo NO
#define MEMORIZED 2
#define BEING_MEMORIZED 3
#define WAS_MEMORIZED 1
#define NOT_MEMORIZED 0


/** 
 A task that should occurre at least once within a preset time period, this time period is the maximum allowed time between two occurrences of a periodic task.
 
 */

//TODO: move sura dependant properties to sura class and resolev conflicts between the two classes
@interface PeriodicTask : NSObject

/** Task name */
@property (strong, nonatomic) NSString *name;

/** Task Description */
@property (strong, nonatomic) NSString *taskDescription;

/** Maximum time allowed between two task occurrences */
@property (nonatomic) NSTimeInterval cycleInterval;

/** Last time that task Occurred */
//@property (strong, nonatomic) NSDate *lastOccurrence;

@property(strong, nonatomic) NSMutableArray<NSDate *> *history;

/** Average time elapsed between refreshes of this task/sura */
@property (nonatomic) NSTimeInterval averageRefreshInterval;

//@property (nonatomic) BOOL memorized;
//@property (nonatomic) BOOL wasMemorized;
//@property (nonatomic) BOOL beingMemorized;

// 0: not memorized, 1: was memorized, 2: is memorized 3: being memorized
@property (nonatomic) NSInteger memorizedState;

@property (nonatomic) NSDate *memorizeDate;

/** Calculates time interval remaining to reach maximum allowed time period between two task occurrences*/
- (NSTimeInterval)remainingTimeInterval;


- (instancetype)initWithName:(NSString *)name
                 description:(NSString *)description
               cycleInterval:(NSTimeInterval)interval
              lastOccurrence:(NSDate *)lastOccurrence;

- (instancetype)createPeridicTaskWithName:(NSString *)name
                              description:(NSString *)description
                            cycleInterval:(NSTimeInterval)interval
                           lastOccurrence:(NSDate *)lastOccurrence;

- (instancetype)initWithPList:(NSDictionary *)plist;

- (NSDictionary *)toPList;
- (void)fromPList:(NSDictionary *)plist;

- (NSTimeInterval)calculateAverageRefresh;

- (NSInteger)index;
@end
