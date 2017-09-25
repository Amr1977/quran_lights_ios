////
//  AppDelegate.m
//  QuranGardens
//
//  Created by Amr Lotfy on 1/29/16.
//  Copyright © 2016 Amr Lotfy. All rights reserved.
//

#import "AppDelegate.h"
#import <BuddyBuildSDK/BuddyBuildSDK.h>
#import "Sura.h"
#import "Reachability.h"

@import FirebaseAuth;

@interface AppDelegate ()

//@property (nonatomic) int updateCounter;

@property (strong, nonatomic) NSMutableArray<NSNumber *> *localTimeStampsHistory;
@property (strong, nonatomic)__block FIRDatabaseReference *updateTimeStampRef;
@property (strong, nonatomic)__block dispatch_block_t stabilizedSyncBlock;
@property (nonatomic) __block BOOL isLoadedBefore;
@property (nonatomic) __block BOOL shouldFullyUploadReviewsHistory;

@end

@implementation AppDelegate

Reachability* reachability;
NetworkStatus remoteHostStatus;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [BuddyBuildSDK setup];
    [self initReachability];
    [FIRApp configure];
    //[FIRDatabase database].persistenceEnabled = YES;
    
    self.firebaseDatabaseReference = [[FIRDatabase database] reference];
    
    [self firebaseSignIn:^(BOOL success, NSString *error){
        if (error == nil){
            [self registerTimeStampTrigger];
        } else {
            NSLog(@"Error: %@",error.localizedLowercaseString);
        }
    }];
    
    return YES;
}


//TODO download ONLY new entries after last sync and upload ONLY diff entries.
//TODO sync all members, not just current member !!!
- (void)syncHistory {
    if (!self.userID) {
        return;
    }
    
    [self syncMembers:^{
        NSLog(@"Members synced.");
        [self onTimeStampAltered:^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"WillStartUpdatedFromFireBase"
                                                                object:self];
            [self downloadReviewsHistory: ^{
                [self downloadMemoHistory: ^{
                    [self uploadHistory:^(BOOL success, BOOL dirty){
                        [self updateTimeStamp:dirty];
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdatedFromFireBase"
                                                                            object:self];
                    }];
                }];
            }];
        }];
    }];
}

-(void)registerTimeStampTrigger{
    if (!self.userID) {
        return;
    }
    
    self.updateTimeStampRef = [[[[self.firebaseDatabaseReference
                                  child:@"users"]
                                 child: self.userID]
                                child:[[[DataSource shared] getCurrentUser] nonEmptyId]]
                               child:@"update_stamp"];
    [self.updateTimeStampRef observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        
        if(snapshot.value == [NSNull null]) {
            self.shouldFullyUploadReviewsHistory = YES;
            return;
        }
        
        NSNumber *timestamp = snapshot.value;
        
        NSLog(@"TimeStamp Trigger: %ld", (long)[timestamp integerValue]);
        
        //Drop if local echo
        
        for (NSNumber *number in self.localTimeStampsHistory) {
            if ([number integerValue] == [timestamp integerValue]) {
                NSLog(@"Dropped local timestamp trigger echo");
                return;
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
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((self.isLoadedBefore ? 5 : 0) * NSEC_PER_SEC)), dispatch_get_main_queue(), self.stabilizedSyncBlock);
        self.isLoadedBefore = YES;
    }];
}

- (void)syncMembers:(void(^)(void))completion{
    //members node children
    [[self membersRef] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        
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
            [self addMemberWithId:[member userId] name:[member name]];
        }
        
        if(completion != nil) {
            completion();
        }
    }];
}

- (void)initReachability{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNetworkChange:) name:kReachabilityChangedNotification object:nil];
    reachability = [Reachability reachabilityForInternetConnection];
    [reachability startNotifier];
    
    remoteHostStatus = [reachability currentReachabilityStatus];
    self.isConnected = !(remoteHostStatus == NotReachable);
    NSLog(@"Reachability: ");
    if(self.isConnected) {
        NSLog(@"Connection established\n");
    } else {
        NSLog(@" No connection\n");
    }
}

- (void)handleNetworkChange:(NSNotification *)notice {
    if(self.isConnected) {
        NSLog(@"\nConnection established\n");
        if (!self.isSignedIn) {
            [self firebaseSignIn:^(BOOL success, NSString *error){
                if (error == nil){
                    [self syncHistory];
                }
            }];
        } else {
           [self syncHistory];
        }
    } else {
       NSLog(@" No connection\n");
    }
}

- (BOOL)isConnected {
    remoteHostStatus = [reachability currentReachabilityStatus];
    _isConnected = (remoteHostStatus != NotReachable);
    return _isConnected;
}

- (NSString *)suraIndexFromSuraName:(NSString *)suraName{
    return [NSString stringWithFormat:@"%lu",((unsigned long) [Sura.suraNames indexOfObject:suraName] + 1)];
}

- (NSMutableArray<NSNumber *> *)sort:(NSMutableArray<NSNumber *> *)source{
    NSMutableArray<NSNumber *> * result = source;
    NSSortDescriptor *lowToHigh = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
    [result sortUsingDescriptors:[NSArray arrayWithObject:lowToHigh]];
    
    return result;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    //[self syncHistory];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

//Firebase

- (void)firebaseSignIn:(void (^)(BOOL success, NSString *error)) completion {
    if (!self.isConnected) {
        return;
    }
    NSString *email = [[NSUserDefaults standardUserDefaults] stringForKey:@"email"];
    NSString *password = [[NSUserDefaults standardUserDefaults] stringForKey:@"password"];
    
    if (email != nil && password != nil) {
        [self signInWithEmail:email password:password completion: completion];
    }
}

- (void)signInWithEmail:(NSString *)email
               password:(NSString *)password
             completion:(void (^)(BOOL success, NSString *error)) completion {
    if (!self.isConnected) {
        completion(NO, @"no Internet connection");
        return;
    }
    
    [[FIRAuth auth] signInWithEmail:email password:password completion:^(FIRUser * _Nullable user, NSError * _Nullable error) {
        if (!error) {
            self.isSignedIn = YES;
            NSLog(@"Success sign in firebase: email: %@, password: %@", email, password);
            NSLog(@"user.uid: %@",user.uid);
            self.userID = user.uid;
            [[NSUserDefaults standardUserDefaults] setObject:email forKey:@"email"];
            [[NSUserDefaults standardUserDefaults] setObject:password forKey:@"password"];
            [[NSNotificationCenter defaultCenter] postNotificationName:FireBaseSignInNotification object:self];
            
            if (completion != nil) {
                completion(YES, nil);
            }
            
        } else {
            self.isSignedIn = NO;
            [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"email"];
            [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"password"];
            NSLog(@"Error signing in to firebase %@", error);
            if (self.isConnected) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"FirebaseInvalidCredentials" object:self];
            }
            
            if (completion != nil) {
                completion(NO, error.localizedDescription);
            }
        }
    }];
}

- (void)signUpWithEmail: (NSString *)email
               password: (NSString *)password
             completion: (void (^)(BOOL success, NSString *error)) completion {
    if (!self.isConnected) {
        completion(NO, @"no Internet connection");
        return;
    }
    
    [[FIRAuth auth] createUserWithEmail:email password:password completion:^(FIRUser * _Nullable user, NSError * _Nullable error) {
        if (error != nil) {
            completion(NO, error.localizedDescription);
        } else {
            self.isSignedIn = YES;
            [[NSUserDefaults standardUserDefaults] setObject:email forKey:@"email"];
            [[NSUserDefaults standardUserDefaults] setObject:password forKey:@"password"];
            NSLog(@"firebaseSignIn created user %@ ", user);
            [self registerTimeStampTrigger];
            completion(YES, nil);
        }
    }];
}

//Only once per app install

//- (void)setUpdateCounter:(int)updateCounter{
//    _updateCounter = updateCounter;
//    [self updateSensor];
//}

- (FIRDatabaseReference *)reviewsRef {
    if (!self.userID) {
        return nil;
    }
    return [[[[self.firebaseDatabaseReference
               child:@"users"]
              child: self.userID]
             child:[[[DataSource shared] getCurrentUser] nonEmptyId]]
            child:@"reviews"];
}

- (FIRDatabaseReference *)memoRef {
    if (!self.userID) {
        return nil;
    }
    return [[[[self.firebaseDatabaseReference
               child:@"users"]
              child: self.userID]
             child:[[[DataSource shared] getCurrentUser] nonEmptyId]]
            child:@"memorization"];
}

- (FIRDatabaseReference *)membersRef {
    if (!self.userID) {
        return nil;
    }
    return [[[self.firebaseDatabaseReference
               child:@"users"]
              child: self.userID]
             child:@"members"];
}

- (void)addMemberWithId:(NSString *)memberId name:(NSString *)name {
    if (![name isEqualToString:@"Master"]) {
        [[[self membersRef] child:memberId] setValue:name];
    }
    
}

//- (void)removeObservers{
//    [[self reviewsRef] removeAllObservers];
//    [[self memoRef] removeAllObservers];
//}

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
    if (!self.userID || !updateFBTimeStamp) {
        return;
    }
    
    [[[[[self.firebaseDatabaseReference
       child:@"users"]
       child: self.userID]
      child:[[[DataSource shared] getCurrentUser] nonEmptyId]]
      child:@"update_stamp"] setValue:date];
}

- (void)remoteTimeStamp:(void(^)(NSNumber *timestamp))completion {
    if (!self.userID) {
        completion(nil);
        return;
    }
    [[[[[self.firebaseDatabaseReference
        child:@"users"]
       child: self.userID]
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
        if ((timestamp == nil || [timestamp integerValue] != [localTimeStamp integerValue]) && completion != nil ) {
            completion();
        }
    }];
}

- (NSString *)getMostRecentFBReviewsTimeStamp {
    NSString *result = [[NSUserDefaults standardUserDefaults] stringForKey:@"MostRecentFBReviewsTimeStamp"];
    if (result == nil){
        result = @"0";
        [self setMostRecentFBReviewsTimeStamp:@"0"];
    }
    
    NSLog(@"getMostRecentFBReviewsTimeStamp: %@", result);
    return result;
}

- (void)setMostRecentFBReviewsTimeStamp: (NSString *)timestamp {
    [[NSUserDefaults standardUserDefaults] setObject:timestamp forKey:@"MostRecentFBReviewsTimeStamp"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)downloadReviewsHistory:(void(^)(void))completion {
    if (!self.userID) {
        return;
    }
    
    NSString *recentTimeStamp = [self getMostRecentFBReviewsTimeStamp];
    
    [[[[self reviewsRef] queryOrderedByKey] queryStartingAtValue:recentTimeStamp] observeSingleEventOfType:(FIRDataEventTypeValue) withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSLog(@"reviewsRef observeSingleEventOfType:FIRDataEventTypeValue");
            NSDictionary<NSString *, NSDictionary *> *reviews = snapshot.value;
            if (snapshot.value != [NSNull null]) {
                
                NSInteger maxTimeStamp = [recentTimeStamp integerValue];
                NSLog(@"history dump: %@", snapshot.value);
                
                NSMutableArray *keys = reviews.allKeys.mutableCopy;
                [keys removeObject:recentTimeStamp];
                
                for (NSString *key in keys)  {
                    if ([key integerValue] > maxTimeStamp) {
                        maxTimeStamp = [key integerValue];
                    }
                    
                    //TODO parse transaction record and apply operation
                    NSDictionary *transaction = reviews[key];
                    NSString *operation = transaction[@"op"];
                    if (operation == nil) {
                        operation = @"refresh";
                    }
                    if ([operation isEqualToString:@"refresh"]) {
                        NSString *timeStamp = transaction[@"time"];
                        NSString *suraIndex = transaction[@"sura"];
                        NSTimeInterval interval = [timeStamp doubleValue];
                        NSDate *date = [NSDate dateWithTimeIntervalSince1970:interval];
                        
                        NSInteger index = [suraIndex integerValue];
                        if (index == 0) {
                            continue;
                        }
                        NSString *suraName = [Sura suraNames][index - 1];
                        [[DataSource shared] saveSuraLastRefresh:date suraName:suraName upload:NO];
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
                //TODO rename reviews to transactions
                [self setMostRecentFBReviewsTimeStamp:[NSString stringWithFormat:@"%ld",maxTimeStamp]];
            }
            
            if (completion != nil) {
                completion();
            }
        });
    }];
}

- (void)downloadMemoHistory:(void(^)(void))completion {
    if (!self.userID) {
        if (completion != nil) {
            completion();
        }
        return;
    }
//TODO: if user switched while downloading data will be saved in other user history!!!!!
    [[self memoRef] observeSingleEventOfType:(FIRDataEventTypeValue) withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSLog(@"memoRef observeSingleEventOfType:FIRDataEventTypeValue");
                if (snapshot.value != [NSNull null]) {
                    for (FIRDataSnapshot *entry in snapshot.children) {
                        NSString *suraIndex = entry.key;
                        NSInteger state = [entry.value integerValue];
                        NSInteger index = [suraIndex integerValue];
                        if (index == 0) {
                            return;
                        }
                        NSString *suraName = [Sura suraNames][index - 1];
                        [[DataSource shared] setMemorizedStateForSura:suraName state:state upload:NO];
                    }
                }
                
                if (completion != nil) {
                    completion();
                }
            });
    }];

}

- (void)enqueueAllReviewsHistoryForUpload{
    //put all reviews transactions in upload queue
    for (PeriodicTask *task in [DataSource shared].tasks) {
        if(task.history.count == 0 ) {
            continue;
        }
        
        for (NSDate *date in task.history) {
            NSNumber *dateNumber =  [NSNumber numberWithLongLong:[date timeIntervalSince1970]];
            NSDictionary *refreshRecord = @{@"time": dateNumber, @"sura": [self suraIndexFromSuraName:task.name]};
            [self enqueueInUploadQueue:refreshRecord];
        }
    }
}

BOOL uploadInProgress;

//TODO handle error uploading
- (void)uploadHistory:(void(^)(BOOL success, BOOL alteredHistory))completion{
    uploadInProgress = YES;
    static BOOL dirty = NO;
    static BOOL networkError = NO;
    
    if (self.shouldFullyUploadReviewsHistory) {
        self.shouldFullyUploadReviewsHistory = NO;
        [self enqueueAllReviewsHistoryForUpload];
    }
    
    if ([self getUploadQueue].count == 0 || networkError) {
        uploadInProgress = NO;
        if (completion != nil) {
            completion(!networkError, dirty);
        }
        dirty = NO;
        networkError = NO;
        self.shouldFullyUploadReviewsHistory = NO;
        return;
    }

    NSString *timestamp = [self timestamp];
    
    [[[[[[self.firebaseDatabaseReference
          child:@"users"]
         child: self.userID]
        child:[[[DataSource shared] getCurrentUser] nonEmptyId]]
       child:@"reviews"]
      child: timestamp]
     setValue: [self getUploadQueueHead] withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
         if (error == nil) {
             dirty = YES;
             [self dequeueFromUploadQueue];
             [self setMostRecentFBReviewsTimeStamp:timestamp];
             //replace recursion with loop
         } else {
             NSLog(@"History upload error %@", error.localizedDescription);
             //terminate gracefully
             networkError = YES;
         }
         [self uploadHistory:completion];
     }];
    
    //TODO memorization upload
}

- (NSString *)suraNameToIndexString:(NSString *)suraName {
    return [NSString stringWithFormat:@"%u", [[Sura suraNames] indexOfObject:suraName] + 1];
}

- (void)refreshSura:(NSString *)suraName withHistory:(NSArray *)history updateFBTimeStamp:(BOOL)updateFBTimeStamp{
    
    if (!self.userID) {
        return;
    }
    
    for (NSDate *date in history) {
        NSNumber *dateNumber =  [NSNumber numberWithLongLong:[date timeIntervalSince1970]];
        NSDictionary *refreshRecord = @{@"time": dateNumber, @"sura": [self suraIndexFromSuraName:suraName]};
        [self enqueueInUploadQueue:refreshRecord];
    }
    
    if (!uploadInProgress) {
        [self uploadHistory:^(BOOL success, BOOL alteredHistory){
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
    NSMutableArray *uploadQueue = [self getUploadQueue].mutableCopy;
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
    NSArray *uploadQueue = [[NSUserDefaults standardUserDefaults] objectForKey:@"uploadQueue"];
    if (uploadQueue == nil) {
        uploadQueue = @[];
        
        [self setUploadQueue:uploadQueue];
    }
    
    return uploadQueue;
}

- (void)setUploadQueue:(NSArray *)uploadQueue{
    [[NSUserDefaults standardUserDefaults] setObject:uploadQueue forKey:@"uploadQueue"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}



- (NSString *)timestamp {
    NSNumber *date =  [NSNumber numberWithLongLong: (long)([[NSDate new] timeIntervalSince1970] * 1000000.0)];
    NSString *dateString = [date stringValue];
    
    return dateString;
}

- (void)refreshSura:(NSString *)suraName updateFBTimeStamp:(BOOL)updateFBTimeStamp{
    
    if (self.userID) {
        NSNumber *date =  [NSNumber numberWithDouble:[[NSDate new] timeIntervalSince1970]];
        
        NSDictionary *refreshRecord = @{@"time": date, @"sura": [self suraIndexFromSuraName:suraName]};
        [self enqueueInUploadQueue:refreshRecord];
        
        if (!uploadInProgress) {
            [self uploadHistory:^(BOOL success, BOOL alteredHistory){
                if (alteredHistory) {
                    [self updateTimeStamp:updateFBTimeStamp];
                }
                
            }];
        }
    }
}

- (void)refreshSura:(NSString *)suraName withMemorization:(NSInteger)memorization updateFBTimeStamp:(BOOL)updateFBTimeStamp{
    
    ///TODO memorization should have timstamp details and be structured like reviews tree
    if (self.userID) {

        [[[[[[self.firebaseDatabaseReference
               child: @"users"]
              child: self.userID]
            child: [[[DataSource shared] getCurrentUser] nonEmptyId]]
             child: @"memorization"]
            child: [self suraIndexFromSuraName:suraName]]
           setValue: [NSNumber numberWithInteger:memorization]];
        [self updateTimeStamp: updateFBTimeStamp];
    }
    
}

- (void)refreshSura:(NSString *)suraName withDate:(NSNumber *)date updateFBTimeStamp:(BOOL)updateFBTimeStamp{
    
    if (self.userID) {
        NSDictionary *refreshRecord = @{@"time": date, @"sura": [self suraIndexFromSuraName:suraName]};

        [self enqueueInUploadQueue:refreshRecord];
        
        if (!uploadInProgress) {
            [self uploadHistory:^(BOOL success, BOOL alteredHistory){
                if (alteredHistory) {
                    [self updateTimeStamp:updateFBTimeStamp];
                }
            }];
        }
    }
}

//TODO use string constants instead of magic strings!!
- (NSMutableArray *)getMemorizationQueue {
    NSMutableArray *memQueue = [((NSArray *)[[NSUserDefaults standardUserDefaults] objectForKey:@"MemorizationQueue"]) mutableCopy];
    if (memQueue == nil){
        memQueue = @[].mutableCopy;
        [self setMemorizationQueue:memQueue];
    }
    
    return memQueue;
}

- (void)setMemorizationQueue:(NSArray *)memQueue {
    if (memQueue == nil) {
        memQueue = @[];
    }
    [[NSUserDefaults standardUserDefaults] setObject:memQueue forKey:@"MemorizationQueue"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)enqueueInMemorizationQueue:(NSDictionary *)memorizationRecord {
    if (memorizationRecord == nil) {
        return;
    }
    NSMutableArray *memQueue = [self getMemorizationQueue];
    [memQueue addObject:memorizationRecord];
    
    [self setMemorizationQueue:memQueue];
}

- (NSDictionary *)getMemorizationQueueHead {
    NSMutableArray *memQueue = [self getMemorizationQueue];
    if (memQueue.count == 0) {
        return nil;
    }
    
    return memQueue[0];
}

- (NSDictionary *)dequeueFromMemorizationQueue {
    NSMutableArray *memQueue = [self getMemorizationQueue];
    if(memQueue.count == 0) {
        return nil;
    }
    
    NSDictionary *memRecord = memQueue[0];
    [memQueue removeObjectAtIndex:0];
    
    [self setMemorizationQueue:memQueue];
    
    return memRecord;
}

@end
