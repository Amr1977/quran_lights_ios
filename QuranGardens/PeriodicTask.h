//
//  PeriodicTask.h
//  QuranGardens
//
//  Created by Amr Lotfy on 1/30/16.
//  Copyright © 2016 Amr Lotfy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Realm/Realm.h>


/** 
 A task that should occurre at least once within a preset time period, this time period is the maximum allowed time between two occurrences of a periodic task.
 
 */
@interface PeriodicTask : RLMObject

/** Task name */
@property (strong, nonatomic) NSString *name;

/** Task Description */
@property (strong, nonatomic) NSString *taskDescription;

/** Maximum time allowed between two task occurrences */
@property (nonatomic) NSTimeInterval cycleInterval;

/** Last time that task Occurred */
@property (strong, nonatomic) NSDate *lastOccurrence;

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

@end

RLM_ARRAY_TYPE(PeriodicTask)
