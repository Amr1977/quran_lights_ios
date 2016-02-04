//
//  PeriodicTaskManager.m
//  QuranGardens
//
//  Created by Amr Lotfy on 1/30/16.
//  Copyright © 2016 Amr Lotfy. All rights reserved.
//

#import "PeriodicTaskManager.h"

@interface PeriodicTaskManager ()

@property (strong, nonatomic) NSMutableArray<PeriodicTask *> *tasks;

@end

@implementation PeriodicTaskManager

- (void)resetTasks{
    NSDate *oldDay = [NSDate dateWithTimeIntervalSince1970:0];
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    for (PeriodicTask * task in self.tasks) {
        task.lastOccurrence = oldDay;
    }
    [realm commitWriteTransaction];
}

- (void)addPeriodicTask:(PeriodicTask *)task{
    [self.tasks addObject:task];
}

- (BOOL)removeTaskByName:(nonnull NSString *)name{
    NSInteger indexToRemove = -1;
    for (NSInteger index = 0; index < [self.tasks count]; index++) {
        if ([self.tasks[index].name isEqualToString:name]) {
            indexToRemove = index;
            break;
        }
    }
    if (indexToRemove > -1) {
        [self.tasks removeObjectAtIndex:indexToRemove];
    }
    
    return (indexToRemove != -1);
}

- (NSArray *)tasks{
    if (!_tasks) {
        _tasks = @[].mutableCopy;
    }
    return _tasks;
}

- (void)loadTasks{
    RLMResults <PeriodicTask *> *results = [PeriodicTask allObjects];
    for (PeriodicTask * task in results) {
        [self.tasks addObject:task];
    }
}

- (void)saveTasks{
    RLMRealm * realm = [RLMRealm defaultRealm];
    [realm transactionWithBlock:^{
        for (PeriodicTask *task in self.tasks) {
            [realm addObject:task]; ;
        }
    }];
    
}

- (NSInteger)taskCount{
    return [self.tasks count];
}

- (PeriodicTask * _Nullable)getTaskAtIndex:(NSInteger)index{
    return [self.tasks objectAtIndex:index];
}

@end
