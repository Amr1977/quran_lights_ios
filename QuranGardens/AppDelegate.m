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

@end

@implementation AppDelegate

Reachability* reachability;
NetworkStatus remoteHostStatus;

FIRDatabaseReference *reviewsRef;
FIRDatabaseReference *memoRef;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [BuddyBuildSDK setup];
    [self initReachability];
    [FIRApp configure];
    //[FIRDatabase database].persistenceEnabled = YES;
    
    self.firebaseDatabaseReference = [[FIRDatabase database] reference];
    
    [self firebaseSignIn:^(BOOL success, NSString *error){
        if (error == nil){
            [self syncHistory];
        }
    }];
    
    return YES;
}

- (void)syncHistory {
    [self createFirebaseDBRefs];
    [self downloadReviewsHistory: ^{
        [self downloadMemoHistory: ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdatedFromFireBase" object:self];
            [self uploadHistory];
        }];
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
    [self syncHistory];
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
            NSLog(@"Error signing in to firebase %@", error);
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
            [self createFirebaseDBRefs];
            [self syncHistory];
            completion(YES, nil);
        }
    }];
}

//Only once per app install

//- (void)setUpdateCounter:(int)updateCounter{
//    _updateCounter = updateCounter;
//    [self updateSensor];
//}

- (void)createFirebaseDBRefs {
    reviewsRef = [[[[self.firebaseDatabaseReference
                     child:@"users"]
                    child: self.userID]
                   child:[[[DataSource shared] getCurrentUser] nonEmptyId]]
                  child:@"reviews"];
    
    memoRef = [[[[self.firebaseDatabaseReference
                  child:@"users"]
                 child: self.userID]
                child:[[[DataSource shared] getCurrentUser] nonEmptyId]]
               child:@"memorization"];
    
}

//- (void)addFirObservers {
//    
//    [self removeObservers];
//    
//    [reviewsRef observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
//        NSString *timeStamp = snapshot.key;
//        NSString *suraIndex = snapshot.value;
//        NSTimeInterval interval = [timeStamp doubleValue];
//        NSDate *date = [NSDate dateWithTimeIntervalSince1970:interval];
//        NSInteger index = [suraIndex integerValue];
//        
//        NSLog(@"reviewsRef FIRDataEventTypeChildAdded timestamp: %@, sura index: %@", timeStamp, suraIndex);
//        if (index == 0) {
//            return;
//        }
//        NSString *suraName = [Sura suraNames][index - 1];
//        
//        if ([[DataSource shared] saveSuraLastRefresh:date suraName:suraName upload:NO]) {
//            self.updateCounter++;
//        }
//    }];
//    
//    [memoRef observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
//        NSString *suraIndex = snapshot.key;
//        NSInteger state = [snapshot.value integerValue];
//        NSInteger index = [suraIndex integerValue];
//        NSLog(@"memoRef FIRDataEventTypeChildAdded sura: %@, state: %ld", suraIndex, state);
//        if (index == 0) {
//            return;
//        }
//        NSString *suraName = [Sura suraNames][index - 1];
//        if ([[DataSource shared] loadMemorizedStateForSura:suraName] != state) {
//            [[DataSource shared] setMemorizedStateForSura:suraName state:state upload:NO];
//            self.updateCounter++;
//        }
//    }];
//    
//    [memoRef observeEventType:FIRDataEventTypeChildChanged withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
//        
//        NSString *suraIndex = snapshot.key;
//        NSInteger state = [snapshot.value integerValue];
//        NSInteger index = [suraIndex integerValue];
//        NSLog(@"memoRef FIRDataEventTypeChildChanged sura: %@, state: %ld", suraIndex, state);
//        if (index == 0) {
//            return;
//        }
//        NSString *suraName = [Sura suraNames][index - 1];
//        if ([[DataSource shared] loadMemorizedStateForSura:suraName] != state) {
//            [[DataSource shared] setMemorizedStateForSura:suraName state:state upload:NO];
//            self.updateCounter++;
//        }
//    }];
//    
//}

//- (void)updateSensor{
//    int __block counter = self.updateCounter;
//    
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        if (counter == self.updateCounter && counter != 0) {
//            counter = 0;
//            self.updateCounter = 0;
//            NSLog(@"updateSensor: threshold elapsed, posting update notification");
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdatedFromFireBase" object:self];
//        }
//    });
//}

- (void)removeObservers{
    [reviewsRef removeAllObservers];
    [memoRef removeAllObservers];
}

- (void)downloadReviewsHistory:(void(^)(void))completion {
    if (!self.userID) {
        return;
    }
    //download all
    
    [reviewsRef observeSingleEventOfType:(FIRDataEventTypeValue) withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSLog(@"reviewsRef observeSingleEventOfType:FIRDataEventTypeValue");
            NSDictionary<NSString *, NSString *> *reviews = snapshot.value;
            for (NSString *key in reviews.allKeys) {
                NSString *timeStamp = key;
                NSString *suraIndex = reviews[key];
                NSTimeInterval interval = [timeStamp doubleValue];
                NSDate *date = [NSDate dateWithTimeIntervalSince1970:interval];
                NSInteger index = [suraIndex integerValue];
                if (index == 0) {
                    return;
                }
                NSString *suraName = [Sura suraNames][index - 1];
                [[DataSource shared] saveSuraLastRefresh:date suraName:suraName upload:NO];
            }
            if (completion != nil) {
                completion();
            }
        });
    }];
}

- (void)downloadMemoHistory:(void(^)(void))completion {
    [memoRef observeSingleEventOfType:(FIRDataEventTypeValue) withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSLog(@"memoRef observeSingleEventOfType:FIRDataEventTypeValue");
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
                if (completion != nil) {
                    completion();
                }
            });
    }];

}

- (void)uploadHistory{
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (PeriodicTask *task in [[DataSource shared] tasks]) {
            [self refreshSura:task.name withHistory:task.history];
            if (task.memorizedState != 0) {
                [self refreshSura:task.name withMemorization:task.memorizedState];
            }
        }

    });
}

- (NSString *)suraNameToIndexString:(NSString *)suraName {
    return [NSString stringWithFormat:@"%ld", [[Sura suraNames] indexOfObject:suraName] + 1];
}

- (void)refreshSura:(NSString *)suraName withHistory:(NSArray *)history{
    if (!self.userID) {
        return;
    }
    
    for (NSDate *date in history) {
        NSNumber *dateNumber =  [NSNumber numberWithLongLong:[date timeIntervalSince1970]];
        NSLog(@"attempting to send %@",dateNumber);
        [[[[[[self.firebaseDatabaseReference
               child:@"users"]
              child: self.userID]
             child:[[[DataSource shared] getCurrentUser] nonEmptyId]]
           child:@"reviews"]
          child: [dateNumber stringValue]]
         setValue: [self suraIndexFromSuraName:suraName]];
    }
}

- (void)refreshSura:(NSString *)suraName{
    
    if (self.userID) {
        [self removeObservers];

        NSNumber *date =  [NSNumber numberWithLongLong:[[NSDate new] timeIntervalSince1970]];
        NSString *dateString = [date stringValue];
        
        [[[[[[self.firebaseDatabaseReference
              child:@"users"]
             child: self.userID]
            child:[[[DataSource shared] getCurrentUser] nonEmptyId]]
           child:@"reviews"]
          child: dateString]
         setValue: [self suraIndexFromSuraName:suraName]];
    }
}

- (void)refreshSura:(NSString *)suraName withMemorization:(NSInteger)memorization{
    
    if (self.userID) {
        [self removeObservers];

        [[[[[[self.firebaseDatabaseReference
               child: @"users"]
              child: self.userID]
            child: [[[DataSource shared] getCurrentUser] nonEmptyId]]
             child: @"memorization"]
            child: [self suraIndexFromSuraName:suraName]]
           setValue: [NSNumber numberWithInteger:memorization]];
    }
}

- (void)refreshSura:(NSString *)suraName withDate:(NSNumber *)date {
    if (self.userID) {
        [self removeObservers];

        [[[[[[self.firebaseDatabaseReference
              child:@"users"]
             child: self.userID]
            child:[[[DataSource shared] getCurrentUser] nonEmptyId]]
           child:@"reviews"]
          child: [date stringValue]]
         setValue: [self suraIndexFromSuraName:suraName]];
    }
}

@end
