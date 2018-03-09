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
    [self.delegate notificationControllerDidSelectDate: self.datePicker.date];
}

- (IBAction)onCancelTapped {
    [self.delegate notificationControllerDidCancel];
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
