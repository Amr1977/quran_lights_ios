//
//  AppDelegate.h
//  QuranGardens
//
//  Created by Amr Lotfy on 1/29/16.
//  Copyright © 2016 Amr Lotfy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DataSource.h"
@import Firebase;
@import FirebaseDatabase;

#define FireBaseSignInNotification @"FirebaseSignedIn"
#define AppVersion @"1.4"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) FIRDatabaseReference *firebaseDatabaseReference;
@property (nonatomic) FIRDatabaseHandle refHandle;
@property(strong, nonatomic) NSString *userID;
@property (nonatomic) BOOL isSignedIn;
@property (nonatomic) BOOL isConnected;

@property (strong, nonatomic) NSMutableDictionary<NSString *,NSMutableArray<NSNumber *> *> *fbRefreshHistory;
@property (nonatomic) NSMutableDictionary<NSString *, NSNumber *> *fbMemorizationState;


- (void)refreshSura:(NSString *)suraName;
- (void)refreshSura:(NSString *)suraName withDate:(NSNumber *)date;
- (void)refreshSura:(NSString *)suraName withHistory:(NSArray *)history;
- (NSMutableArray<NSNumber *> *)sort:(NSMutableArray<NSNumber *> *)source;
- (void)updateTimeStamp;


- (void)signUpWithEmail: (NSString *)email
               password: (NSString *)password
             completion: (void (^)(BOOL success, NSString *error))completion;

- (void)signInWithEmail:(NSString *)email
               password:(NSString *)password
             completion:(void (^)(BOOL success, NSString *error))completion;

- (void)refreshSura:(NSString *)suraName withMemorization:(NSInteger)memorization;

@property (weak,nonatomic) DataSource *dataSource;

@end

