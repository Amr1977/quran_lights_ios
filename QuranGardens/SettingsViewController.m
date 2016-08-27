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

@property (weak, nonatomic) IBOutlet UITextField *refreshPeriodText;
@property (weak, nonatomic) IBOutlet UISegmentedControl *sortDirectionSegments;
@property (weak, nonatomic) IBOutlet UITableView *sortTypeTableView;
@property (nonatomic) BOOL settingsAltered;

/** Either a number of days or in the format [xy][xn][xw][xd][xh][xm][xs], where x is an integer, y: year, n: month, w: week, d: day, h: hour, m: minute, s: second*/
//@property (strong, nonatomic) NSString *fadeTimeString;

@end

@implementation SettingsViewController

static Settings* settingsCopy;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.sortTypeTableView.delegate = self;
    self.sortTypeTableView.dataSource = self;
    self.refreshPeriodText.delegate = self;
    
    self.refreshPeriodText.keyboardType = UIKeyboardTypeNumberPad;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self updateUI];
}

- (void)updateUI{
    //fade time
    NSUInteger days;
    days = self.settings.fadeTime / (24 * 60 * 60);
    NSLog(@"fade time in days: %lu", days);
    if (days) {
        self.refreshPeriodText.text = [[[NSNumber numberWithUnsignedInteger:days] stringValue] copy];
        NSLog(@"self.refreshPeriodText.text: %@", self.refreshPeriodText.text);
    } else {
        NSLog(@"days = 0");
    }
    
    //sort type
    NSIndexPath* selectedCellIndexPath = [NSIndexPath indexPathForRow:self.settings.sortType inSection:0];
    [self.sortTypeTableView selectRowAtIndexPath:selectedCellIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    
    //Sort direction
    self.sortDirectionSegments.selectedSegmentIndex = self.settings.descendingSort ? 1 : 0;
    [self.sortDirectionSegments sendActionsForControlEvents:UIControlEventValueChanged];
}

- (void)setSettings:(Settings *)settings{
    _settings = settings;
    settingsCopy = settings;
    
    [self updateUI];
    
    NSLog(@"SettingsViewController: received settings: %@",[self settings]);
}

+ (double)getTimeInSeconds:(NSString *)timeString{
    //TODO: Do it !

    return 0;
}
+ (NSString *)getTimeStringFromSeconds:(double)seconds{
    //TODO: Do it !
    
    return nil;
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"sortTypeCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    cell.textLabel.text = [Settings sortTypeList][indexPath.row];
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [[Settings sortTypeList] count];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    //TODO: find sort type by indexing string in cell text in sortTypeList in Settings class
    if (self.settings.sortType != indexPath.row) {
        NSIndexPath* selectedCellIndexPath = [NSIndexPath indexPathForRow:self.settings.sortType inSection:0];
        [tableView deselectRowAtIndexPath:selectedCellIndexPath animated:NO];
        self.settingsAltered = YES;
        self.settings.sortType = indexPath.row;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.settings.sortType != indexPath.row) {
        cell.selected = NO;
    }
}

#pragma mark - Apply

- (IBAction)apply:(id)sender{
    self.settings.fadeTime = [self.refreshPeriodText.text integerValue] * 24 * 60 * 60;
    self.settings.descendingSort = (self.sortDirectionSegments.selectedSegmentIndex == 1);
    self.settings.sortType = self.sortTypeTableView.indexPathForSelectedRow.row;
    NSLog(@"SettingsViewController: delivering settings: %@",[self settings]);
    [self.delegate settingsViewController:self didChangeSettings:self.settings];
}


- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    NSLog(@"textFieldShouldBeginEditing");
    NSLog(@"fself.refreshPeriodText.text: %@", self.refreshPeriodText.text);
    textField.backgroundColor = [UIColor colorWithRed:220.0f/255.0f green:220.0f/255.0f blue:220.0f/255.0f alpha:1.0f];
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField{
    NSLog(@"textFieldDidBeginEditing");
    NSLog(@"fself.refreshPeriodText.text: %@", self.refreshPeriodText.text);
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField{
    NSLog(@"textFieldShouldEndEditing");
    NSLog(@"fself.refreshPeriodText.text: %@", self.refreshPeriodText.text);
    textField.backgroundColor = [UIColor whiteColor];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField{
    NSLog(@"textFieldDidEndEditing");
    NSLog(@"fself.refreshPeriodText.text: %@", self.refreshPeriodText.text);
}

@end
