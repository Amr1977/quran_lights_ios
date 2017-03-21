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

@property (nonatomic) BOOL isSignedUp;

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
    
    NetworkStatus remoteHostStatus = [reachability currentReachabilityStatus];
    
    NSLog(@"Reachability:\n");
    if(remoteHostStatus == NotReachable) {NSLog(@" No connection\n");}
    else if (remoteHostStatus == ReachableViaWiFi) {NSLog(@"wifi Connection\n"); }
    else if (remoteHostStatus == ReachableViaWWAN) {NSLog(@"cell Connection\n"); }
}

- (void) handleNetworkChange:(NSNotification *)notice
{
    remoteHostStatus = [reachability currentReachabilityStatus];
    
    NSLog(@"Reachability:");
    if(remoteHostStatus == NotReachable) {NSLog(@" No connection\n");}
    else if (remoteHostStatus == ReachableViaWiFi) {NSLog(@"wifi Connection\n"); }
    else if (remoteHostStatus == ReachableViaWWAN) {NSLog(@"cell Connection\n"); }
    
    if(remoteHostStatus != NotReachable) {
        if (!self.isSignedIn) {
            [self firebaseSignIn];
        } else {
            [self checkUpdatetimeStamps];
        }
    }
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
                 NSLog(@"user.uid: %@",user.uid);
                 self.userID = user.uid;
                 [[NSNotificationCenter defaultCenter] postNotificationName:FireBaseSignInNotification object:self];
                 //[self signUpWithEmail:@"amr.lotf@badrit.com" password:@"pazzword2011" userName:@"amr"];
                 [self checkUpdatetimeStamps];
                 
             } else {
                 NSLog(@"Error signing in to firebase %@", error);
             }
             
         }];
    }
}

- (void)signUpWithEmail: (NSString *)email password: (NSString *)password userName: (NSString *)userName
             completion: (void (^)(BOOL success))completion {
    FIRAuthCredential *credential = [FIREmailPasswordAuthProvider credentialWithEmail:email
                                                                             password:password];
    [[FIRAuth auth].currentUser linkWithCredential:credential
                                        completion:^(FIRUser *_Nullable user, NSError *_Nullable error) {
                                            if (error != nil) {
                                                NSLog(@"Error linking account %@", error.localizedDescription);
                                                completion(false);
                                            } else {
                                                self.isSignedUp = true;
                                                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isSignedUp"];
                                                [[NSUserDefaults standardUserDefaults] setObject:email forKey:@"email"];
                                                [[NSUserDefaults standardUserDefaults] setObject:password forKey:@"password"];
                                                [[NSUserDefaults standardUserDefaults] setObject:userName forKey:@"userName"];
                                                NSLog(@"firebaseSignIn created user %@ ", user);
                                                completion(true);
                                            }
                                        }
     ];
}

- (void)checkUpdatetimeStamps{
    if (self.userID) {
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
    
    if (!self.userID) {
        return;
    }
    
    self.fbRefreshHistory = @{}.mutableCopy;
    
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
    if (!self.userID) {
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
    
    if (self.userID) {
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

- (void)refreshSura:(NSString *)suraName withDate:(NSNumber *)date {
    if (self.userID) {
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
    if (self.userID) {
        [[[[self.firebaseDatabaseReference
            child:@"users"]
           child: self.userID]
          child:@"update"]
         setValue:updateDate];
    }
}

@end
