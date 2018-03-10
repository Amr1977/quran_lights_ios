//
//  NotificationsViewController.m
//  QuranGardens
//
//  Created by   Amr Lotfy on 3/9/18.
//  Copyright © 2018 Amr Lotfy. All rights reserved.
//

#import "NotificationsViewController.h"

@interface NotificationsViewController ()
@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;
@property (weak, nonatomic) IBOutlet UISegmentedControl *periodicSegmentControl;


@end

@implementation NotificationsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated {
    self.title = [NSString stringWithFormat:@"Notification time for Surat: %@", self.suraName];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onOkTapped {
    
    NSInteger repeat = 0;
    
    switch (self.periodicSegmentControl.selectedSegmentIndex) {
        case 0:
            repeat = 0;
            break;
       
            
        case 1:
            repeat = NSCalendarUnitDay;
            break;
            
        case 2:
            repeat = NSCalendarUnitWeekday;
            break;
            
        case 3:
            repeat = NSCalendarUnitMonth;
            break;
            
            
        default:
            repeat = 0;
            break;
    }
    
    [self.delegate notificationControllerDidSelectDate: self.datePicker.date withRepeatPeriod:repeat];
}

- (IBAction)onCancelTapped {
    [self.delegate notificationControllerDidCancel];
}

- (IBAction)onDeleteTapped {
    [self.delegate NotificationControllerDidChooseToDeleteNotification];
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
