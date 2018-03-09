//
//  NotificationsViewController.h
//  QuranGardens
//
//  Created by   Amr Lotfy on 3/9/18.
//  Copyright © 2018 Amr Lotfy. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol NotificationControllerDelegate

- (void)notificationControllerDidCancel;
- (void)notificationControllerDidSelectDate:(NSDate *)notificationDate;

@end

@interface NotificationsViewController : UIViewController

@property (strong, nonatomic) NSDate *notificationDate;
@property (weak, nonatomic) id<NotificationControllerDelegate> delegate;
@property (strong, nonatomic)  NSString *suraName;

@end
