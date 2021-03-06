//
//  SettingsViewController.m
//  QuranGardens
//
//  Created by Amr Lotfy on 8/19/16.
//  Copyright © 2016 Amr Lotfy. All rights reserved.
//

#import "SettingsViewController.h"
#import "UIViewController+Gestures.h"
#import "NSString+Localization.h"
#import "AMRTools.h"
#import "SignupViewController.h"

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

@property (weak, nonatomic) IBOutlet UITextField *refreshPeriodText;
@property (weak, nonatomic) IBOutlet UISegmentedControl *sortDirectionSegments;
@property (weak, nonatomic) IBOutlet UITableView *sortTypeTableView;

@property (weak, nonatomic) IBOutlet UILabel *languageLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *languageSelector;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;



/** Either a number of days or in the format [xy][xn][xw][xd][xh][xm][xs], where x is an integer, y: year, n: month, w: week, d: day, h: hour, m: minute, s: second*/
//@property (strong, nonatomic) NSString *fadeTimeString;

@property (weak, nonatomic) IBOutlet UIView *content;


@property (weak, nonatomic) IBOutlet UILabel *VerseCountLabel;
@property (weak, nonatomic) IBOutlet UISwitch *verseCountSwitch;

@property (weak, nonatomic) IBOutlet UILabel *memorizsationMarkLabel;
@property (weak, nonatomic) IBOutlet UISwitch *memorizationMarkSwitch;

@property (weak, nonatomic) IBOutlet UILabel *suraIndexLabel;
@property (weak, nonatomic) IBOutlet UISwitch *suraIndexSwitch;

@property (weak, nonatomic) IBOutlet UILabel *refreshCountLabel;
@property (weak, nonatomic) IBOutlet UISwitch *refreshCountSwitch;

@property (weak, nonatomic) IBOutlet UILabel *characterCountLabel;
@property (weak, nonatomic) IBOutlet UISwitch *characterCountSwitch;

@property (weak, nonatomic) IBOutlet UILabel *elapsedDaysLabel;
@property (weak, nonatomic) IBOutlet UISwitch *elapsedDaysSwitch;


@property (weak, nonatomic) IBOutlet UILabel *singleTapToRefreshLabel;
@property (weak, nonatomic) IBOutlet UISwitch *singleTapToRefreshSwitch;
@property (weak, nonatomic) IBOutlet UILabel *soundLabel;
@property (weak, nonatomic) IBOutlet UISwitch *soundOptionSwitch;
@property (weak, nonatomic) IBOutlet UILabel *averageModeLabel;
@property (weak, nonatomic) IBOutlet UISwitch *averageModeSwitch;
@property (weak, nonatomic) IBOutlet UILabel *compactCellsOptionLabel;
@property (weak, nonatomic) IBOutlet UISwitch *compactCellsOptionSwith;

@end

@implementation SettingsViewController

static Settings* settingsCopy;

- (IBAction)onLanguageSelected:(UISegmentedControl *)sender {
    NSLog(@"language changed");
    [self toggleLanguage];
    
}

//cell content
- (IBAction)onSwitchTapped:(UISwitch *)sender {
    switch (sender.tag) {
        case 1:
            self.settings.showVerseCount = sender.isOn;
            break;
            
        case 2:
            self.settings.showMemorizationMark = sender.isOn;
            break;
        case 3:
            self.settings.showSuraIndex = sender.isOn;
            break;
            
        case 4:
            self.settings.showRefreshCount = sender.isOn;
            break;
        case 5:
            self.settings.showCharacterCount = sender.isOn;
            break;
            
        case 6:
            self.settings.showElapsedDaysCount = sender.isOn;
            break;
            
        case 7:
            self.settings.isFastRefreshOn = sender.isOn;
            break;
            
        case 8:
            self.settings.isSoundOn = sender.isOn;
            break;
        case 9:
            self.settings.isAverageModeOn = sender.isOn;
            break;
            
        case 10:
            self.settings.isCompactCellsOn = sender.isOn;
            break;
            
        default:
            break;
    }
    
    [self applySettings];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.sortTypeTableView.delegate = self;
    self.sortTypeTableView.dataSource = self;
    self.refreshPeriodText.delegate = self;
    self.view.userInteractionEnabled = YES;
    
    
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
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
     [self.refreshPeriodText resignFirstResponder];
    [self applySettings];
}

-(void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.scrollView.contentSize = self.content.frame.size;
}

- (void)backToCollection{
    //[self.navigationController popViewControllerAnimated: YES];
    //TODO do it!
    //[self.delegate hideSettingsView];
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
    
    [self.verseCountSwitch setOn:self.settings.showVerseCount];
    [self.memorizationMarkSwitch setOn:self.settings.showMemorizationMark];
    [self.suraIndexSwitch setOn:self.settings.showSuraIndex];
    [self.refreshCountSwitch setOn:self.settings.showRefreshCount];
    [self.characterCountSwitch setOn:self.settings.showCharacterCount];
    [self.elapsedDaysSwitch setOn:self.settings.showElapsedDaysCount];
    
    [self.singleTapToRefreshSwitch setOn:self.settings.isFastRefreshOn];
    [self.soundOptionSwitch setOn:self.settings.isSoundOn];
    [self.averageModeSwitch setOn:self.settings.isAverageModeOn];
    [self.compactCellsOptionSwith setOn:self.settings.isCompactCellsOn];

    //TODO localize added options labels
    
    for (UIView *subview in [self.content subviews]) {
        if ([subview isKindOfClass:[UILabel class]]) {
            UILabel *label = (UILabel *)subview;
            label.text = [label.text localize];
        }
    }
    
    NSLog(@"View size %@",NSStringFromCGRect(self.view.frame));
    NSLog(@"Screen size %@",NSStringFromCGRect([[UIScreen mainScreen] bounds]));
    
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
    //if (self.settings.sortType != indexPath.row) {
        NSIndexPath* selectedCellIndexPath = [NSIndexPath indexPathForRow:self.settings.sortType inSection:0];
        [tableView deselectRowAtIndexPath:selectedCellIndexPath animated:NO];
        //self.settingsAltered = YES;
        self.settings.sortType = indexPath.row;
        [self applySettings];
    //}
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
    
    int days = [self.refreshPeriodText.text integerValue];
    
    return days != 0;
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    NSCharacterSet* notDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    if ([string rangeOfCharacterFromSet:notDigits].location == NSNotFound)
    {
        return YES;
    }
    
    return NO;
}

- (void)textFieldDidEndEditing:(UITextField *)textField{
    NSLog(@"textFieldDidEndEditing");
    NSLog(@"fself.refreshPeriodText.text: %@", self.refreshPeriodText.text);
}

- (IBAction)didEndEditing:(id)sender{
    NSLog(@"didEndEditing");
    [self hideKeyBoard];
    [self applySettings];
}

- (IBAction)onSignUp:(id)sender {
    SignupViewController *signupViewController = [[SignupViewController alloc] init];
    [self.navigationController pushViewController:signupViewController animated:YES];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    NSLog(@"touchesBegan");
    [self hideKeyBoard];
}

- (void)applySettings{
    [self hideKeyBoard];
    NSInteger lightDays = self.refreshPeriodText.text.integerValue;
    if (lightDays > 0) {
        self.settings.fadeTime = lightDays * 24 * 60 * 60;
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        NSLog(@"SettingsViewController: delivering settings: %@",[self settings]);
        [self.delegate settingsViewController:self didChangeSettings:self.settings];
    });
}
- (IBAction)sortSegmentControlTapped:(id)sender {
    self.settings.descendingSort = (self.sortDirectionSegments.selectedSegmentIndex == 1);
    [self.delegate settingsViewController:self didChangeSettings:self.settings];
}

- (IBAction)onTapRateUs {
    NSString *appUrlString = @"https://itunes.apple.com/us/app/quran-lights/id1218872513?mt=8";
    NSURL *appURL = [[NSURL alloc] initWithString:appUrlString];
    if([[UIApplication sharedApplication] canOpenURL:appURL]) {
        [[UIApplication sharedApplication] openURL:appURL];
    }
}

- (IBAction)reviewUs {
    NSString *appUrlString = @"https://itunes.apple.com/us/app/quran-lights/id1218872513?action=write-review";
    NSURL *appURL = [[NSURL alloc] initWithString:appUrlString];
    if([[UIApplication sharedApplication] canOpenURL:appURL]) {
        [[UIApplication sharedApplication] openURL:appURL];
    }
}

- (IBAction)contactUs {
    [self sendEmailTo:@"amr.lotfy.othman@gmail.com" withSubject:@"Quran Lights Feedback" withBody:@""];
}

- (IBAction)shareApp {
    
    NSURL *url=[NSURL URLWithString:@"https://itunes.apple.com/us/app/quran-lights/id1218872513?mt=8"];
    NSString *textToShare = @"Quran Lights - A unique Quran performance measurement and visualization tool";
    NSArray *objectsToShare = @[textToShare, url];
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:objectsToShare applicationActivities:nil];
    
    NSArray *excludeActivities = @[UIActivityTypeAirDrop,
                                   UIActivityTypePrint,
                                   UIActivityTypeAssignToContact,
                                   UIActivityTypeSaveToCameraRoll,
                                   UIActivityTypeAddToReadingList,
                                   UIActivityTypePostToFlickr,
                                   UIActivityTypePostToVimeo];
    
    activityVC.excludedActivityTypes = excludeActivities;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        activityVC.popoverPresentationController.sourceView = self.view;
        activityVC.popoverPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width/2, self.view.bounds.size.height/4, 0, 0);
    }
    [self presentViewController:activityVC animated:true completion:nil];
}

-(void) sendEmailTo:(NSString *)to withSubject:(NSString *)subject withBody:(NSString *)body {
    NSString *mailString = [NSString stringWithFormat:@"mailto:?to=%@&subject=%@&body=%@",
                            [to stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding],
                            [subject stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding],
                            [body stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:mailString]];
}

- (IBAction)followUs:(id)sender {
     [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.facebook.com/QuranicLights/"]];
}

- (IBAction)openCharts:(id)sender {
    [self.delegate showCharts];
}

- (IBAction)showProfiles:(id)sender {
    [self.delegate showMembersView];
}

- (IBAction)showLoginView:(id)sender {
    [self.delegate showLoginView];
}


@end
