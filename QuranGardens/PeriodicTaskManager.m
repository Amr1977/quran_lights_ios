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
        _dataSource = [[DataSource alloc] init];
        [_dataSource load];
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
        NSUInteger firstSuraOrder = [[Sura suraNames] indexOfObject:((PeriodicTask *)a).name];
        NSUInteger secondSuraOrder = [[Sura suraNames] indexOfObject:((PeriodicTask *)b).name];
        
        double firstStrength = (((PeriodicTask *)a).remainingTimeInterval/((PeriodicTask *)a).cycleInterval);
        double secondStrength = (((PeriodicTask *)b).remainingTimeInterval/((PeriodicTask *)b).cycleInterval);
        NSComparisonResult result;
        if (firstStrength > secondStrength ) {
            result = NSOrderedDescending;
        } else if (firstStrength < secondStrength ) {
            result = NSOrderedAscending;
        } else if(firstSuraOrder > secondSuraOrder) {
            result = NSOrderedAscending;
        } else {
            result = NSOrderedDescending;
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
    NSDate *oldDay = [NSDate dateWithTimeIntervalSince1970:0];
    for (PeriodicTask * task in self.dataSource.tasks) {
        task.lastOccurrence = oldDay;
    }
    [self saveTasks];
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

@end
