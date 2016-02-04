//
//  PeriodicTask.m
//  QuranGardens
//
//  Created by Amr Lotfy on 1/30/16.
//  Copyright © 2016 Amr Lotfy. All rights reserved.
//

#import "PeriodicTask.h"

@implementation PeriodicTask

- (instancetype)initWithName:(NSString *)name
                 description:(NSString *)description
               cycleInterval:(NSTimeInterval)interval
              lastOccurrence:(NSDate *)lastOccurrence{
    
    self = [super init];
    if (self) {
        _name = name;
        _taskDescription = description;
        _cycleInterval = interval;
        _lastOccurrence = lastOccurrence;
    }
    
    return self;
}

- (NSTimeInterval)remainingTimeInterval{
    NSTimeInterval result = 0;
    NSTimeInterval ellapsedInterval = [[[NSDate alloc] init] timeIntervalSinceDate:self.lastOccurrence];
    result = self.cycleInterval - ellapsedInterval;
    return result;
}

- (instancetype)createPeridicTaskWithName:(NSString *)name
                              description:(NSString *)description
                            cycleInterval:(NSTimeInterval)interval
                           lastOccurrence:(NSDate *)lastOccurrence{
    
    PeriodicTask *newTask = [[PeriodicTask alloc] initWithName:name
                                                   description:description
                                                 cycleInterval:interval
                                                lastOccurrence:lastOccurrence];
    
    return newTask;
}

- (void)save{
    RLMRealm * realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    [realm addObject:self];
    [realm commitWriteTransaction];
}

@end
