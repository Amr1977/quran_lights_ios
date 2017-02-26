//
//  AppDelegate.h
//  QuranGardens
//
//  Created by Amr Lotfy on 1/29/16.
//  Copyright © 2016 Amr Lotfy. All rights reserved.
//

#import <UIKit/UIKit.h>
@import Firebase;
@import FirebaseDatabase;

#define FireBaseSignInNotification @"FirebaseSignedIn"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) FIRDatabaseReference *firebaseDatabaseReference;
@property (nonatomic) FIRDatabaseHandle refHandle;
@property(strong, nonatomic) NSString *userID;
@property (nonatomic) BOOL isSignedIn;
@property (strong, nonatomic) NSMutableDictionary<NSString *,NSMutableArray<NSNumber *> *> *fbRefreshHistory;


- (void)refreshSura:(NSString *)suraName;
- (void)refreshSura:(NSString *)suraName withDate:(NSNumber *)date;
- (void)refreshSura:(NSString *)suraName withHistory:(NSArray *)history;
- (NSMutableArray<NSNumber *> *)sort:(NSMutableArray<NSNumber *> *)source;
- (void)updateTimeStamp;

@end

