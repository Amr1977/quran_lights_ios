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



@end

@implementation AppDelegate

Reachability* reachability;
NetworkStatus remoteHostStatus;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [BuddyBuildSDK setup];
    [self initReachability];
    [FIRApp configure];
    self.firebaseDatabaseReference = [[FIRDatabase database] reference];
    [self firebaseSignIn];
    
    return YES;
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

- (void) handleNetworkChange:(NSNotification *)notice
{
    if(self.isConnected) {
        NSLog(@"\nConnection established\n");
        if (!self.isSignedIn) {
            [self firebaseSignIn];
        } else {
            [self checkUpdatetimeStamps];
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
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

//Firebase

- (void)firebaseSignIn{
    if (!self.isConnected) {
        return;
    }
    self.isSignedUp = [[NSUserDefaults standardUserDefaults] boolForKey:@"isSignedUp"];
    NSString *email = [[NSUserDefaults standardUserDefaults] stringForKey:@"email"];
    NSString *password = [[NSUserDefaults standardUserDefaults] stringForKey:@"password"];
    
    if (self.isSignedUp && email != nil && password != nil) {
        [[FIRAuth auth] signInWithEmail:email
                               password:password
                             completion:^(FIRUser * _Nullable user, NSError * _Nullable error) {
                                 if (error != nil) {
                                     NSLog(@"Error Signing in as %@", error.localizedDescription);
                                 } else {
                                     NSLog(@"Signed in successfully as %@ with email: %@, password: [%@]", user, email, password);
                                     self.isSignedIn = YES;
                                     NSLog(@"user.uid: %@",user.uid);
                                     self.userID = user.uid;
                                     [[NSNotificationCenter defaultCenter] postNotificationName:FireBaseSignInNotification object:self];
                                     [self checkUpdatetimeStamps];
                                 }
        }];
    } else {
        [[FIRAuth auth]
         signInAnonymouslyWithCompletion:^(FIRUser *_Nullable user, NSError *_Nullable error) {
             if (!error) {
                 self.isSignedIn = YES;
                 self.isSignedUp = NO;
                 [[NSUserDefaults standardUserDefaults] setBool:self.isSignedUp forKey:@"isSignedUp"];
                 NSLog(@"user.uid: %@",user.uid);
                 self.userID = user.uid;
                 [[NSNotificationCenter defaultCenter] postNotificationName:FireBaseSignInNotification object:self];
                 //[self signUpWithEmail:@"amr.lotf@badrit.com" password:@"pazzword2011" userName:@"amr"];
                 [self checkUpdatetimeStamps];
                 
             } else {
                 self.isSignedIn = NO;
                 self.isSignedUp = NO;
                 [[NSUserDefaults standardUserDefaults] setBool:self.isSignedUp forKey:@"isSignedUp"];
                 NSLog(@"Error signing in to firebase %@", error);
             }
         }];
    }
}

- (void)signUpWithEmail: (NSString *)email password: (NSString *)password userName: (NSString *)userName
             completion: (void (^)(BOOL success, NSString *error))completion {
    if (!self.isConnected) {
        completion(NO, @"no Internet connection");
        return;
    }
    
    [self signOut];
    
    FIRAuthCredential *credential = [FIREmailPasswordAuthProvider credentialWithEmail:email
                                                                             password:password];
    [[FIRAuth auth].currentUser linkWithCredential:credential
                                        completion:^(FIRUser *_Nullable user, NSError *_Nullable error) {
                                            if (error != nil) {
                                                NSLog(@"Error linking account %@", error.localizedDescription);
                                                completion(NO, error.localizedDescription);
                                            } else {
                                                self.isSignedUp = YES;
                                                self.isSignedIn = YES;
                                                [[NSUserDefaults standardUserDefaults] setBool:self.isSignedUp  forKey:@"isSignedUp"];
                                                [[NSUserDefaults standardUserDefaults] setObject:email forKey:@"email"];
                                                [[NSUserDefaults standardUserDefaults] setObject:password forKey:@"password"];
                                                [[NSUserDefaults standardUserDefaults] setObject:userName forKey:@"userName"];
                                                NSLog(@"firebaseSignIn created user %@ ", user);
                                                [self checkUpdatetimeStamps];
                                                completion(YES, nil);
                                            }
                                        }
     ];
}

- (void)signOut{
    NSError *signOutError;
    BOOL status = [[FIRAuth auth] signOut:&signOutError];
    if (!status) {
        NSLog(@"Error signing out: %@", signOutError);
    } else {
        self.isSignedIn = NO;
        self.isSignedUp = NO;
    }
}

- (void)signInWithEmail:(NSString *)email password:(NSString *)password completion:(void (^)(BOOL success, NSString *error))completion {
    if (!self.isConnected) {
        completion(NO, @"no Internet connection");
        return;
    }
    
    [self signOut];
    
    [[FIRAuth auth]
     createUserWithEmail:email
     password:password
     completion:^(FIRUser *_Nullable user,
                  NSError *_Nullable error) {
         if (error != nil) {
             NSLog(@"firebaseSignIn error signin %@ ", error.localizedDescription);
             self.isSignedUp = NO;
             self.isSignedIn = NO;
             [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"isSignedUp"];
             completion(NO, error.localizedDescription);
         } else {
             self.userID = user.uid;
             self.isSignedUp = YES;
             self.isSignedIn = YES;
             [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isSignedUp"];
             [[NSUserDefaults standardUserDefaults] setObject:email forKey:@"email"];
             [[NSUserDefaults standardUserDefaults] setObject:password forKey:@"password"];
             NSLog(@"firebaseSignIn signed in user %@ ", user);
             [self checkUpdatetimeStamps];
             completion(YES, nil);
         }
     }];
}

- (void)checkUpdatetimeStamps{
    if (self.userID && self.isConnected) {
        [[[[self.firebaseDatabaseReference
            child:@"users"]
           child:self.userID]
          child:@"update"]
         observeSingleEventOfType:FIRDataEventTypeValue
         withBlock:^(FIRDataSnapshot * _Nonnull snapshot){
             
             if (snapshot.value == [NSNull null]) {
                 [self loadHistory];
             } else {
                 NSNumber *localUpdateTimeStamp = [[NSUserDefaults standardUserDefaults] valueForKey:@"LastUpdateTimeStamp"];
                 NSNumber *remoteUpdateTimeStamp = snapshot.value;
                 NSLog(@"Update stamp on Firebase %@", remoteUpdateTimeStamp);
                 
                 if ([localUpdateTimeStamp isEqualToNumber:remoteUpdateTimeStamp]) {
                     NSLog(@"History Already Synced with Firebase on %@ %@",
                           localUpdateTimeStamp,
                           [NSDate dateWithTimeIntervalSince1970:localUpdateTimeStamp.doubleValue]);
                     return;
                 } else {
                     if (remoteUpdateTimeStamp != nil){
                         [self loadHistory];
                     }
                 }
             }
         }
         withCancelBlock:^(NSError * _Nonnull error) {
             NSLog(@"%@", error.localizedDescription);
         }];
    }
}

- (void)uploadHistory{
    
}

- (void)loadHistory{
    //return;
    if (!self.userID || !self.isConnected) {
        return;
    }
    
    self.fbRefreshHistory = @{}.mutableCopy;
    self.fbMemorizationState = @{}.mutableCopy;
    
    FIRDatabaseReference * surasRef = [[[self.firebaseDatabaseReference child:@"users"] child: self.userID] child:@"Suras"];
    FIRDatabaseQuery *query = [surasRef queryOrderedByKey];
    
    [[[[self.firebaseDatabaseReference
        child:@"users"]
        child: self.userID]
        child:@"Suras"]
     observeSingleEventOfType:FIRDataEventTypeValue
     withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
         if (!(snapshot.value == [NSNull null])) {
             NSLog(@"########## FIRDataSnapshot snapshot: %@",snapshot);
             NSLog(@"########## FIRDataSnapshot snapshot.value: %@",snapshot.value);
             NSMutableArray *suras = ((NSArray *)snapshot.value).mutableCopy;
             NSLog(@"########## FIRDataSnapshot [snapshot key]: %@",[snapshot key]);
             NSLog(@"########## FIRDataSnapshot [snapshot value]: %@",[snapshot value]);

             NSLog(@"########## suras: %@",suras);
             
             for (FIRDataSnapshot *childSnap in snapshot.children) {
                 NSLog(@"key: %@", childSnap.key);
                 NSLog(@"value: %@", childSnap.value);
                 NSString *indexStr = [NSString stringWithFormat:@"%@", childSnap.key];
                 NSInteger index = indexStr.integerValue;
                 NSDictionary *reviews = ((NSDictionary *)(childSnap.value))[@"reviews"];
                 NSLog(@"Sura %ld %@", (long)index, reviews );
                 NSMutableArray *dates = [reviews allValues].mutableCopy;
                 dates = [self sort:dates];
                 self.fbRefreshHistory[indexStr] = dates;
                 self.fbMemorizationState[indexStr] = (NSNumber *)(((NSDictionary *)(childSnap.value))[@"memorization"]);
             }
         }
         [[NSNotificationCenter defaultCenter] postNotificationName:@"HistoryLoadedFromFireBase" object:self];
     }
     withCancelBlock:^(NSError * _Nonnull error) {
         NSLog(@"%@", error.localizedDescription);
     }];
}

- (void)refreshSura:(NSString *)suraName withHistory:(NSArray *)history{
    [self updateTimeStamp];
    if (!self.userID && self.isConnected) {
        return;
    }
    for (NSDate *date in history) {
        NSNumber *dateNumber =  [NSNumber numberWithLongLong:[date timeIntervalSince1970]];
        NSLog(@"attempting to send %@",dateNumber);
        [[[[[[[self.firebaseDatabaseReference
               child:@"users"]
              child: self.userID]
             child:@"Suras"]
            child:[self suraIndexFromSuraName:suraName]]
           child:@"reviews"] childByAutoId]
         setValue: dateNumber];
    }
}

- (void)refreshSura:(NSString *)suraName{
    
    if (self.userID && self.isConnected) {
        NSNumber *date =  [NSNumber numberWithLongLong:[[NSDate new] timeIntervalSince1970]];
        
        [[[[[[[self.firebaseDatabaseReference
               child:@"users"]
              child: self.userID]
             child:@"Suras"]
            child:[self suraIndexFromSuraName:suraName]]
           child:@"reviews"]
          childByAutoId] setValue: date];
    }
    [self updateTimeStamp];
    
}

- (void)refreshSura:(NSString *)suraName withMemorization:(NSInteger)memorization{
    
    if (self.userID && self.isConnected) {
        [[[[[[self.firebaseDatabaseReference
               child:@"users"]
              child: self.userID]
             child:@"Suras"]
            child:[self suraIndexFromSuraName:suraName]]
           child:@"memorization"]
           setValue: [NSNumber numberWithInteger:memorization]];
    }
    [self updateTimeStamp];
    
}


- (void)refreshSura:(NSString *)suraName withDate:(NSNumber *)date {
    if (self.userID && self.isConnected) {
        [[[[[[[self.firebaseDatabaseReference
               child:@"users"]
              child: self.userID]
             child:@"Suras"]
            child:[self suraIndexFromSuraName:suraName]]
           child:@"reviews"]
          childByAutoId]
         setValue: date];
    }
[self updateTimeStamp];
}

- (void)updateTimeStamp {
    NSNumber *updateDate =  [NSNumber numberWithLongLong:[[NSDate new] timeIntervalSince1970]];
    [[NSUserDefaults standardUserDefaults] setObject:updateDate forKey:@"LastUpdateTimeStamp"];
    
    if (self.userID && self.isConnected) {
        [[[[self.firebaseDatabaseReference
            child:@"users"]
           child: self.userID]
          child:@"update"]
         setValue:updateDate];
    }
}

@end
