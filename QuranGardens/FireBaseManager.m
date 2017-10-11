//
//  FireBaseManager.m
//  QuranGardens
//
//  Created by   Amr Lotfy on 10/10/17.
//  Copyright © 2017 Amr Lotfy. All rights reserved.
//

#import "FireBaseManager.h"
#import "Reachability.h"
#import "SyncManager.h"
#import "DataSource.h"
@import Firebase;
@import FirebaseDatabase;
@import FirebaseAuth;

@implementation FireBaseManager

Reachability* reachability;
NetworkStatus remoteHostStatus;

+ (FireBaseManager *)shared {
    static FireBaseManager *sharedInstance;
    if(sharedInstance == nil){
        sharedInstance = [[FireBaseManager alloc] init];
    }
    
    return sharedInstance;
}

- (void) start {
    [self initReachability];
    [FIRApp configure];
    //[FIRDatabase database].persistenceEnabled = YES;
    
    self.firebaseDatabaseReference = [[FIRDatabase database] reference];
    
    [self firebaseSignIn:^(BOOL success, NSString *error){
        //NSLog(@"Upload queue: %@", [self getUploadQueue]);
        if (error == nil){
            [self serverTimeSkew];
            //[self registerTimeStampTrigger];
        } else {
            NSLog(@"Error: %@",error.localizedLowercaseString);
        }
    }];
}

- (void)serverTimeSkew {
    FIRDatabaseReference *offsetRef = [[FIRDatabase database] referenceWithPath:@".info/serverTimeOffset"];
    [offsetRef observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot) {
        self.serverOffset = [(NSNumber *)snapshot.value doubleValue];
        NSLog(@"Estimated server time: %0.6f", self.serverOffset);
    }];
}
- (void)initReachability{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNetworkChange:) name:kReachabilityChangedNotification object:nil];
    reachability = [Reachability reachabilityForInternetConnection];
    [reachability startNotifier];
    
    NSLog(@"Reachability: ");
    if([self isConnected]) {
        NSLog(@"Connection established\n");
    } else {
        NSLog(@" No connection\n");
    }
}

- (void)handleNetworkChange:(NSNotification *)notice {
    if([self isConnected]) {
        NSLog(@"\nConnection established\n");
        if (!self.isSignedIn) {
            [self firebaseSignIn:^(BOOL success, NSString *error){
                if (error == nil){
                    [[SyncManager shared] syncHistory];
                }
            }];
        } else {
            [[SyncManager shared] syncHistory];
        }
    } else {
        NSLog(@" No connection\n");
    }
}

- (BOOL)isConnected {
    return [reachability currentReachabilityStatus] != NotReachable;
}


- (void)firebaseSignIn:(void (^)(BOOL success, NSString *error)) completion {
    if (![self isConnected]) {
        completion(NO, @"no Internet connection");
        return;
    }
    //TODO remove after debug finish
    NSString *email = [[NSUserDefaults standardUserDefaults] stringForKey:@"email"];
    NSString *password = [[NSUserDefaults standardUserDefaults] stringForKey:@"password"];
    
    if (email != nil && password != nil) {
        [self signInWithEmail:email password:password completion: completion];
    }
}

- (void)signInWithEmail:(NSString *)email
               password:(NSString *)password
             completion:(void (^)(BOOL success, NSString *error)) completion {
    if (![self isConnected]) {
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
            [[SyncManager shared] registerTimeStampTrigger];
            if (completion != nil) {
                completion(YES, nil);
            }
        } else {
            self.isSignedIn = NO;
            NSLog(@"Error signing in to firebase %@", error);
            if ([self isConnected]) {
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
    if (![self isConnected]) {
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
            [[SyncManager shared] registerTimeStampTrigger];
            completion(YES, nil);
        }
    }];
}

- (FIRDatabaseReference *)reviewsRef {
    if (![self isConnected] || self.userID == nil  ) {
        return nil;
    }
    return [[[[self.firebaseDatabaseReference
               child:@"users"]
              child: self.userID]
             child:[[[DataSource shared] getCurrentUser] nonEmptyId]]
            child:@"reviews"];
}

- (FIRDatabaseReference *)membersRef {
    if (![self isConnected] || self.userID == nil  ) {
        return nil;
    }
    return [[[self.firebaseDatabaseReference
              child:@"users"]
             child: self.userID]
            child:@"members"];
}

@end
