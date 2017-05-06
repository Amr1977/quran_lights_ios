//
//  PeriodicTaskManager.h
//  QuranGardens
//
//  Created by Amr Lotfy on 1/30/16.
//  Copyright © 2016 Amr Lotfy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PeriodicTask.h"
#import "DataSource.h"

@interface PeriodicTaskManager : NSObject

@property (strong, nonatomic, nonnull) DataSource *dataSource;

- (PeriodicTask * _Nullable)getTaskAtIndex:(NSInteger)index;
- (void)resetTasks;
- (NSInteger)taskCount;
- (void)sortListReverseOrder;
- (void)sortListWeakerFirst;
- (void)sortListStrongestFirst;
- (void)sortWithBlock:(NSComparisonResult(^ _Nullable) (id _Nullable object1, id _Nullable object2))sortBlock;
- (void)saveTasks;

- (NSInteger)getCurrentKhatmaNumber;
- (Boolean)isCoveredInCurrentKhatma:(NSString *_Nonnull)suraName;

@end
