//
//  PeriodicTask.m
//  QuranGardens
//
//  Created by Amr Lotfy on 1/30/16.
//  Copyright © 2016 Amr Lotfy. All rights reserved.
//

#import "PeriodicTask.h"

static NSString * const PeriodicTaskNameKey = @"name";
static NSString * const PeriodicTaskLastOccurrenceKey = @"lastOccurrence";
static NSString * const PeriodicTaskCycleIntervalKey = @"cycleInterval";

@implementation PeriodicTask

#pragma mark - NSCoding

//- (id)initWithCoder:(NSCoder *)decoder {
//    self = [super init];
//    if (!self) {
//        return nil;
//    }
//    
//    self.name = [decoder decodeObjectForKey:@"name"];
//    self.taskDescription = [decoder decodeObjectForKey:@"taskDescription"];
//    self.lastOccurrence = [decoder decodeObjectForKey:@"lastOccurrence"];
//    self.cycleInterval = [[decoder decodeObjectForKey:@"cycleInterval"] doubleValue];
//    
//    return self;
//}
//
//- (void)encodeWithCoder:(NSCoder *)encoder {
//    [encoder encodeObject:self.name forKey:@"name"];
//    [encoder encodeObject:self.taskDescription forKey:@"taskDescription"];
//    [encoder encodeObject:self.lastOccurrence forKey:@"lastOccurrence"];
//    [encoder encodeObject:[NSNumber numberWithDouble:self.cycleInterval] forKey:@"cycleInterval"];
//}

- (instancetype)initWithPList:(NSDictionary *)plist{
    if (!plist){
        return nil;
    }
    self = [super init];
    if (self) {
        _name = (NSString *)[plist objectForKey:PeriodicTaskNameKey];
        _taskDescription = nil;
        _cycleInterval = [(NSNumber *)[plist objectForKey:PeriodicTaskCycleIntervalKey] doubleValue];
        _lastOccurrence = (NSDate *)[plist objectForKey:PeriodicTaskLastOccurrenceKey];
    }
    
    return self;
}

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
    //TODO: do it!
}

- (NSDictionary *)toPList{
    NSMutableDictionary *plist = @{}.mutableCopy;
    
    [plist setValue:self.name forKey:@"name"];
    [plist setValue:self.lastOccurrence forKey:@"lastOccurrence"];
    [plist setValue:[NSNumber numberWithDouble:self.cycleInterval] forKey:@"cycleInterval"];
    
    return [plist copy];
}

- (void)fromPList:(NSDictionary *)plist{
    if (!plist) { return; }
    
    _name = (NSString *)[plist objectForKey:PeriodicTaskNameKey];
    _taskDescription = nil;
    _cycleInterval = [(NSNumber *)[plist objectForKey:PeriodicTaskCycleIntervalKey] doubleValue];
    _lastOccurrence = (NSDate *)[plist objectForKey:PeriodicTaskLastOccurrenceKey];
}

@end
