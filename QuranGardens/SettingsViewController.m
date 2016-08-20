//
//  SettingsViewController.m
//  QuranGardens
//
//  Created by Amr Lotfy on 8/19/16.
//  Copyright © 2016 Amr Lotfy. All rights reserved.
//

#import "SettingsViewController.h"

static NSString * const YearTimeUnit = @"y";
static NSString * const MonthTimeUnit = @"n";
static NSString * const WeekTimeUnit = @"w";
static NSString * const DayTimeUnit = @"d";
static NSString * const HourTimeUnit = @"h";
static NSString * const MinuteTimeUnit = @"m";
static NSString * const SecondTimeUnit = @"s";

static NSString * const DefaultTimeUnit = @"d";


@interface SettingsViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *sortTypeTableView;

/** Either a number of days or in the format [xy][xn][xw][xd][xh][xm][xs], where x is an integer, y: year, n: month, w: week, d: day, h: hour, m: minute, s: second*/
@property (strong, nonatomic) NSString *fadeTimeString;


@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.sortTypeTableView.delegate = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


+ (double)getTimeInSeconds:(NSString *)timeString{
    //TODO: Do it !

    return 0;
}
+ (NSString *)getTimeStringFromSeconds:(double)seconds{
    //TODO: Do it !
    
    return nil;
}





@end
