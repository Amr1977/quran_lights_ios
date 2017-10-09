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
@property (nonatomic) __block BOOL shouldFullyUploadReviewsHistory;
@property (nonatomic) __block NSTimeInterval serverOffset;

@end

@implementation AppDelegate

Reachability* reachability;
NetworkStatus remoteHostStatus;
BOOL uploadInProgress;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [BuddyBuildSDK setup];
    [self initReachability];
    [FIRApp configure];
    //[FIRDatabase database].persistenceEnabled = YES;
    
    self.firebaseDatabaseReference = [[FIRDatabase database] reference];
    
    [self firebaseSignIn:^(BOOL success, NSString *error){
        if (error == nil){
            [self serverTimeSkew];
            //[self registerTimeStampTrigger];
        } else {
            NSLog(@"Error: %@",error.localizedLowercaseString);
        }
    }];
    
    return YES;
}

- (void)serverTimeSkew {
    FIRDatabaseReference *offsetRef = [[FIRDatabase database] referenceWithPath:@".info/serverTimeOffset"];
    [offsetRef observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot) {
        self.serverOffset = [(NSNumber *)snapshot.value doubleValue];
        NSLog(@"Estimated server time: %0.6f", self.serverOffset);
    }];
}


//TODO sync all members, not just current member !!!
- (void)syncHistory {
    NSLog(@"syncHistory started");
    if (!self.isConnected || !self.userID) {
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
    if (!(self.isConnected) || self.userID == nil  ) {
        return;
    }
    
    /**
    * first sync is made on app launch and does not need to be delayed
    */
    static BOOL isFirstSync = YES;
    
    self.updateTimeStampRef = [[[[self.firebaseDatabaseReference
                                  child:@"users"]
                                 child: self.userID]
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
        completion(NO, @"no Internet connection");
        return;
    }
    //TODO remove afrter debug finish
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
            [self registerTimeStampTrigger];
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

- (FIRDatabaseReference *)reviewsRef {
    if (!(self.isConnected) || self.userID == nil  ) {
        return nil;
    }
    return [[[[self.firebaseDatabaseReference
               child:@"users"]
              child: self.userID]
             child:[[[DataSource shared] getCurrentUser] nonEmptyId]]
            child:@"reviews"];
}

- (FIRDatabaseReference *)membersRef {
    if (!(self.isConnected) || self.userID == nil  ) {
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
    
    if (!self.isConnected || !self.userID || !updateFBTimeStamp ) {
        return;
    }
    
    [[[[[self.firebaseDatabaseReference
       child:@"users"]
       child: self.userID]
      child:[[[DataSource shared] getCurrentUser] nonEmptyId]]
      child:@"update_stamp"] setValue:date];
}

- (void)remoteTimeStamp:(void(^)(NSNumber *timestamp))completion {
    if (!self.isConnected || !self.userID) {
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
    if (!self.isConnected || !self.userID) {
        if (completion != nil) {
            completion();
        }
        return;
    }
    
    NSString *recentTimeStamp = [self getLastTransactionTimeStamp];
    
    [[[[self reviewsRef] queryOrderedByKey] queryStartingAtValue:recentTimeStamp] observeSingleEventOfType:(FIRDataEventTypeValue) withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSLog(@"reviewsRef observeSingleEventOfType:FIRDataEventTypeValue");
            NSDictionary<NSString *, NSDictionary *> *reviews = snapshot.value;
            if (snapshot.value == [NSNull null]) {
                self.shouldFullyUploadReviewsHistory = YES;
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
                                    @"sura": [self suraIndexFromSuraName:task.name]};
        
        reviews[[self timestamp]] = memRecord;
        NSLog(@"reviews upload added: %@", memRecord);
        
        for (NSDate *date in task.history) {
            NSNumber *dateNumber =  [NSNumber numberWithLongLong:[date timeIntervalSince1970]];
            NSDictionary *refreshRecord = @{@"op": @"refresh", @"time": dateNumber, @"sura": [self suraIndexFromSuraName:task.name]};
            reviews[[self timestamp]] = refreshRecord;
            NSLog(@"reviews upload added: %@", refreshRecord);
        }
    }
    
    return reviews;
}

- (void)uploadHistory:(void(^)(BOOL success, BOOL alteredHistory))completion{
    if (!(self.isConnected) || self.userID == nil  ) {
        return;
    }
    uploadInProgress = YES;
    static BOOL dirty = NO;
    static BOOL networkError = NO;
    
    if (self.shouldFullyUploadReviewsHistory) {
        self.shouldFullyUploadReviewsHistory = NO;
        NSDictionary *reviews = [self reviewsDic];
        [[[[[self.firebaseDatabaseReference
            child:@"users"]
           child: self.userID]
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

- (NSString *)suraNameToIndexString:(NSString *)suraName {
    return [NSString stringWithFormat:@"%u", [[Sura suraNames] indexOfObject:suraName] + 1];
}

- (void)refreshSura:(NSString *)suraName withHistory:(NSArray *)history updateFBTimeStamp:(BOOL)updateFBTimeStamp{
    
    if (!self.isConnected || !self.userID) {
        return;
    }
    
    for (NSDate *date in history) {
        NSNumber *dateNumber =  [NSNumber numberWithLongLong:[date timeIntervalSince1970]];
        NSDictionary *refreshRecord = @{@"op": @"refresh", @"time": dateNumber, @"sura": [self suraIndexFromSuraName:suraName]};
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
    if(filteredArray == nil || filteredArray.count == 0) {
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
    NSNumber *date =  [NSNumber numberWithLongLong: ([[NSDate new] timeIntervalSince1970] * 1000.0 + self.serverOffset) * 1000.0];
    NSString *dateString = [date stringValue];
    
    NSLog(@"generated timestamp: %@", dateString);
    
    return dateString;
}

- (void)refreshSura:(NSString *)suraName updateFBTimeStamp:(BOOL)updateFBTimeStamp{
    
    if (self.userID) {
        NSNumber *date =  [NSNumber numberWithDouble:[[NSDate new] timeIntervalSince1970]];
        
        NSDictionary *refreshRecord = @{@"op": @"refresh", @"time": date, @"sura": [self suraIndexFromSuraName:suraName]};
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
}

- (void)refreshSura:(NSString *)suraName withMemorization:(NSInteger)memorization updateFBTimeStamp:(BOOL)updateFBTimeStamp{
    if (self.userID) {
        NSString *memString = [NSString stringWithFormat:@"%ld", memorization];
        NSDictionary *refreshRecord = @{@"op": @"memorize" , @"state": memString , @"sura": [self suraIndexFromSuraName:suraName]};

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
}

- (void)refreshSura:(NSString *)suraName withDate:(NSNumber *)date updateFBTimeStamp:(BOOL)updateFBTimeStamp{
    if (self.userID) {
        NSDictionary *refreshRecord = @{@"op": @"refresh", @"time": date, @"sura": [self suraIndexFromSuraName:suraName]};

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
}

@end
