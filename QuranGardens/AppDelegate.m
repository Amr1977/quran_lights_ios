////
//  AppDelegate.m
//  QuranGardens
//
//  Created by Amr Lotfy on 1/29/16.
//  Copyright © 2016 Amr Lotfy. All rights reserved.
//

#import "AppDelegate.h"
#import <BuddyBuildSDK/BuddyBuildSDK.h>
@import FirebaseAuth;

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [BuddyBuildSDK setup];
    [FIRApp configure];
    self.firebaseDatabaseReference = [[FIRDatabase database] reference];
    [self firebaseSignIn];
    
    
    return YES;
}

- (void)firebaseSignIn{
    [[FIRAuth auth]
     signInAnonymouslyWithCompletion:^(FIRUser *_Nullable user, NSError *_Nullable error) {
         if (!error) {
             self.isSignedIn = YES;
             NSLog(@"user.uid: %@",user.uid);
             self.userID = user.uid;
             [[NSNotificationCenter defaultCenter] postNotificationName:FireBaseSignInNotification object:self];
             [self loadHistory];
             
         } else {
             NSLog(@"Error signing in to firebase %@", error);
         }
         
     }];
}

- (void)refreshSura:(NSString *)suraName{
    NSNumber *date =  [NSNumber numberWithLongLong:[[NSDate new] timeIntervalSince1970]];
    [[[[[[[self.firebaseDatabaseReference child:@"users"] child: self.userID] child:@"Suras"] child:suraName] child:@"reviews"] childByAutoId] setValue: date];
}

- (void)refreshSura:(NSString *)suraName withDate:(NSNumber *)date {
    [[[[[[[self.firebaseDatabaseReference child:@"users"] child: self.userID] child:@"Suras"] child:suraName] child:@"reviews"] childByAutoId] setValue: date];
}

- (NSMutableArray<NSNumber *> *)sort:(NSMutableArray<NSNumber *> *)source{
    NSMutableArray<NSNumber *> * result = [source sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        NSNumber *first = (NSNumber *)a;
        NSNumber *second = (NSNumber *)b;
        NSComparisonResult result;
        if (first > second ) {
            result = NSOrderedDescending;
        } else {
            result = NSOrderedAscending;
        }
        return result;
    }].mutableCopy;
    
    return result;
}


- (void)loadHistory{
    
    self.fbRefreshHistory = @[].mutableCopy;
    
    [[[[self.firebaseDatabaseReference child:@"users"] child: self.userID] child:@"Suras"] observeSingleEventOfType:FIRDataEventTypeValue
                                                                                                          withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
                                                                                                              //NSLog(@"########## FIRDataSnapshot: %@",snapshot.value);
                                                                                                              NSMutableArray *suras = ((NSArray *)snapshot.value).mutableCopy;
                                                                                                              NSLog(@"########## suras[1]: %@",suras[1]);
                                                                                                              for (NSInteger index = 1; index <= 114; index++) {
                                                                                                                  NSDictionary *reviews = ((NSDictionary *)suras[index])[@"reviews"];
                                                                                                                  NSLog(@"Sura %d %@", index, reviews );
                                                                                                                  NSMutableArray *dates = [reviews allValues].mutableCopy;
                                                                                                                  dates = [self sort:dates];
                                                                                                                  [self.fbRefreshHistory addObject:dates];
                                                                                                              }
                                                                                                              
                                                                                                              [[NSNotificationCenter defaultCenter] postNotificationName:@"HistoryLoadedFromFireBase" object:self];
                                                                                                              
                                                                                                              
                                                                                                              //NSMutableArray *result = @[].mutableCopy;
                                                                                                              
//                                                                                                              for(NSDictionary *sura in suras){
//                                                                                                                  if ((([sura[@"archived"] boolValue]) || ([question[@"remove_2from_ui"] boolValue]))) {
//                                                                                                                      //NSLog(@"ignored a question %@", question);
//                                                                                                                      continue;
//                                                                                                                  } if(([question[@"landing_page"] boolValue])) {
//                                                                                                                      self.landingQuestion = question;
//                                                                                                                  } else {
//                                                                                                                      [result addObject:question];
//                                                                                                                  }
//                                                                                                              }
//                                                                                                              
//                                                                                                              self.questions = result;
                                                                                                              
                                                                                                              
                                                                                                              //NSLog(@"########## suras: %@",suras);
                                                                                                              //NSLog(@"###### [snapshot.value class] class %@", [snapshot.value class]);
                                                                                                          }
                                                                                                    withCancelBlock:^(NSError * _Nonnull error) {
                                                                                                        NSLog(@"%@", error.localizedDescription);
                                                                                                    }];
    
    //Listen for new questions in the Firebase database
//    self.refHandle = [[self.firebaseDatabaseReference child:@"questions"] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot) {
//        [self.questions addObject:snapshot.value];
//        for (NSDictionary *question in self.questions) {
//            if ([question objectForKey:QuestionTitleKeyEnglish] && [question objectForKey:QuestionBodyKeyEnglish]) {
//                NSLog(@"Question Title: %@ , body: %@",question[QuestionTitleKeyEnglish], question[QuestionBodyKeyEnglish]);
//            }
//        }
//    }];
}

    


- (void)refreshSura:(NSString *)suraName withHistory:(NSArray *)history{
    for (NSDate *date in history) {
        NSNumber *dateNumber =  [NSNumber numberWithLongLong:[date timeIntervalSince1970]];
        NSLog(@"attempting to send %@",dateNumber);
    [[[[[[[self.firebaseDatabaseReference child:@"users"] child: self.userID] child:@"Suras"] child:suraName] child:@"reviews"] childByAutoId] setValue: dateNumber];
    }
    
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

@end
