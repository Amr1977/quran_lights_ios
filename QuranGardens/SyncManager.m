//
//  SyncManager.m
//  QuranGardens
//
//  Created by   Amr Lotfy on 10/10/17.
//  Copyright © 2017 Amr Lotfy. All rights reserved.
//

#import "SyncManager.h"
#import "FireBaseManager.h"
#import "DataSource.h"
#import "AMRTools.h"
#import "MembersManager.h"
#import "Sura.h"

@import Firebase;
@import FirebaseDatabase;

@interface SyncManager ()

@property (strong, nonatomic) NSMutableArray<NSNumber *> *localTimeStampsHistory;
@property (strong, nonatomic)__block FIRDatabaseReference *updateTimeStampRef;
@property (strong, nonatomic)__block dispatch_block_t stabilizedSyncBlock;
@property (nonatomic) __block BOOL shouldFullyUploadReviewsHistory;

@end

@implementation SyncManager

BOOL uploadInProgress;

+ (SyncManager *)shared {
    static SyncManager *sharedInstance;
    
    if(sharedInstance == nil) {
        sharedInstance = [[SyncManager alloc] init];
        NSLog(@"syncManager Initialized");
    }
    
    return sharedInstance;
}

//TODO sync all members, not just current member !!!
- (void)syncHistory {
    NSLog(@"syncHistory started");
    if (![[FireBaseManager shared] isConnected] || ![FireBaseManager shared].userID) {
        //should it return or try sign in if connected ???
        return;
    }
    
    [self syncMembers:^{
        NSLog(@"Members synced.");
        [[NSNotificationCenter defaultCenter] postNotificationName:@"WillStartUpdatedFromFireBase"
                                                            object:self];
        [self downloadReviewsHistory: ^{
            [self uploadHistory:^(BOOL success, BOOL dirty){
                if (success) {
                    NSLog(@"🌻 Success uploading history. 🌻");
                    [self updateTimeStamp:dirty];
                } else {
                    NSLog(@">>>>>>>>>>>> 💥 💥 💥  Error uploading history. <<<<<<<<<<<<<<<<<");
                }
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdatedFromFireBase"
                                                                    object:self];
                NSLog(@"syncHistory Completed.");
            }];
        }];
    }];
}

-(void)registerTimeStampTrigger{
    NSLog(@"registerTimeStampTrigger started");
    if (!([FireBaseManager shared].isConnected) || [FireBaseManager shared].userID == nil  ) {
        return;
    }
    
    /**
     * first sync is made on app launch and does not need to be delayed
     */
    static BOOL isFirstSync = YES;
    
    self.updateTimeStampRef = [[[[[FireBaseManager shared].firebaseDatabaseReference
                                  child:@"users"]
                                 child: [FireBaseManager shared].userID]
                                child:[[[DataSource shared] getCurrentUser] nonEmptyId]]
                               child:@"update_stamp"];
    [self.updateTimeStampRef observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        
        if(snapshot.value == [NSNull null]) {
            //Handle fresh firebase database
            NSLog(@"self.shouldFullyUploadReviewsHistory = YES;");
            self.shouldFullyUploadReviewsHistory = YES;
        } else {
            NSNumber *timestamp = snapshot.value;
            NSLog(@"TimeStamp Trigger: %ld", (long)[timestamp integerValue]);
            
            //drop if matching user update timestamp
            
            if([timestamp integerValue] == [[self currentLocalTimeStamp] integerValue]) {
                NSLog(@"Dropped timestamp trigger: matched current local timestamp.");
                return;
            }
            
            //Drop if local echo
            
            for (NSNumber *number in self.localTimeStampsHistory) {
                if ([number integerValue] == [timestamp integerValue]) {
                    NSLog(@"Dropped local timestamp trigger echo");
                    return;
                }
            }
        }
        
        //stabilized sync
        if (self.stabilizedSyncBlock != nil) {
            dispatch_block_cancel(self.stabilizedSyncBlock);
            NSLog(@">>>>>>>>>>>>>>>>> Dropping repeated timestamp update trigger");
        }
        
        self.stabilizedSyncBlock = dispatch_block_create(0, ^{
            NSLog(@">>>>>>>>>>>>>>>>> Executing syncHistory block");
            [self syncHistory];
        });
        
        //execute stabilized sync after a while
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((isFirstSync ? 0 : 5) * NSEC_PER_SEC)), dispatch_get_main_queue(), self.stabilizedSyncBlock);
        isFirstSync = YES;
    }];
}

- (void)syncMembers:(void(^)(void))completion{
    //members node children
    [[[FireBaseManager shared]
      membersRef]
observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        
        if (snapshot.value != [NSNull null]) {
            NSDictionary<NSString *, NSString *> *members = snapshot.value;
            
            for (NSString *key in [members allKeys]) {
                [[DataSource shared] addUser:members[key] userId:key];
            }
        }
        
        NSMutableArray<User *> *localMembers = [[DataSource shared] getUsers];
        for (User *member in localMembers) {
            if ([member.name isEqualToString:@"Master"]) {
                continue;
            }
            [[MembersManager shared] addMemberWithId:[member userId] name:[member name]];
        }
        
        if(completion != nil) {
            completion();
        }
    }];
}

- (void)refreshSura:(NSString *)suraName withDate:(NSNumber *)date updateFBTimeStamp:(BOOL)updateFBTimeStamp{
    NSDictionary *refreshRecord = @{@"op": @"refresh", @"time": date, @"sura": [Sura suraIndexFromSuraName:suraName]};
    
    [self enqueueInUploadQueue:refreshRecord];
    
    if (!uploadInProgress) {
        [self uploadHistory:^(BOOL success, BOOL alteredHistory){
            if (success) {
                [self setLastTransactionTimeStamp:[self timestamp]];
            }
            if (alteredHistory) {
                [self updateTimeStamp:updateFBTimeStamp];
            }
        }];
    }
}

- (void)refreshSura:(NSString *)suraName updateFBTimeStamp:(BOOL)updateFBTimeStamp{
    
    NSNumber *date =  [NSNumber numberWithDouble:[[NSDate new] timeIntervalSince1970]];
    
    NSDictionary *refreshRecord = @{@"op": @"refresh", @"time": date, @"sura": [Sura suraIndexFromSuraName:suraName]};
    [self enqueueInUploadQueue:refreshRecord];
    
    if (!uploadInProgress) {
        [self uploadHistory:^(BOOL success, BOOL alteredHistory){
            if (success) {
                [self setLastTransactionTimeStamp:[self timestamp]];
            }
            if (alteredHistory) {
                [self updateTimeStamp:updateFBTimeStamp];
            }
        }];
    }
    
}

- (void)refreshSura:(NSString *)suraName withMemorization:(NSInteger)memorization updateFBTimeStamp:(BOOL)updateFBTimeStamp{
    NSString *memString = [NSString stringWithFormat:@"%ld", memorization];
    NSDictionary *refreshRecord = @{@"op": @"memorize" , @"state": memString , @"sura": [Sura suraIndexFromSuraName:suraName]};
    
    [self enqueueInUploadQueue:refreshRecord];
    
    if (!uploadInProgress) {
        [self uploadHistory:^(BOOL success, BOOL alteredHistory){
            if (success) {
                [self setLastTransactionTimeStamp:[self timestamp]];
            }
            if (alteredHistory) {
                [self updateTimeStamp:updateFBTimeStamp];
            }
        }];
    }
}

- (void)refreshSura:(NSString *)suraName withHistory:(NSArray *)history updateFBTimeStamp:(BOOL)updateFBTimeStamp{
    
    if (![FireBaseManager shared].isConnected || ![FireBaseManager shared].userID) {
        return;
    }
    
    for (NSDate *date in history) {
        NSNumber *dateNumber =  [NSNumber numberWithLongLong:[date timeIntervalSince1970]];
        NSDictionary *refreshRecord = @{@"op": @"refresh", @"time": dateNumber, @"sura": [Sura suraIndexFromSuraName:suraName]};
        [self enqueueInUploadQueue:refreshRecord];
    }
    
    if (!uploadInProgress) {
        [self uploadHistory:^(BOOL success, BOOL alteredHistory){
            if (success) {
                [self setLastTransactionTimeStamp:[self timestamp]];
            }
            if (alteredHistory) {
                [self updateTimeStamp:updateFBTimeStamp];
            }
        }];
    }
}

- (NSDictionary *)getUploadQueueHead {
    NSArray *queue = [self getUploadQueue];
    
    if (queue.count == 0) {
        return nil;
    }
    
    return queue[0];
}

- (void)enqueueInUploadQueue:(NSDictionary *)refreshRecord {
    NSLog(@"Enqueue in upload queue: %@", refreshRecord);
    NSMutableArray *uploadQueue = [self getUploadQueue].mutableCopy;
    NSNumber *time = refreshRecord[@"time"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @"time", time];
    NSArray *filteredArray = [uploadQueue filteredArrayUsingPredicate:predicate];
    if(filteredArray != nil && filteredArray.count > 0) {
        NSLog(@"Duplicate insertion in upload queue detected");
        return;
    }
    
    [uploadQueue addObject:refreshRecord];
    [self setUploadQueue:uploadQueue];
}

- (NSDictionary *)dequeueFromUploadQueue {
    NSMutableArray *uploadQueue = [self getUploadQueue].mutableCopy;
    if(uploadQueue.count == 0){
        return nil;
    }
    
    NSDictionary *popedRefreshRecord = uploadQueue[0];
    [uploadQueue removeObjectAtIndex:0];
    [self setUploadQueue:uploadQueue];
    
    return popedRefreshRecord;
}

- (NSArray *)getUploadQueue{
    NSArray *uploadQueue = [[NSUserDefaults standardUserDefaults] objectForKey:[self uploadQueueKey]];
    if (uploadQueue == nil) {
        uploadQueue = @[];
        
        [self setUploadQueue:uploadQueue];
    }
    
    NSLog(@"uploadQueue %@", uploadQueue);
    
    return uploadQueue;
}

- (void)setUploadQueue:(NSArray *)uploadQueue{
    [[NSUserDefaults standardUserDefaults] setObject:uploadQueue forKey:[self uploadQueueKey]];
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSLog(@"uploadQueue %@", uploadQueue);
}

-(NSString *)uploadQueueKey {
    return [[DataSource shared] userKey:@"uploadQueue"];
}


- (NSString *)timestamp {
    NSNumber *date =  [NSNumber numberWithLongLong: ([[NSDate new] timeIntervalSince1970] * 1000.0 + [FireBaseManager shared].serverOffset) * 1000.0];
    NSString *dateString = [date stringValue];
    
    NSLog(@"generated timestamp: %@", dateString);
    
    return dateString;
}

- (NSNumber *)currentLocalTimeStamp {
    NSString *userTimeStamp = [[DataSource shared] userKey:@"UpdateTimeStamp"];
    return (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:userTimeStamp];
}

- (void)updateLocalTimeStamp {
    NSNumber *date = [NSNumber numberWithDouble: [[NSDate new] timeIntervalSince1970]];
    NSString *userTimeStamp = [[DataSource shared] userKey:@"UpdateTimeStamp"];
    
    [[NSUserDefaults standardUserDefaults] setObject:date
                                              forKey:userTimeStamp];
}

- (void)updateTimeStamp:(BOOL)updateFBTimeStamp {
    
    NSNumber *date = [NSNumber numberWithDouble: [[NSDate new] timeIntervalSince1970]];
    [self.localTimeStampsHistory addObject:date];
    NSString *userTimeStamp = [[DataSource shared] userKey:@"UpdateTimeStamp"];
    
    [[NSUserDefaults standardUserDefaults] setObject:date
                                              forKey:userTimeStamp];
    
    if (![FireBaseManager shared].isConnected || ![FireBaseManager shared].userID || !updateFBTimeStamp ) {
        return;
    }
    
    [[[[[[FireBaseManager shared].firebaseDatabaseReference
         child:@"users"]
        child: [FireBaseManager shared].userID]
       child:[[[DataSource shared] getCurrentUser] nonEmptyId]]
      child:@"update_stamp"] setValue:date];
}

- (void)remoteTimeStamp:(void(^)(NSNumber *timestamp))completion {
    if (![FireBaseManager shared].isConnected || ![FireBaseManager shared].userID) {
        completion(nil);
        return;
    }
    [[[[[[FireBaseManager shared].firebaseDatabaseReference
         child:@"users"]
        child: [FireBaseManager shared].userID]
       child:[[[DataSource shared] getCurrentUser] nonEmptyId]]
      child:@"update_stamp"] observeSingleEventOfType: FIRDataEventTypeValue
     withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
         NSLog(@"timestamp snapshot %@", snapshot);
         if (completion == nil) return;
         if (snapshot.value != [NSNull null]) {
             NSNumber *timestamp = (NSNumber *)[snapshot value];
             completion(timestamp);
         } else {
             completion(nil);
         }
     }];
}

- (void)onTimeStampAltered:(void(^)(void))completion{
    __block NSNumber *localTimeStamp = [self currentLocalTimeStamp];
    [self remoteTimeStamp:^(NSNumber *timestamp) {
        NSLog(@"onTimeStampAltered: timestamp %@", timestamp);
        if ((timestamp == nil || [timestamp integerValue] != [localTimeStamp integerValue]) && completion != nil ) {
            completion();
        }
    }];
}

- (NSString *)getLastTransactionTimeStamp {
    NSString *result = [[NSUserDefaults standardUserDefaults] stringForKey:@"MostRecentFBReviewsTimeStamp"];
    if (result == nil){
        result = @"0";
        [self setLastTransactionTimeStamp:@"0"];
    }
    
    NSLog(@"getLastTransactionTimeStamp: %@", result);
    return result;
}

- (void)setLastTransactionTimeStamp: (NSString *)timestamp {
    [[NSUserDefaults standardUserDefaults] setObject:timestamp forKey:@"MostRecentFBReviewsTimeStamp"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSLog(@"setLastTransactionTimeStamp: %@", timestamp);
}

- (void)downloadReviewsHistory:(void(^)(void))completion {
    if (![FireBaseManager shared].isConnected || ![FireBaseManager shared].userID) {
        if (completion != nil) {
            completion();
        }
        return;
    }
    
    NSString *recentTimeStamp = [self getLastTransactionTimeStamp];
    
    [[[[[FireBaseManager shared] reviewsRef] queryOrderedByKey] queryStartingAtValue:recentTimeStamp] observeSingleEventOfType:(FIRDataEventTypeValue) withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSLog(@"reviewsRef observeSingleEventOfType:FIRDataEventTypeValue");
            NSDictionary<NSString *, NSDictionary *> *reviews = snapshot.value;
            if (snapshot.value == [NSNull null]) {
                if (completion != nil) {
                    completion();
                }
                return;
            }
            
            long long maxTimeStamp = [recentTimeStamp longLongValue];
            NSLog(@"history dump: %@", snapshot.value);
            NSMutableArray *keys = reviews.allKeys.mutableCopy;
            [keys removeObject:recentTimeStamp];
            NSMutableDictionary *surasHistory = @{}.mutableCopy;
            
            for (NSString *key in keys)  {
                if ([key longLongValue] > maxTimeStamp) {
                    maxTimeStamp = [key longLongValue];
                }
                //TODO parse transaction record and apply operation
                NSDictionary *transaction = reviews[key];
                NSString *operation = transaction[@"op"];
                //set default operation
                if (operation == nil) {
                    operation = @"refresh";
                }
                if ([operation isEqualToString:@"refresh"]) {
                    NSString *timeStamp = transaction[@"time"];
                    NSString *suraIndex = transaction[@"sura"];
                    NSTimeInterval interval = [timeStamp doubleValue];
                    NSDate *date = [NSDate dateWithTimeIntervalSince1970:interval];
                    NSInteger index = [suraIndex integerValue];
                    if (index == 0) { continue; }
                    NSString *suraName = [Sura suraNames][index - 1];
                    if(surasHistory[suraName] == nil){
                        surasHistory[suraName] = @[].mutableCopy;
                    }
                    [surasHistory[suraName] addObject:date];
                }
                
                if ([operation isEqualToString:@"memorize"]) {
                    NSString *suraIndex = transaction[@"sura"];
                    NSInteger index = [suraIndex integerValue];
                    if (index == 0) {
                        continue;
                    }
                    NSString *suraName = [Sura suraNames][index - 1];
                    NSString *memState = transaction[@"state"];
                    NSInteger state = [memState integerValue];
                    [[DataSource shared] setMemorizedStateForSura:suraName state:state upload:NO];
                }
            }
            //insert new refresh transactions a sura at once
            for (NSString *suraName in surasHistory.allKeys) {
                [[DataSource shared] appendRefreshHistory:surasHistory[suraName] suraName:suraName upload:NO];
            }
            //TODO rename reviews to transactions
            NSLog(@"maxTimeStamp: %@", [NSString stringWithFormat:@"%lld", (long long)maxTimeStamp]);
            [self setLastTransactionTimeStamp:[NSString stringWithFormat:@"%lld", (long long)maxTimeStamp]];
            
            
            if (completion != nil) {
                completion();
            }
        });
    }];
}

- (NSDictionary *)reviewsDic {
    
    NSMutableDictionary *reviews = @{}.mutableCopy;
    //put all reviews transactions in upload queue
    for (PeriodicTask *task in [DataSource shared].tasks) {
        
        
        NSString *stateString = [NSString stringWithFormat:@"%ld", task.memorizedState];
        NSDictionary *memRecord = @{@"op": @"memorize",
                                    @"state": stateString,
                                    @"sura": [Sura suraIndexFromSuraName:task.name]};
        
        reviews[[self timestamp]] = memRecord;
        NSLog(@"reviews upload added: %@", memRecord);
        
        for (NSDate *date in task.history) {
            NSNumber *dateNumber =  [NSNumber numberWithLongLong:[date timeIntervalSince1970]];
            NSDictionary *refreshRecord = @{@"op": @"refresh", @"time": dateNumber, @"sura": [Sura suraIndexFromSuraName:task.name]};
            reviews[[self timestamp]] = refreshRecord;
            NSLog(@"reviews upload added: %@", refreshRecord);
        }
    }
    
    return reviews;
}

- (void)uploadHistory:(void(^)(BOOL success, BOOL alteredHistory))completion{
    if (!([FireBaseManager shared].isConnected) || [FireBaseManager shared].userID == nil  ) {
        return;
    }
    uploadInProgress = YES;
    static BOOL dirty = NO;
    static BOOL networkError = NO;
    
    if (self.shouldFullyUploadReviewsHistory) {
        self.shouldFullyUploadReviewsHistory = NO;
        NSDictionary *reviews = [self reviewsDic];
        [[[[[[FireBaseManager shared].firebaseDatabaseReference
             child:@"users"]
            child: [FireBaseManager shared].userID]
           child:[[[DataSource shared] getCurrentUser] nonEmptyId]]
          child:@"reviews"] setValue:reviews withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
            if (error == nil) {
                [self setLastTransactionTimeStamp:[self timestamp]];
                completion(YES, YES);
            } else {
                completion(NO, NO);
            }
            uploadInProgress = NO;
        }];
        return;
    }
    
    if ([self getUploadQueue].count == 0 || networkError) {
        uploadInProgress = NO;
        if (completion != nil) {
            completion(!networkError, dirty);
        }
        dirty = NO;
        networkError = NO;
        return;
    }
    
    NSString *timestamp = [self timestamp];
    
    
    //TODO consider updating multiple nodes at once using [ref updateChildValues:]
    [[[[[[[FireBaseManager shared].firebaseDatabaseReference
          child:@"users"]
         child: [FireBaseManager shared].userID]
        child:[[[DataSource shared] getCurrentUser] nonEmptyId]]
       child:@"reviews"]
      child: timestamp]
     setValue: [self getUploadQueueHead] withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
         if (error == nil) {
             dirty = YES;
             [self dequeueFromUploadQueue];
             [self setLastTransactionTimeStamp:timestamp];
             //TODO: replace recursion with loop
         } else {
             NSLog(@"History upload error %@", error.localizedDescription);
             //terminate gracefully
             networkError = YES;
         }
         [self uploadHistory:completion];
     }];
}


@end
