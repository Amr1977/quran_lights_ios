//
//  SyncManager.h
//  QuranGardens
//
//  Created by   Amr Lotfy on 10/10/17.
//  Copyright © 2017 Amr Lotfy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SyncManager : NSObject

- (void)syncHistory;
- (void)refreshSura:(NSString *)suraName updateFBTimeStamp:(BOOL)updateFBTimeStamp;
- (void)refreshSura:(NSString *)suraName withDate:(NSNumber *)date updateFBTimeStamp:(BOOL)updateFBTimeStamp;
- (void)refreshSura:(NSString *)suraName withHistory:(NSArray *)history updateFBTimeStamp:(BOOL)updateFBTimeStamp;
- (void)refreshSura:(NSString *)suraName withMemorization:(NSInteger)memorization updateFBTimeStamp:(BOOL)updateFBTimeStamp;

- (void)updateTimeStamp:(BOOL)updateFBTimeStamp;
-(void)registerTimeStampTrigger;

+ (SyncManager *)shared;

@end
