//
//  FireBaseManager.h
//  QuranGardens
//
//  Created by   Amr Lotfy on 10/10/17.
//  Copyright © 2017 Amr Lotfy. All rights reserved.
//

#import <Foundation/Foundation.h>

@import Firebase;
@import FirebaseDatabase;

#define FireBaseSignInNotification @"FirebaseSignedIn"


@interface FireBaseManager : NSObject

@property (strong, nonatomic) FIRDatabaseReference *firebaseDatabaseReference;
@property (nonatomic) FIRDatabaseHandle refHandle;
@property(strong, nonatomic) __block NSString *userID;
@property (nonatomic) __block BOOL isSignedIn;
@property (nonatomic) __block NSTimeInterval serverOffset;
@property (nonatomic) __block BOOL isConnected;

- (void)firebaseSignIn:(void (^)(BOOL success, NSString *error))completion;

- (void)signUpWithEmail: (NSString *)email
               password: (NSString *)password
             completion: (void (^)(BOOL success, NSString *error))completion;

- (void)signInWithEmail:(NSString *)email
               password:(NSString *)password
             completion:(void (^)(BOOL success, NSString *error))completion;

- (FIRDatabaseReference *)membersRef;
- (FIRDatabaseReference *)reviewsRef;
- (void) start;

+ (FireBaseManager *)shared;

@end
