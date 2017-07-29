//
//  PeriodicTaskManager.m
//  QuranGardens
//
//  Created by Amr Lotfy on 1/30/16.
//  Copyright © 2016 Amr Lotfy. All rights reserved.
//

#import "PeriodicTaskManager.h"
#import "Sura.h"

@interface PeriodicTaskManager ()

@end

@implementation PeriodicTaskManager

- (instancetype)init{
    self = [super init];
    if (self) {
        _dataSource = [DataSource shared];
        [_dataSource load:nil];
    }
    return self;
}

- (void)soraListNormalOrder{
    
}

- (void)sortListReverseOrder{
    NSMutableArray <PeriodicTask *> *reversedTasks = [[[self.dataSource.tasks reverseObjectEnumerator] allObjects] mutableCopy];
    self.dataSource.tasks = reversedTasks;
}

- (void)sortListWeakerFirst{
    NSMutableArray *sortedArray;
    sortedArray = [self.dataSource.tasks sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        double firstStrength = [[((PeriodicTask *)a).history lastObject] timeIntervalSince1970];
        double secondStrength = [[((PeriodicTask *)b).history lastObject] timeIntervalSince1970];
        NSComparisonResult result;
        if (firstStrength > secondStrength ) {
            result = NSOrderedDescending;
        } else if (firstStrength < secondStrength ) {
            result = NSOrderedAscending;
        } else {
            result = NSOrderedSame;
        }
        
        return result;
    }].mutableCopy;
    
    self.dataSource.tasks = sortedArray;
}

- (void)sortListStrongestFirst{
    [self sortListWeakerFirst];
    [self sortListReverseOrder];
}

- (void)sortWithBlock:(NSComparisonResult(^) (id object1, id object2))sortBlock{
    NSMutableArray *sortedArray;
    sortedArray = [self.dataSource.tasks sortedArrayUsingComparator:sortBlock].mutableCopy;
    
    self.dataSource.tasks = sortedArray;
}

- (void)resetTasks{
//    NSDate *oldDay = [NSDate dateWithTimeIntervalSince1970:0];
//    for (PeriodicTask * task in self.dataSource.tasks) {
//        task.lastOccurrence = oldDay;
//    }
//    [self saveTasks];
}

- (NSInteger)taskCount{
    return [self.dataSource.tasks count];
}

- (PeriodicTask * _Nullable)getTaskAtIndex:(NSInteger)index{
    return [self.dataSource.tasks objectAtIndex:index];
}

- (void)saveTasks{
    [self.dataSource save];
}

- (NSInteger)getCurrentKhatmaNumber {
    NSInteger minReadCount = self.dataSource.tasks[0].history.count;
    
    for (PeriodicTask *task in self.dataSource.tasks) {
        if (task.history.count < minReadCount) {
            minReadCount = task.history.count;
        }
    }
    
    return minReadCount + 1;
}

- (Boolean)isCoveredInCurrentKhatma:(NSString *)suraName {
    
    NSInteger currentKhatma = [self getCurrentKhatmaNumber];
    
    NSInteger index = [[Sura suraNames] indexOfObject:suraName];
    
    if (index == NSNotFound || index >= self.dataSource.tasks.count) {
        return NO;
    }
    
    PeriodicTask *task = self.dataSource.tasks[index];
    
    Boolean result = task.history.count >= currentKhatma;
    
    return result;
}


@end
