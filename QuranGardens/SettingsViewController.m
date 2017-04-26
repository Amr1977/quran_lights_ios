//
//  SettingsViewController.m
//  QuranGardens
//
//  Created by Amr Lotfy on 8/19/16.
//  Copyright © 2016 Amr Lotfy. All rights reserved.
//

#import "SettingsViewController.h"
#import "UIViewController+Gestures.h"
#import "LoginViewController.h"
#import "NSString+Localization.h"
#import "AMRTools.h"

static NSString * const YearTimeUnit = @"y";
static NSString * const MonthTimeUnit = @"n";
static NSString * const WeekTimeUnit = @"w";
static NSString * const DayTimeUnit = @"d";
static NSString * const HourTimeUnit = @"h";
static NSString * const MinuteTimeUnit = @"m";
static NSString * const SecondTimeUnit = @"s";

static NSString * const DefaultTimeUnit = @"d";

static CGFloat const DefaultCellHeight = 44;

@interface SettingsViewController () <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UIScrollView *scrollview;

@property (weak, nonatomic) IBOutlet UITextField *refreshPeriodText;
@property (weak, nonatomic) IBOutlet UISegmentedControl *sortDirectionSegments;
@property (weak, nonatomic) IBOutlet UITableView *sortTypeTableView;
@property (nonatomic) BOOL settingsAltered;

@property (weak, nonatomic) IBOutlet UILabel *languageLabel;

@property (weak, nonatomic) IBOutlet UISegmentedControl *languageSelector;


/** Either a number of days or in the format [xy][xn][xw][xd][xh][xm][xs], where x is an integer, y: year, n: month, w: week, d: day, h: hour, m: minute, s: second*/
//@property (strong, nonatomic) NSString *fadeTimeString;

@end

@implementation SettingsViewController

static Settings* settingsCopy;

- (IBAction)onLanguageSelected:(UISegmentedControl *)sender {
    NSLog(@"language changed");
    [self toggleLanguage];
    
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.sortTypeTableView.delegate = self;
    self.sortTypeTableView.dataSource = self;
    self.refreshPeriodText.delegate = self;
    self.view.userInteractionEnabled = YES;
    self.scrollview.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    
    self.sortTypeTableView.layer.borderWidth = 1.0;
    self.sortTypeTableView.layer.borderColor = [UIColor grayColor].CGColor;
    CGRect frame = self.sortTypeTableView.frame;
    frame.size.height = DefaultCellHeight * ([[Settings sortTypeList] count] - 1);
    self.sortTypeTableView.frame = frame;

    [self addSwipeHandlerToView:self.view direction:@"right" handler:@selector(backToCollection)];
    
    if ([AMRTools isRTL]) {
        self.languageLabel.text = [@"Language" localize];
        self.languageSelector.selectedSegmentIndex = 1;
    }
    
    //self.refreshPeriodText.keyboardType = UIKeyboardTypeNumberPad;
}

- (void)backToCollection{
    [self.navigationController popViewControllerAnimated: YES];
    
}

- (void)viewDidLayoutSubviews{
    self.scrollview.frame = self.view.frame;
    //self.scrollview.backgroundColor = [UIColor greenColor];
    self.scrollview.frame = CGRectMake(0, 50, self.view.frame.size.width, self.view.frame.size.height);
    self.scrollview.contentSize = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height + 10).size;
}

-(void)hideKeyBoard {
    NSLog(@"Hide KB");
    [self.refreshPeriodText resignFirstResponder];
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
    settingsCopy = [settings copy];
    
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
    cell.textLabel.text = [[Settings sortTypeList][indexPath.row] localize];
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [[Settings sortTypeList] count];
}

- (void)toggleLanguage{
    
    UIAlertController *confirmation = [UIAlertController alertControllerWithTitle:[@"Language Change" localize]
                                                                          message:[@"App needs to close to change current app locale, you will need to relaunch app yourself." localize]
                                                                   preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* ok = [UIAlertAction actionWithTitle:[@"Ok" localize] style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction * action) {
                                                   [AMRTools isRTL] ? [AMRTools setLocaleEnglish] : [AMRTools setLocaleArabic];
                                                   exit(0);
                                               }
                         ];
    
    UIAlertAction* cancel = [UIAlertAction actionWithTitle:[@"Cancel" localize] style:UIAlertActionStyleDefault
                                                   handler:nil];
    
    [confirmation addAction:ok];
    [confirmation addAction:cancel];
    
    [self presentViewController:confirmation animated:YES completion:nil];
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

- (IBAction)didEndEditing:(id)sender{
    NSLog(@"didEndEditing");
    [self hideKeyBoard];
}

- (IBAction)onSignUp:(id)sender {
    LoginViewController *loginviewController = [[UIStoryboard storyboardWithName:@"Login" bundle:nil] instantiateViewControllerWithIdentifier:@"LoginViewController"];
    
    [self presentViewController:loginviewController animated:YES completion:nil];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    NSLog(@"touchesBegan");
    [self hideKeyBoard];
}

- (void)dealloc{
    self.settings.fadeTime = [self.refreshPeriodText.text integerValue] * 24 * 60 * 60;
    self.settings.descendingSort = (self.sortDirectionSegments.selectedSegmentIndex == 1);
    self.settings.sortType = self.sortTypeTableView.indexPathForSelectedRow.row;
    NSLog(@"SettingsViewController: delivering settings: %@",[self settings]);
    NSLog(@"Settings copy %@", settingsCopy);
    if (![self.settings isEqual:settingsCopy]) {
        [self.delegate settingsViewController:self didChangeSettings:self.settings];
    } else {
        NSLog(@"Nothing changed");
    }
    
}

@end
