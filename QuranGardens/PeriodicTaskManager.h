//
//  PeriodicTaskManager.h
//  QuranGardens
//
//  Created by Amr Lotfy on 1/30/16.
//  Copyright © 2016 Amr Lotfy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PeriodicTask.h"

@interface PeriodicTaskManager : NSObject

@property (strong, nonatomic) NSMutableArray<PeriodicTask *> *tasks;

- (void)addPeriodicTask:(nonnull PeriodicTask *)task;
- (BOOL)removeTaskByName:(nonnull NSString *)name;
- (PeriodicTask * _Nullable)getTaskAtIndex:(NSInteger)index;

- (void)loadTasks;
- (void)saveTasks;
- (void)resetTasks;
- (NSInteger)taskCount;

- (void)sortListReverseOrder;
- (void)sortListWeakerFirst;
- (void)sortListStrongestFirst;
- (void)sortWithBlock:(NSComparisonResult(^) (id object1, id object2))sortBlock;

@end
