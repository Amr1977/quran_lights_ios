//
//  QuranGardensViewController.m
//  QuranGardens
//
//  Created by Amr Lotfy on 1/29/16.
//  Copyright © 2016 Amr Lotfy. All rights reserved.
//

#import "QuranGardensViewController.h"
#import "SuraViewCell.h"
#import "Sura.h"
#import "PeriodicTaskManager.h"
#import <QuartzCore/CAAnimation.h>
#import "Settings.h"
#import "Statistics.h"
#import "AppDelegate.h"
#import "AMRTools.h"
#import "CubicLineChartViewController.h"
#import "NSString+Localization.h"
#import "PiePolylineChartViewController.h"
#import "PrayTime.h"
#import "UsersViewController.h"
#import "SignupViewController.h"
#import "MBProgressHUD.h"
#import "UIViewController+Toast.h"
#import "NotificationsViewController.h"
@import AVFoundation;
@import Charts;
@import GoogleMobileAds;



CGFloat const CellHeight = 80;
CGFloat const CellWidth = 120;


NSInteger const RefreshPeriod = 300; // refresh each 5 minutes;
NSInteger const RecentMemorizedMarkDays = 10;

static NSString *const ShowHelpScreenKey = @"Show_help_screen";
static NSString *const ReversedSortOrderOptionKey = @"reversed_sort_order";
static NSString *const SorterTypeOptionKey = @"sorter_type";

@interface QuranGardensViewController () <GADBannerViewDelegate, NotificationControllerDelegate>


@property (strong, nonatomic) IBOutlet UIView *bottomBar;
@property (weak, nonatomic) IBOutlet UIView *settingsView;
@property (weak, nonatomic) IBOutlet UIView *settingsDismissDetector;



@property (strong, nonatomic) PeriodicTaskManager *periodicTaskManager;
@property (strong, nonatomic) UIAlertController *menu;
@property (strong, nonatomic) UIAlertController *suraMenu;
@property (strong, nonatomic) PeriodicTask *selectedTask;
@property (nonatomic) BOOL showHelpScreen;
@property (nonatomic) BOOL menuOpened;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (nonatomic) BOOL reversedSortOrder;
@property (nonatomic, assign) SorterType sortType;

@property (strong,nonatomic) UIImage *sunImage;
@property (strong,nonatomic) UIImage *recordImage;

@property (strong, nonatomic) Statistics* statistics;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *score;

@property (strong, nonatomic) IBOutlet UIButton *moshafOrderButton;
@property (strong, nonatomic) IBOutlet UIButton *lightSortButton;
@property (strong, nonatomic) IBOutlet UIButton *charCountSortButton;
@property (strong, nonatomic) IBOutlet UIButton *wordCountSortButton;
@property (strong, nonatomic) IBOutlet UIButton *verseCountSortButton;
@property (strong, nonatomic) IBOutlet UIButton *refreshCountSortButton;//UIButton *scoreButton
@property (strong, nonatomic) IBOutlet UIButton *revalationOrderSortButton;

@property (nonatomic) __block NSInteger hideCounter;
@property (nonatomic) __block Boolean overviewMode;
@property (nonatomic) NSIndexPath* selectedCell;

@property (nonatomic) BOOL isLightCalculationBasedOnAverage;
@property(nonatomic, strong) GADBannerView *bannerView;//GADBannerView

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *collectionViewHeightConstraint;

@property (strong, nonatomic) NotificationsViewController *notificationsViewController;

@property (weak, nonatomic) IBOutlet UIView *rightEdgeSwipeDetector;

@property (weak, nonatomic) IBOutlet UIView *leftEdgeSwipeDetector;

@property (strong, nonatomic) SettingsViewController *settingsViewController;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *settingsViewHeightConstraints;




@end

@implementation QuranGardensViewController

UIImage *barButtonImage;
UIImage *barButtonImageActive;
UIImage *chartButtonImage;
UIButton *scoreButton;
CGFloat CellSmallHeight = 40;
CGFloat CellSmallWidth = 40;
BOOL updateInProgress;

static NSMutableDictionary *operations;

AppDelegate *delegate;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.overviewMode = [[NSUserDefaults standardUserDefaults] boolForKey:@"overviewMode"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onFirebaseWillStartSync) name:@"WillStartUpdatedFromFireBase" object:nil];
    
    delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    [self setModalPresentationStyle:UIModalPresentationCurrentContext];
    
    operations = @{}.mutableCopy;
    barButtonImage = [[UIImage imageNamed:@"sun.jpg"] imageWithRenderingMode: UIImageRenderingModeAlwaysTemplate];
    barButtonImageActive = [[UIImage imageNamed:@"sun.jpg"] imageWithRenderingMode: UIImageRenderingModeAlwaysTemplate];
    
    chartButtonImage = [[UIImage imageNamed:@"charts3"] imageWithRenderingMode: UIImageRenderingModeAlwaysTemplate];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:@"UpdatedFromFireBase" object:nil];
    
    self.sunImage = [UIImage imageNamed:@"sun.jpg"];
    self.recordImage = [UIImage imageNamed:@"record.png"];
    
    [self handleDeviceOrientation];
    
    [self setNavigationBar];
    
    [self initTaskManager];
    
    [self setupCollectionView];
    
    [self applyCurrentSort];
    
    [self AddPeriodicRefresh];
    
    //TODO: make singleton of data source to avoid this
    self.statistics = [[Statistics alloc] initWithDataSource:self.periodicTaskManager.dataSource];
    currentKhatma = [self.periodicTaskManager getCurrentKhatmaNumber];
    
    NSLog(@"Memorized %ld of total %ld", (long)[self.statistics memorizedScore], (long)[Statistics allSurasScore]);
    
    self.bottomBar.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.bottomBar];
    
    self.collectionView.layer.shouldRasterize = YES;
    
    self.bottomBar.layer.shouldRasterize = YES;
    
    self.bannerView = [[GADBannerView alloc] initWithAdSize: (([[UIDevice currentDevice] orientation] ==  UIDeviceOrientationPortrait) ? kGADAdSizeSmartBannerPortrait : kGADAdSizeSmartBannerLandscape)];
    self.bannerView.adUnitID = @"ca-app-pub-3940256099942544/2934735716";
    self.bannerView.rootViewController = self;
    self.bannerView.layer.zPosition = 1000;
    
    CGRect adFrame =  self.bannerView.frame;
    adFrame.size.width = self.view.frame.size.width;
    adFrame.origin.x = 0;
    adFrame.origin.y = self.view.frame.size.height;
    
    [self addSwipeHandlerToView:self.leftEdgeSwipeDetector direction:@"right" handler:@selector(showLeftMenu)];
    [self addSwipeHandlerToView:self.rightEdgeSwipeDetector direction:@"left" handler:@selector(showRightMenu)];
    
    
    //self.bannerView.frame = adFrame;
    
    //self.bannerView.delegate = self;
    //[self.view addSubview:self.bannerView];
    
   // [self addSwipeHandlerToView:self.bannerView direction:@"RIGHT" handler:@selector(hideAds)];
    //GADRequest *request = [GADRequest request];
    
    //[self.bannerView loadRequest:request];
    //[self positionBannerViewFullWidthAtBottomOfView: self.bannerView];
    
}

BOOL appearedBefore;

- (void)initSettingsView{
    [self.settingsView setHidden:YES];
    
    [self addSwipeHandlerToView:self.settingsView direction:@"left" handler:@selector(HideSettingsView)];
    [self addSwipeHandlerToView:self.settingsDismissDetector direction:@"tap" handler:@selector(HideSettingsView)];
    [self addSwipeHandlerToView:self.settingsDismissDetector direction:@"right" handler:@selector(HideSettingsView)];
    [self addSwipeHandlerToView:self.settingsDismissDetector direction:@"left" handler:@selector(HideSettingsView)];
    [self addSwipeHandlerToView:self.settingsDismissDetector direction:@"up" handler:@selector(HideSettingsView)];
    [self addSwipeHandlerToView:self.settingsDismissDetector direction:@"down" handler:@selector(HideSettingsView)];

    self.settingsViewController = [[SettingsViewController alloc] init];
    self.settingsViewController.settings = [self.periodicTaskManager.dataSource.settings copy];
    self.settingsViewController.delegate = self;
    
    
    [self addChildViewController:self.settingsViewController];
    
    [self.settingsViewController.view setFrame:CGRectMake(0.0f, 0.0f, self.settingsView.frame.size.width, self.settingsView.frame.size.height)];
    [self.settingsView addSubview:self.settingsViewController.view];
    
    [self.settingsViewController didMoveToParentViewController:self];
    
    self.settingsViewHeightConstraints.constant = -64.0 ;
    
    [self.settingsViewController didMoveToParentViewController:self];
    
    //TODO: Add shadow
}

- (void)showLeftMenu {
    NSLog(@"Show left menu.");
    [self showSettingsView];
}

- (void)showRightMenu {
    NSLog(@"Show Right menu.");
}


- (NSInteger)getMarkedSuraIndex {
    NSInteger result = [[NSUserDefaults standardUserDefaults] integerForKey:@"marked_sura_index"];
    return result;
}

- (void)setMarkedSuraIndex:(NSInteger)index{
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:@"marked_sura_index"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.collectionView reloadData];
}

-(void)hideAds {
    [UIView animateWithDuration:0.5 animations:^{
        
        CGRect adFrame =  self.bannerView.frame;
        adFrame.origin.y = self.view.frame.size.height;
        self.bannerView.frame = adFrame;
        
        
        CGRect cFrame = self.collectionView.frame;
        cFrame.size.height += adFrame.size.height;
        self.collectionView.frame = cFrame;
        
        self.collectionViewHeightConstraint.constant = 0;
        [self.collectionView reloadData];
    }];
    
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInt
                               duration:(NSTimeInterval)duration {
    self.bannerView.adSize = (([[UIDevice currentDevice] orientation] ==  UIDeviceOrientationPortrait) ? kGADAdSizeSmartBannerPortrait : kGADAdSizeSmartBannerLandscape);
}

BOOL gotFirstAd = NO;

- (void)adViewDidReceiveAd:(GADBannerView *)adView {
    NSLog(@"adViewDidReceiveAd %@", adView);
    if (!gotFirstAd) {
        gotFirstAd = YES;
        [UIView animateWithDuration:0.5 animations:^{
            CGRect adFrame =  self.bannerView.frame;
            adFrame.origin.y = self.view.frame.size.height - adFrame.size.height;
            self.bannerView.frame = adFrame;
            
            CGRect cFrame = self.collectionView.frame;
            cFrame.size.height -= adFrame.size.height;
            self.collectionView.frame = cFrame;
            
            self.collectionViewHeightConstraint.constant = -adFrame.size.height;
        }];
    }
    
}

#pragma mark - ad view positioning

- (void)positionBannerViewFullWidthAtBottomOfSafeArea:(UIView *_Nonnull)bannerView NS_AVAILABLE_IOS(11.0) {
    // Position the banner. Stick it to the bottom of the Safe Area.
    // Make it constrained to the edges of the safe area.
    UILayoutGuide *guide = self.view.safeAreaLayoutGuide;
    
    [NSLayoutConstraint activateConstraints:@[
                                              [guide.leftAnchor constraintEqualToAnchor:bannerView.leftAnchor],
                                              [guide.rightAnchor constraintEqualToAnchor:bannerView.rightAnchor],
                                              [self.collectionView.bottomAnchor constraintEqualToAnchor:bannerView.topAnchor]
                                              ]];
}

- (void)positionBannerViewFullWidthAtBottomOfView:(UIView *_Nonnull)bannerView {
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:bannerView
                                                          attribute:NSLayoutAttributeLeading
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeLeading
                                                         multiplier:1
                                                           constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:bannerView
                                                          attribute:NSLayoutAttributeTrailing
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeTrailing
                                                         multiplier:1
                                                           constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:bannerView
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.collectionView
                                                          attribute:NSLayoutAttributeBottom
                                                         multiplier:1
                                                           constant:0]];
}

#pragma mark - view positioning



- (void)onFirebaseWillStartSync {
    if (updateInProgress) {
        return;
    }
    updateInProgress = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"onFirebaseWillStartSync: Showin HUD");
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    });
}

- (void)usersMenu{
    [self.navigationController pushViewController:[[UsersViewController alloc] init] animated:YES];
}

- (void)hideSortBar {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.hideCounter -= 1;
        NSLog(@"hide sort bar called, hide counter %ld", (long)self.hideCounter);
        if (self.hideCounter <= 0) {
            self.hideCounter = 0;
//            if (self.overviewMode) {
//                return;
//            }
            NSLog(@"hiding sort bar");
            [self.bottomBar setHidden:YES];
            self.bottomBar.frame =  CGRectMake(0, self.collectionView.frame.size.height + self.collectionView.frame.origin.y, self.collectionView.frame.size.width, 0);
            
        }
    });
}

- (void)showSortBar {
    self.hideCounter += 1;
    NSLog(@"show sort bar called, hide counter %ld", (long)self.hideCounter);
    [self.bottomBar setHidden:NO];
    [UIView animateWithDuration:1 animations:^{
        self.bottomBar.frame =  CGRectMake(0, self.collectionView.frame.size.height  + self.collectionView.frame.origin.y - 50, self.collectionView.frame.size.width, 50);
    } completion:^(BOOL finished) {
        [self hideSortBar];
    }];
    
    
    
}

- (void)openFacePage {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.facebook.com/QuranicLights/"]];
}
    
- (IBAction)onScoreTabbed:(id)sender {
    if(!updateInProgress) {
        [self usersMenu];
    }
}

NSInteger currentKhatma = 0;


#pragma mark - Navigation items, score

- (void)refreshScoreButton{
    NSInteger todayScore =  [self.statistics todayScore];
    NSInteger yesterdayScore = [self.statistics yesterdayScore];
    //NSInteger total = [self.statistics totalScore];
    
    //NSString *totalString = [AMRTools abbreviateNumber:total withDecimal:1];
    NSString *todayString = [AMRTools abbreviateNumber:todayScore withDecimal:3];
    
    if (scoreButton == nil) {
        CGRect imageFrame = CGRectMake(0, 0, 40, 30);
        
        scoreButton = [[UIButton alloc] initWithFrame:imageFrame];
        [scoreButton setTitle:@"💹" forState:UIControlStateNormal];
        
        [scoreButton addTarget:self
                        action:@selector(showCharts)
              forControlEvents:UIControlEventTouchUpInside];
        
        [scoreButton setShowsTouchWhenHighlighted:YES];//👤
        
        UIBarButtonItem *chartsItem = [[UIBarButtonItem alloc] initWithCustomView:scoreButton];
        
        self.navigationItem.leftBarButtonItems = @[chartsItem, self.score];
    }
    
//    [scoreButton setTitle:[NSString stringWithFormat:@"%@/%@",totalString, todayString]
//                 forState:UIControlStateNormal];
    
    
    
    NSInteger newKhatma = [self.periodicTaskManager getCurrentKhatmaNumber];
    
    if (newKhatma > currentKhatma) {
        NSLog(@"Congratulations, A Khatma is Completed");
        [self showMessageAlertViewWithTitle:[@"Congratulations!" localize] message:[@"You have completed a Khatma 🙂" localize]];
        currentKhatma = newKhatma;
    }
    
    
    self.score.title = [NSString stringWithFormat:@"%@", todayString];
    
    
    UIColor *color = ((todayScore > yesterdayScore)? [UIColor greenColor] : [UIColor whiteColor]);
    [scoreButton setTintColor:color];
    self.score.tintColor = color;
}

- (void)showMessageAlertViewWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                  message:message
                                                           preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* okAction = [UIAlertAction actionWithTitle:[@"Ok" localize]
                                                           style:UIAlertActionStyleDefault
                                                         handler:nil];
    
    
    
    [alert addAction:okAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)initTaskManager{
    self.periodicTaskManager = [[PeriodicTaskManager alloc] init];
}

- (void)setNavigationBar{
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"sunrise.jpg"] forBarMetrics:UIBarMetricsDefault];
    [self setMenuButton];
}

- (void)handleDeviceOrientation{
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(orientationChanged:)
     name:UIDeviceOrientationDidChangeNotification
     object:[UIDevice currentDevice]];
}

- (void)startupHelpAlert{
    if ([self showHelpScreen]) {
        [self howItWorks];
    }
}

- (NSMutableArray<NSNumber *> *)mapDatesToNumbers:(NSArray<NSDate *>*)source{
    NSMutableArray<NSNumber *> *result = @[].mutableCopy;
    
    for (NSDate *date in source) {
        NSNumber *number = [NSNumber numberWithLongLong:[date timeIntervalSince1970]];
        [result addObject:number];
    }
    
    return result;
}

- (NSMutableArray<NSDate *> *)mapNumbersToDates:(NSArray<NSNumber *>*)source{
    NSMutableArray<NSDate *> *result = @[].mutableCopy;
    
    for (NSNumber *number in source) {
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:number.doubleValue];
        [result addObject:date];
    }
    
    return result;
}


- (void)mergeLocal:(NSMutableArray<NSNumber *> *)local withRemote:(NSMutableArray<NSNumber *> *)remote{
    
}

UIButton *settingsButton;
UIButton *fbButton;
UIButton *overviewButton;
UIButton *lightCalculationMethodButton;
UIButton *soundToggle;
UIButton *toggleSingleTouchRefreshModeButton;

#pragma mark - Navigation bar items
- (void)setMenuButton{

    CGRect imageFrame = CGRectMake(0, 0, 30, 30);
    
    settingsButton = [[UIButton alloc] initWithFrame:imageFrame];
    [settingsButton setTitle:@"⚙️" forState:UIControlStateNormal];
    //settingsButton.tintColor = [UIColor yellowColor];
    //[settingsButton setBackgroundImage:barButtonImage forState:UIControlStateNormal];
    settingsButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];
    [settingsButton addTarget:self
                   action:@selector(settings)
         forControlEvents:UIControlEventTouchUpInside];
    
    [settingsButton setShowsTouchWhenHighlighted:YES];
    UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithCustomView:settingsButton];

    //link t quran-lights.firebaseapp.com
    fbButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 27, 27)];
    //[settingsButton setTitle:@"S" forState:UIControlStateNormal];
    //settingsButton.tintColor = [UIColor yellowColor];
    //[fbButton setBackgroundImage:[UIImage imageNamed:@"fb"] forState:UIControlStateNormal];
    //fbButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];
    [fbButton setTitle:@"ℹ️" forState:UIControlStateNormal];
    [fbButton addTarget:self
                       action:@selector(openFacePage)
             forControlEvents:UIControlEventTouchUpInside];
    
    [fbButton setShowsTouchWhenHighlighted:YES];
    UIBarButtonItem *fbItem = [[UIBarButtonItem alloc] initWithCustomView:fbButton];
    
    //overview mode
    overviewButton = [[UIButton alloc] initWithFrame:imageFrame];
    [overviewButton setTitle:@"↕️" forState:UIControlStateNormal];//🔍🔇🔈
    [overviewButton addTarget:self
                 action:@selector(toggleOverView)
       forControlEvents:UIControlEventTouchUpInside];
    
    [overviewButton setShowsTouchWhenHighlighted:YES];
    UIBarButtonItem *overviewItem = [[UIBarButtonItem alloc] initWithCustomView:overviewButton];
    
    
    //overview mode
    lightCalculationMethodButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    lightCalculationMethodButton.layer.cornerRadius = 10.0;
    [lightCalculationMethodButton setTitle:@"🔆" forState:UIControlStateNormal];//🔍🔇🔈
    [lightCalculationMethodButton addTarget:self
                       action:@selector(toggleLightCalculationMethod)
             forControlEvents:UIControlEventTouchUpInside];
    
    [lightCalculationMethodButton setShowsTouchWhenHighlighted:YES];
    UIBarButtonItem *lightCalculationMethodItem = [[UIBarButtonItem alloc] initWithCustomView:lightCalculationMethodButton];
    
    
    //sound on/off
    //overview mode
    soundToggle = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    soundToggle.layer.cornerRadius = 10.0;
    BOOL soundOffFlag = [[NSUserDefaults standardUserDefaults] boolForKey:@"SoundOffFlag"];
    [soundToggle setTitle:soundOffFlag ? @"🔇" : @"🔈" forState:UIControlStateNormal];//🔍🔇🔈
    [soundToggle addTarget:self
                                     action:@selector(toggleSound)
                           forControlEvents:UIControlEventTouchUpInside];
    
    [soundToggle setShowsTouchWhenHighlighted:YES];
    UIBarButtonItem *soundToggleItem = [[UIBarButtonItem alloc] initWithCustomView:soundToggle];
    
    UIButton *signInButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    signInButton.layer.cornerRadius = 10.0;
    
    [signInButton setTitle:@"👥" forState:UIControlStateNormal];
    [signInButton addTarget:self
                     action:@selector(showLoginView)
           forControlEvents:UIControlEventTouchUpInside];
    
    [signInButton setShowsTouchWhenHighlighted:YES];
    UIBarButtonItem *signInItem = [[UIBarButtonItem alloc] initWithCustomView:signInButton];
    
    toggleSingleTouchRefreshModeButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    toggleSingleTouchRefreshModeButton.layer.cornerRadius = 10.0;
    BOOL singleTouch = [[NSUserDefaults standardUserDefaults] boolForKey:@"single_touch_refresh_flag"];
    [toggleSingleTouchRefreshModeButton setTitle:singleTouch ? @"⚡️" : @"🌻" forState:UIControlStateNormal];
    
    [toggleSingleTouchRefreshModeButton addTarget:self
                     action:@selector(switchSingleTouchRefresh)
           forControlEvents:UIControlEventTouchUpInside];
    
    [toggleSingleTouchRefreshModeButton setShowsTouchWhenHighlighted:YES];
    UIBarButtonItem *singleTouchRefreshItem = [[UIBarButtonItem alloc] initWithCustomView:toggleSingleTouchRefreshModeButton];
    
    self.navigationItem.rightBarButtonItems = @[menuButton,fbItem, overviewItem, lightCalculationMethodItem, soundToggleItem, singleTouchRefreshItem, signInItem];
    
    [self setSortButtons];
}

- (void)switchSingleTouchRefresh {
    BOOL singleTouchOn = [[NSUserDefaults standardUserDefaults] boolForKey:@"single_touch_refresh_flag"];
    singleTouchOn = !singleTouchOn;
    [[NSUserDefaults standardUserDefaults] setBool:singleTouchOn forKey:@"single_touch_refresh_flag"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [toggleSingleTouchRefreshModeButton setTitle:singleTouchOn ? @"⚡️" : @"🌻" forState:UIControlStateNormal];
    if(singleTouchOn) {
        [self toast:@"Fast Refresh On"];
    } else {
        [self toast:@"Fast Refresh Off"];
    }
}

- (void)showLoginView{
    SignupViewController *signupViewController = [[SignupViewController alloc] init];
    [self.navigationController pushViewController:signupViewController animated:YES];
}


- (void)toggleSound{
    BOOL soundOff = ![[NSUserDefaults standardUserDefaults] boolForKey:@"SoundOffFlag"];
    [[NSUserDefaults standardUserDefaults] setBool:soundOff forKey:@"SoundOffFlag"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [soundToggle setTitle:soundOff ? @"🔇" : @"🔈" forState:UIControlStateNormal];
    if(soundOff) {
        [self toast:@"Sound Off"];
    } else {
        [self toast:@"Sound On"];
    }
    
}

- (void)toggleLightCalculationMethod {
    self.isLightCalculationBasedOnAverage = !self.isLightCalculationBasedOnAverage;
    
    if (self.isLightCalculationBasedOnAverage) {
        [lightCalculationMethodButton setBackgroundColor:[[UIColor greenColor] colorWithAlphaComponent:0.5]];
        [self toast:@"Average inter-refresh Light State."];
    } else {
        [lightCalculationMethodButton setBackgroundColor:[UIColor clearColor]];
        [self toast:@"Last Refresh Light State."];
    }
    
    [[self collectionView] reloadData];
}

- (void)setSortButtons{
    //sort by normal order

    [self.moshafOrderButton setTitle:@"B" forState:UIControlStateNormal];
    
    
    [self.moshafOrderButton setBackgroundImage:barButtonImage forState:UIControlStateNormal];
    [self.moshafOrderButton addTarget:self
                               action:@selector(fastAccessNormalSuraOrderSort)
                     forControlEvents:UIControlEventTouchUpInside];
    
    [self.moshafOrderButton setShowsTouchWhenHighlighted:YES];
    [self.moshafOrderButton setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
    
    
    //sort by light strength
    [self.lightSortButton setTitle:@"L" forState:UIControlStateNormal];
    
    [self.lightSortButton setBackgroundImage:barButtonImage forState:UIControlStateNormal];
    [self.lightSortButton addTarget:self
                             action:@selector(fastAccessWeakerFirstSuraFirstSort)
                   forControlEvents:UIControlEventTouchUpInside];
    
    [self.lightSortButton setShowsTouchWhenHighlighted:YES];
    [self.lightSortButton setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
    
    //sort by character count
    [self.charCountSortButton setTitle:@"C" forState:UIControlStateNormal];
    
    [self.charCountSortButton setBackgroundImage:barButtonImage forState:UIControlStateNormal];
    [self.charCountSortButton addTarget:self
                                 action:@selector(fastAccessCharCountSuraSort)
                       forControlEvents:UIControlEventTouchUpInside];
    
    [self.charCountSortButton setShowsTouchWhenHighlighted:YES];
    [self.charCountSortButton setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
    
    
    //sort by word count
    [self.wordCountSortButton setTitle:@"W" forState:UIControlStateNormal];
    
    [self.wordCountSortButton setBackgroundImage:barButtonImage forState:UIControlStateNormal];
    [self.wordCountSortButton addTarget:self
                                 action:@selector(fastAccessWordCountSuraSort)
                       forControlEvents:UIControlEventTouchUpInside];
    
    [self.wordCountSortButton setShowsTouchWhenHighlighted:YES];
    [self.wordCountSortButton setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
    
    
    //sort by refresh count
    [self.refreshCountSortButton setTitle:@"F" forState:UIControlStateNormal];
    
    [self.refreshCountSortButton setBackgroundImage:barButtonImage forState:UIControlStateNormal];
    [self.refreshCountSortButton addTarget:self
                                    action:@selector(fastAccessRefreshCountSuraSort)
                          forControlEvents:UIControlEventTouchUpInside];
    
    [self.refreshCountSortButton setShowsTouchWhenHighlighted:YES];
    [self.refreshCountSortButton setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
    
    //sort by revalation order
    [self.revalationOrderSortButton setTitle:@"R" forState:UIControlStateNormal];
    
    [self.revalationOrderSortButton setBackgroundImage:barButtonImage forState:UIControlStateNormal];
    [self.revalationOrderSortButton addTarget:self
                                       action:@selector(fastAccessRevalationOrderSuraSort)
                             forControlEvents:UIControlEventTouchUpInside];
    
    [self.revalationOrderSortButton setShowsTouchWhenHighlighted:YES];
    [self.revalationOrderSortButton setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
    
    //sort by verse count
    [self.verseCountSortButton setTitle:@"V" forState:UIControlStateNormal];
    
    [self.verseCountSortButton setBackgroundImage:barButtonImage forState:UIControlStateNormal];
    [self.verseCountSortButton addTarget:self
                                  action:@selector(fastAccessVerseCountSuraSort)
                        forControlEvents:UIControlEventTouchUpInside];
    
    [self.verseCountSortButton setShowsTouchWhenHighlighted:YES];
    [self.verseCountSortButton setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];

    [self.bottomBar addSubview:self.moshafOrderButton];
    [self.bottomBar addSubview:self.lightSortButton];
    [self.bottomBar addSubview:self.charCountSortButton];
    [self.bottomBar addSubview:self.wordCountSortButton];
    [self.bottomBar addSubview:self.verseCountSortButton];
    [self.bottomBar addSubview:self.revalationOrderSortButton];
    [self.bottomBar addSubview:self.refreshCountSortButton];
}

- (void)howItWorks{
    
   UIAlertController *howItWorks = [UIAlertController alertControllerWithTitle:[@"How it works" localize]
                                          message:[@"After you review any Sura remember to refresh its cell here, you have limited days before light goes almost off unless you refresh it again.\n\nThat will give you an overview of how frequent you review Suras and how fresh are they in your memory.\n\nLet's add more light to our lives !" localize]
                                   preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:[@"Ok" localize] style:UIAlertActionStyleDefault
                                                          handler:nil];
    
    UIAlertAction* doNotShowAgain = [UIAlertAction actionWithTitle:[@"Don't show again" localize] style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) { [self setShowHelpScreen:NO]; }];
    
    
    if (!self.menuOpened) {
        [howItWorks addAction:doNotShowAgain];
    }
    [howItWorks addAction:defaultAction];
    
    [self presentViewController:howItWorks animated:YES completion:nil];
    
}

- (BOOL)showHelpScreen{
    if (![[NSUserDefaults standardUserDefaults] objectForKey:ShowHelpScreenKey]) {
        return YES;
    }
    return [[[NSUserDefaults standardUserDefaults] objectForKey:ShowHelpScreenKey] boolValue];
}

- (void)setShowHelpScreen:(BOOL)showHelpScreen{
    [[NSUserDefaults standardUserDefaults] setBool:showHelpScreen forKey:ShowHelpScreenKey];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    CGFloat sideLength = sqrt(self.view.frame.size.height * self.view.frame.size.width * 0.9 / 114.0);
    CellSmallWidth = sideLength;
    CellSmallHeight = sideLength;

    self.bottomBar.frame =  CGRectMake(0, self.collectionView.frame.size.height - self.bottomBar.frame.size.height, self.collectionView.frame.size.width, self.bottomBar.frame.size.height);
    
    
    [self applyCurrentSort];
    [self refreshScoreButton];
    [self.collectionView reloadData];
    
    [self.settingsViewController beginAppearanceTransition: YES animated: NO];
}

Boolean hasAppearedBefore;

- (Boolean)hasCredentials{
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"email"] != nil &&
    [[NSUserDefaults standardUserDefaults] stringForKey:@"password"] != nil;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if(!appearedBefore) {
        [self initSettingsView];
        appearedBefore = YES;
        [self startupHelpAlert];
    }

    [self showSortBar];
}

- (UIAlertController *)menu{
    if (!_menu) {
        _menu = [UIAlertController alertControllerWithTitle:[@"Select Action" localize]
                                                    message:@""
                                             preferredStyle:UIAlertControllerStyleAlert];
        
//        UIAlertAction* resetAction = [UIAlertAction actionWithTitle:@"Reset"
//                                                              style:UIAlertActionStyleDestructive
//                                                            handler:^(UIAlertAction * action) {
//                                                                  [self resetAllTasks];
//                                                                  self.menuOpened = NO;
//                                                              }];
        
        UIAlertAction* howItWorksAction = [UIAlertAction actionWithTitle:[@"How it works" localize]
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction * action) {
                                                                  [self howItWorks];
                                                                  self.menuOpened = NO;
                                                              }];
        
        UIAlertAction* settingsAction = [UIAlertAction actionWithTitle:[@"Settings" localize]
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
                                                               [self settings];
                                                               self.menuOpened = NO;
                                                           }];
        
//        UIAlertAction* saveAction = [UIAlertAction actionWithTitle:@"Save To File"
//                                                                 style:UIAlertActionStyleDefault
//                                                               handler:^(UIAlertAction * action) {
//                                                                   [self save];
//                                                                   self.menuOpened = NO;
//                                                               }];
//        
//        UIAlertAction* loadAction = [UIAlertAction actionWithTitle:@"Load from File"
//                                                             style:UIAlertActionStyleDefault
//                                                           handler:^(UIAlertAction * action) {
//                                                               [self load];
//                                                               self.menuOpened = NO;
//                                                           }];
        
        UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:[@"Cancel" localize]
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction * action) { self.menuOpened = NO; }];
        [_menu addAction:howItWorksAction];
        [_menu addAction:settingsAction];
//        [_menu addAction:saveAction];
//        [_menu addAction:loadAction];
        //[_menu addAction:resetAction];
        [_menu addAction:cancelAction];
    }
    return _menu;
}


//handlers keys are used as action titles, values are blocks to be executed on selecting that action
- (void)showMenuWithTitle:(NSString *)title handlers:(NSDictionary *)handlers orderedKeys:(NSArray <NSString *>*)orderedKeys {
    UIAlertController *menu = [UIAlertController alertControllerWithTitle:title
                                                                  message:@""
                                                           preferredStyle:UIAlertControllerStyleAlert];
    
    for (NSString *actionTitle in orderedKeys) {
        UIAlertAction* action = [UIAlertAction actionWithTitle:actionTitle
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action) {
                                                           void (^ block)() = handlers[actionTitle];
                                                           block();
                                                       }];
        [menu addAction:action];
    }
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:[@"Cancel" localize]
                                                           style:UIAlertActionStyleDefault
                                                         handler:nil];
    
    

    [menu addAction:cancelAction];
    
    [self presentViewController:menu animated:YES completion:nil];
}


//TODO: save/load memorization state

- (void)showSuraMenu{
    
    NSMutableArray <NSString *>* orderedKeys = @[].mutableCopy;
    [orderedKeys addObject:[@"Refresh" localize]];
    
    if (operations[[@"Refresh" localize]] == nil) {
        operations[[@"Refresh" localize]] = ^(){
            [AMRTools play:@"rahman.mp3"];
            [self refreshTask:self.selectedTask];
        };
    }
    
    [orderedKeys addObject:[@"Set Notification" localize]];
    
    if (operations[[@"Set Notification" localize]] == nil) {
        operations[[@"Set Notification" localize]] = ^(){
            [self showNotificationsViewController];
        };
    }

    
    [orderedKeys addObject:[@"Put Marker" localize]];
    if (operations[[@"Put Marker" localize]] == nil) {
        operations[[@"Put Marker" localize]] = ^(){
            [self setMarkedSuraIndex:[self.selectedTask index]];
            [self refreshViews];
        };
    }
    
    if(self.selectedTask.memorizedState != MEMORIZED){
        [orderedKeys addObject:[@"Memorized" localize]];
    }
    if (operations[[@"Memorized" localize]] == nil) {
        operations[[@"Memorized" localize]] = ^(){
            [AMRTools play:@"rahman.mp3"];
            if (self.selectedTask.memorizedState == BEING_MEMORIZED) {
                self.selectedTask.memorizeDate = [NSDate new];
                [[DataSource shared] saveSuraMemorizationDate:self.selectedTask.memorizeDate suraName:self.selectedTask.name];
            }
            
            self.selectedTask.memorizedState = MEMORIZED;
            NSLog(@"memorized: %ld",(long)self.selectedTask.memorizedState);
            [self.periodicTaskManager.dataSource saveMemorizedStateForTask:self.selectedTask];
            [self.collectionView reloadData];
        };
    }
    
    if (self.selectedTask.memorizedState != BEING_MEMORIZED) {
        [orderedKeys addObject:[@"Being Memorized" localize]];
    }
    
    if (operations[[@"Being Memorized" localize]] == nil) {
        operations[[@"Being Memorized" localize]] = ^(){
            [AMRTools play:@"rahman.mp3"];
            self.selectedTask.memorizedState = BEING_MEMORIZED;
            NSLog(@"memorized: %ld",(long)self.selectedTask.memorizedState);
            [self.periodicTaskManager.dataSource saveMemorizedStateForTask:self.selectedTask];
            [self.collectionView reloadData];
        };
    }
    
    if (self.selectedTask.memorizedState != WAS_MEMORIZED) {
        [orderedKeys addObject:[@"Was Memorized" localize]];
    }
    if (operations[[@"Was Memorized" localize]] == nil) {
        operations[[@"Was Memorized" localize]] = ^(){
            self.selectedTask.memorizedState = WAS_MEMORIZED;
            [self.periodicTaskManager.dataSource saveMemorizedStateForTask:self.selectedTask];
            NSLog(@"was memorized: %ld",(long)self.selectedTask.memorizedState);
            [self.collectionView reloadData];
        };
    }
    
    if (self.selectedTask.memorizedState != NOT_MEMORIZED) {
        [orderedKeys addObject:[@"Not Memorized" localize]];
     }
    
    if (operations[[@"Not Memorized" localize]] == nil) {
        operations[[@"Not Memorized" localize]] = ^(){
            self.selectedTask.memorizedState = NOT_MEMORIZED;
            NSLog(@"memorized: %ld",(long)self.selectedTask.memorizedState);
            [self.periodicTaskManager.dataSource saveMemorizedStateForTask:self.selectedTask];
            [self.collectionView reloadData];
        };
    }
    NSString *title = [NSString stringWithFormat:@"%lu %@",(unsigned long) [Sura.suraNames indexOfObject:self.selectedTask.name] + 1, [self.selectedTask.name localize]];
    [self showMenuWithTitle:title handlers:operations orderedKeys:orderedKeys];
}

- (void)save{
    [self areYouSureDialogWithMessage:@"Save Suras states (overwrites last save)?" yesBlock:^{
        [self.periodicTaskManager.dataSource saveToFile:@"status.bin" completion:^(BOOL success){
            if (success) {
                NSLog(@"Saved to status.bin");
            }
        }];
    }];
}

- (void)load{
    [self areYouSureDialogWithMessage:@"Loading last saved Suras states ?" yesBlock:^{
        [self.periodicTaskManager.dataSource loadFromFile:@"status.bin" completionBlock:^(BOOL success){
            if (success) {
                NSLog(@"load success from status.bin");
                [self refresh];
                [self.periodicTaskManager.dataSource save];
            } else {
                NSLog(@"******failed to load from file status.bin");
            }
        }];
    }];
}

- (void)settings{
    [self showSettingsView];
    
    
    //[self.navigationController pushViewController:settingsViewController animated:YES];
}

//TODO: extract common steps to some block

- (void)normalSuraOrderSort{
    //TODO: move sorting to a separate class
    NSMutableArray *sortedArray;
    sortedArray = [self.periodicTaskManager.dataSource.tasks sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        NSUInteger firstOrder = [[Sura suraNames] indexOfObject:((PeriodicTask *)a).name];
        NSUInteger secondOrder = [[Sura suraNames] indexOfObject:((PeriodicTask *)b).name];
        NSComparisonResult result;
        if (firstOrder > secondOrder ) {
            result = NSOrderedDescending;
        } else {
            result = NSOrderedAscending;
        }
        
        return result;
    }].mutableCopy;
    
    self.periodicTaskManager.dataSource.tasks = sortedArray;
    
    self.sortType = NormalSuraOrderSort;
    self.periodicTaskManager.dataSource.settings.sortType = NormalSuraOrderSort;
    [self.periodicTaskManager.dataSource saveSettings];
    
    [self.collectionView reloadData];
}

- (void)revalSuraOrderSort{
    //TODO: move sorting to a separate class
    NSMutableArray *sortedArray;
    sortedArray = [self.periodicTaskManager.dataSource.tasks sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        NSUInteger firstSuraOrder = [[Sura suraNames] indexOfObject:((PeriodicTask *)a).name];
        NSUInteger secondSuraOrder = [[Sura suraNames] indexOfObject:((PeriodicTask *)b).name];
        NSUInteger firstOrder = [[Sura suraRevalOrder][firstSuraOrder] unsignedIntegerValue];
        NSUInteger secondOrder = [[Sura suraRevalOrder][secondSuraOrder] unsignedIntegerValue];
        NSComparisonResult result;
        if (firstOrder > secondOrder ) {
            result = NSOrderedDescending;
        } else if (firstOrder < secondOrder ) {
            result = NSOrderedAscending;
        } else if(firstSuraOrder > secondSuraOrder) {
            result = NSOrderedDescending;
        } else {
            result = NSOrderedAscending;
        }

        
        return result;
    }].mutableCopy;
    
    self.periodicTaskManager.dataSource.tasks = sortedArray;
    
    self.sortType = RevalationOrderSort;
    
    [self.collectionView reloadData];
}

- (void)fastAccessCharCountSuraSort{
    self.hideCounter += 1;
    [self hideSortBar];
    if (self.periodicTaskManager.dataSource.settings.sortType == CharCountSort) {
        self.periodicTaskManager.dataSource.settings.descendingSort = !self.periodicTaskManager.dataSource.settings.descendingSort;
        [self.periodicTaskManager.dataSource saveSettings];
    }
    
    [self toast:self.periodicTaskManager.dataSource.settings.descendingSort ? @"Character Count Chapter Sort Desc." : @"Character Count Chapter Sort Asc."];
    
    [self charCountSuraSort];
    [self applyCurrentSort];
}

- (void)fastAccessRevalationOrderSuraSort{
    self.hideCounter += 1;
    [self hideSortBar];
    if (self.periodicTaskManager.dataSource.settings.sortType == RevalationOrderSort) {
        self.periodicTaskManager.dataSource.settings.descendingSort = !self.periodicTaskManager.dataSource.settings.descendingSort;
        [self.periodicTaskManager.dataSource saveSettings];
    }
    
    [self toast:self.periodicTaskManager.dataSource.settings.descendingSort ? @"Revalation Order Chapter Sort Desc." : @"Revalation Order Chapter Sort Asc."];
    
    [self revalSuraOrderSort];
    [self applyCurrentSort];
}


- (void)fastAccessWordCountSuraSort{
    self.hideCounter += 1;
    [self hideSortBar];
    if (self.periodicTaskManager.dataSource.settings.sortType == WordCountSort) {
        self.periodicTaskManager.dataSource.settings.descendingSort = !self.periodicTaskManager.dataSource.settings.descendingSort;
        [self.periodicTaskManager.dataSource saveSettings];
    }
    
    [self toast:self.periodicTaskManager.dataSource.settings.descendingSort ? @"Words Count Chapter Sort Desc." : @"Words Count Chapter Sort Asc."];
    
    [self wordCountSuraSort];
    [self applyCurrentSort];
}

- (void)fastAccessVerseCountSuraSort{
    self.hideCounter += 1;
    [self hideSortBar];
    if (self.periodicTaskManager.dataSource.settings.sortType == VersesCountSort) {
        self.periodicTaskManager.dataSource.settings.descendingSort = !self.periodicTaskManager.dataSource.settings.descendingSort;
        [self.periodicTaskManager.dataSource saveSettings];
    }
    
    [self toast:self.periodicTaskManager.dataSource.settings.descendingSort ? @"Verses Count Chapter Sort Desc." : @"Verses Count Chapter Sort Asc."];
    
    [self versesCountSuraSort];
    [self applyCurrentSort];
}



- (void)fastAccessRefreshCountSuraSort{
    self.hideCounter += 1;
    [self hideSortBar];
    if (self.periodicTaskManager.dataSource.settings.sortType == RefreshCountSort) {
        self.periodicTaskManager.dataSource.settings.descendingSort = !self.periodicTaskManager.dataSource.settings.descendingSort;
        [self.periodicTaskManager.dataSource saveSettings];
    }
    
    [self toast:self.periodicTaskManager.dataSource.settings.descendingSort ? @"Refresh Count Chapter Sort Desc." : @"Refresh Count Chapter Sort Asc."];
    
    [self refreshCountSuraSort];
    [self applyCurrentSort];
}


- (void)fastAccessNormalSuraOrderSort{
    
    self.hideCounter += 1;
    [self hideSortBar];
    if (self.periodicTaskManager.dataSource.settings.sortType == NormalSuraOrderSort) {
        self.periodicTaskManager.dataSource.settings.descendingSort = !self.periodicTaskManager.dataSource.settings.descendingSort;
        
        [self.periodicTaskManager.dataSource saveSettings];
    }
    
    [self toast:self.periodicTaskManager.dataSource.settings.descendingSort ? @"Quran Order Chapter Sort Desc." : @"Quran Order Chapter Sort Asc."];
    
    [self normalSuraOrderSort];
    [self applyCurrentSort];
}

- (void)fastAccessWeakerFirstSuraFirstSort{
    self.hideCounter += 1;
    [self hideSortBar];
    if (self.periodicTaskManager.dataSource.settings.sortType == LightSort) {
        self.periodicTaskManager.dataSource.settings.descendingSort = !self.periodicTaskManager.dataSource.settings.descendingSort;
        [self.periodicTaskManager.dataSource saveSettings];
    }
    
    [self toast:self.periodicTaskManager.dataSource.settings.descendingSort ? @"Cell Light Strength Chapter Sort Desc." : @"Cell Light Strength Chapter Sort Asc."];
    
    [self weakerFirstSuraFirstSort];
    [self applyCurrentSort];
}

- (void)charCountSuraSort{
    //TODO: move sorting to a separate class
    NSMutableArray *sortedArray;
    sortedArray = [self.periodicTaskManager.dataSource.tasks sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        NSUInteger firstSuraOrder = [[Sura suraNames] indexOfObject:((PeriodicTask *)a).name];
        NSUInteger secondSuraOrder = [[Sura suraNames] indexOfObject:((PeriodicTask *)b).name];
        NSUInteger firstOrder = [[Sura suraCharsCount][firstSuraOrder] unsignedIntegerValue];
        NSUInteger secondOrder = [[Sura suraCharsCount][secondSuraOrder] unsignedIntegerValue];
        NSComparisonResult result;
        if (firstOrder > secondOrder ) {
            result = NSOrderedDescending;
        } else if (firstOrder < secondOrder ) {
            result = NSOrderedAscending;
        } else if(firstSuraOrder > secondSuraOrder) {
            result = NSOrderedDescending;
        } else {
            result = NSOrderedAscending;
        }
        
        return result;
    }].mutableCopy;
    
    self.periodicTaskManager.dataSource.tasks = sortedArray;
    
    self.sortType = CharCountSort;
    self.periodicTaskManager.dataSource.settings.sortType = CharCountSort;
    [self.periodicTaskManager.dataSource saveSettings];

    
    [self.collectionView reloadData];
}

- (void)refreshCountSuraSort{
    //TODO: move sorting to a separate class
    NSMutableArray *sortedArray;
    sortedArray = [self.periodicTaskManager.dataSource.tasks sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        PeriodicTask *task1 = ((PeriodicTask *)a);
        PeriodicTask *task2 = ((PeriodicTask *)b);
        
        NSUInteger firstSuraOrder = [[Sura suraNames] indexOfObject:task1.name];
        NSUInteger secondSuraOrder = [[Sura suraNames] indexOfObject:task2.name];
        NSUInteger firstOrder = task1.history.count;
        NSUInteger secondOrder = task2.history.count;
        NSComparisonResult result;
        if (firstOrder > secondOrder ) {
            result = NSOrderedDescending;
        } else if (firstOrder < secondOrder ) {
            result = NSOrderedAscending;
        } else if(firstSuraOrder > secondSuraOrder) {
            result = NSOrderedDescending;
        } else {
            result = NSOrderedAscending;
        }
        
        return result;
    }].mutableCopy;
    
    self.periodicTaskManager.dataSource.tasks = sortedArray;
    
    self.sortType = RefreshCountSort;
    self.periodicTaskManager.dataSource.settings.sortType = RefreshCountSort;
    [self.periodicTaskManager.dataSource saveSettings];
    
    [self.collectionView reloadData];
}


- (void)wordCountSuraSort{
    //TODO: move sorting to a separate class
    NSMutableArray *sortedArray;
    sortedArray = [self.periodicTaskManager.dataSource.tasks sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        NSUInteger firstSuraOrder = [[Sura suraNames] indexOfObject:((PeriodicTask *)a).name];
        NSUInteger secondSuraOrder = [[Sura suraNames] indexOfObject:((PeriodicTask *)b).name];
        NSUInteger firstOrder = [[Sura suraWordCount][firstSuraOrder] unsignedIntegerValue];
        NSUInteger secondOrder = [[Sura suraWordCount][secondSuraOrder] unsignedIntegerValue];
        NSComparisonResult result;
        if (firstOrder > secondOrder ) {
            result = NSOrderedDescending;
        } else if (firstOrder < secondOrder ) {
            result = NSOrderedAscending;
        } else if(firstSuraOrder > secondSuraOrder) {
            result = NSOrderedDescending;
        } else {
            result = NSOrderedAscending;
        }
        
        return result;
    }].mutableCopy;
    
    self.periodicTaskManager.dataSource.tasks = sortedArray;
    
    self.sortType = WordCountSort;
    
    [self.collectionView reloadData];
}

- (void)versesCountSuraSort{
    //TODO: move sorting to a separate class
    NSMutableArray *sortedArray;
    sortedArray = [self.periodicTaskManager.dataSource.tasks sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        NSUInteger firstSuraOrder = [[Sura suraNames] indexOfObject:((PeriodicTask *)a).name];
        NSUInteger secondSuraOrder = [[Sura suraNames] indexOfObject:((PeriodicTask *)b).name];
        
        NSUInteger firstOrder = [[Sura suraVerseCount][firstSuraOrder] unsignedIntegerValue];
        NSUInteger secondOrder = [[Sura suraVerseCount][secondSuraOrder] unsignedIntegerValue];
        NSComparisonResult result;
        if (firstOrder > secondOrder ) {
            result = NSOrderedDescending;
        } else if (firstOrder < secondOrder ) {
            result = NSOrderedAscending;
        } else if(firstSuraOrder > secondSuraOrder) {
            result = NSOrderedDescending;
        } else {
            result = NSOrderedAscending;
        }
        
        return result;
    }].mutableCopy;
    
    self.periodicTaskManager.dataSource.tasks = sortedArray;
    
    self.sortType = VersesCountSort;
    
    [self.collectionView reloadData];
}

- (void)setReversedSortOrder:(BOOL)reversedSortOrder{
    self.periodicTaskManager.dataSource.settings.descendingSort = reversedSortOrder;
}

- (BOOL)reversedSortOrder{
    return self.periodicTaskManager.dataSource.settings.descendingSort;
}

- (void)setSortType:(SorterType)sortType{
    self.periodicTaskManager.dataSource.settings.sortType = sortType;
}

- (SorterType)sortType{
    return self.periodicTaskManager.dataSource.settings.sortType;
}

- (void)reversedSuraOrderSort{
    [self.periodicTaskManager sortListReverseOrder];
    [self.collectionView reloadData];
}

- (void)weakerFirstSuraFirstSort{
    [self.periodicTaskManager sortListWeakerFirst];
    self.periodicTaskManager.dataSource.settings.sortType = LightSort;
    [self.periodicTaskManager.dataSource saveSettings];
    [self.collectionView reloadData];
}

- (void)strongerFirstSuraOrderSort{
    [self.periodicTaskManager sortListStrongestFirst];
    [self.collectionView reloadData];
}

- (void)AddPeriodicRefresh{
    NSTimer* timer = [NSTimer timerWithTimeInterval:RefreshPeriod target:self selector:@selector(refresh) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}


- (void)showActionMenu{
    self.menuOpened = YES;
    [self presentViewController:self.menu animated:YES completion:nil];
}

- (void)refresh{
    [self applyCurrentSort];
    [self refreshScoreButton];
    [self.collectionView reloadData];
}


- (void)orientationChanged:(NSNotification *)note{
    [self.collectionView reloadData];
}

- (void)areYouSureDialogWithMessage:(NSString *)message yesBlock:(void(^)(void))yesBlock{
    UIAlertController *confirmation = [UIAlertController alertControllerWithTitle:[@"Are You sure ?" localize]
                                                                        message:message
                                                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* noAction = [UIAlertAction actionWithTitle:[@"No" localize] style:UIAlertActionStyleDefault
                                                          handler:nil];
    
    UIAlertAction* yesAction = [UIAlertAction actionWithTitle:[@"Yes" localize] style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) { yesBlock(); }];
    
    [confirmation addAction:noAction];
    [confirmation addAction:yesAction];
    
    [self presentViewController:confirmation animated:YES completion:nil];
}

- (void)infoWithMessage:(NSString *)message {
    UIAlertController *confirmation = [UIAlertController alertControllerWithTitle:[@"Info" localize]
                                                                          message:message
                                                                   preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* noAction = [UIAlertAction actionWithTitle:[@"Ok" localize] style:UIAlertActionStyleDefault
                                                     handler:nil];
    
    [confirmation addAction:noAction];
    
    [self presentViewController:confirmation animated:YES completion:nil];
}

- (void)resetAllTasks{
    [self areYouSureDialogWithMessage:@"Reset all Suras states ?" yesBlock:^{
        [self.periodicTaskManager resetTasks];
        [self refresh];
        NSLog(@"Destructed !");
    }];
}

- (void)setupCollectionView{
    UINib *nib = [UINib nibWithNibName:@"SuraViewCell" bundle: nil];
    [self.collectionView registerNib:nib forCellWithReuseIdentifier:@"cellIdentifier"];

//    UIImage *image = [UIImage imageNamed:@"star.jpg"];
//    self.collectionView.backgroundView = [[UIImageView alloc] initWithImage:image];
//    self.collectionView.backgroundView.alpha = 0.8;
    
    self.collectionView.backgroundView.contentMode = UIViewContentModeScaleAspectFit;
    //[self addSwipeHandlerToView:self.collectionView direction:@"left" handler:@selector(settings)];
    //[self addSwipeHandlerToView:self.collectionView direction:@"right" handler:@selector(showCharts)];
    self.collectionView.bounces = YES;
}

- (void) showCharts {
    UIAlertController *menu = [UIAlertController alertControllerWithTitle:[@"Charts Menu" localize]
                                                                  message:@""
                                                           preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* dalyScore = [UIAlertAction actionWithTitle:[@"Daily Score Chart" localize]
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       [self dailyScoreChart];
                                                   }];
    [menu addAction:dalyScore];
    
    UIAlertAction* monthlyScore = [UIAlertAction actionWithTitle: [@"Monthly Score Sum Chart" localize]
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * action) {
                                                          [self monthlyScoreChart];
                                                      }];
    [menu addAction:monthlyScore];
    
    UIAlertAction* memorizedPercentage = [UIAlertAction actionWithTitle:[@"Memorization Pie Chart" localize]
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       [self memorizationChart];
                                                   }];
    [menu addAction:memorizedPercentage];
    
    
    //khatmaChart
    
    UIAlertAction* todayReviewReadRatio = [UIAlertAction actionWithTitle:[@"Review-Read Ratio" localize]
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
                                                               [self reviewReadRatioChart];
                                                           }];
    [menu addAction:todayReviewReadRatio];
    
    //khatmaChart
    
    UIAlertAction* khatmaProgress = [UIAlertAction actionWithTitle:[@"Khatma Progress Chart" localize]
                                                                  style:UIAlertActionStyleDefault
                                                                handler:^(UIAlertAction * action) {
                                                                    [self khatmaChart];
                                                                }];
    [menu addAction:khatmaProgress];
    
        UIAlertAction* cancel = [UIAlertAction actionWithTitle:[@"Cancel" localize]
                                                         style:UIAlertActionStyleCancel
                                                       handler:^(UIAlertAction * action) {
                                                           
                                                       }];
        [menu addAction:cancel];
    
//    UIAlertAction* action = [UIAlertAction actionWithTitle:actionTitle
//                                                     style:UIAlertActionStyleDefault
//                                                   handler:^(UIAlertAction * action) {
//                                                       void (^ block)() = handlers[actionTitle];
//                                                       block();
//                                                   }];
//    [menu addAction:action];
    
    
    
    [self presentViewController:menu animated:YES completion:nil];
    
    
}

- (void)dailyScoreChart {
    NSLog(@"Show charts called");
    CubicLineChartViewController *chartsVC = [[CubicLineChartViewController alloc] init];
    chartsVC.scores = [self.statistics scores];
    chartsVC.chartTitle = @"Daily Score Chart";
    [self.navigationController pushViewController:chartsVC animated:NO];
}

- (void)monthlyScoreChart {
    NSLog(@"Show monthly scores chart called");
    CubicLineChartViewController *chartsVC = [[CubicLineChartViewController alloc] init];
    chartsVC.scores = [self.statistics getMonthlySumScores];
    chartsVC.chartTitle = @"Monthly Score Sum Chart";
    [self.navigationController pushViewController:chartsVC animated:NO];
}

- (void)memorizationChart {
    NSLog(@"memorizationChart TODO");
    PiePolylineChartViewController  *vc = [[PiePolylineChartViewController alloc] init];
    
    vc.scores = [self.statistics getMemorizationStates];
    vc.chartTitle = [@"Memorization Percentage Chart" localize];
    
    [self.navigationController pushViewController:vc animated:NO];

}

//reviewReadChart
- (void)reviewReadRatioChart {
    PiePolylineChartViewController  *vc = [[PiePolylineChartViewController alloc] init];
    
    vc.scores = [self.statistics getTodayReviewReadScores];
    vc.chartTitle = [@"Review Read Ratio Chart (Today)" localize];
    
    [self.navigationController pushViewController:vc animated:NO];
}


- (void)khatmaChart {
    PiePolylineChartViewController  *vc = [[PiePolylineChartViewController alloc] init];

    vc.scores = [self.statistics getKhatmaProgress: currentKhatma];
    vc.chartTitle = [@"Khatma Progress Chart" localize];
    
    [self.navigationController pushViewController:vc animated:NO];

    
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.periodicTaskManager taskCount];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    SuraViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cellIdentifier" forIndexPath:indexPath];
    if (cell.tag == 0) {
        cell.tag = 1;
        cell.content.layer.cornerRadius = 10.0;
        cell.content.clipsToBounds = YES;
        cell.content.layer.borderWidth = 2;
        cell.backgroundColor = [UIColor blackColor];
//        cell.memorized.layer.cornerRadius = cell.memorized.frame.size.width / 2.0;
//        cell.memorized.layer.borderWidth = 2.0;
        cell.memorized.image = self.sunImage;
        cell.layer.shouldRasterize = YES;
        cell.layer.rasterizationScale = [[UIScreen mainScreen] scale];
    }
    PeriodicTask *task = [self.periodicTaskManager getTaskAtIndex:indexPath.row];
    
    task.cycleInterval = self.periodicTaskManager.dataSource.settings.fadeTime;
    
    //remainingTimeInterval
    CGFloat progress = (self.isLightCalculationBasedOnAverage ? (self.periodicTaskManager.dataSource.settings.fadeTime - [task averageRefreshInterval]) : [task remainingTimeInterval]) / self.periodicTaskManager.dataSource.settings.fadeTime;
    
    if (progress < 0.3 && [task.history count] > 0) {
        cell.suraName.textColor = [UIColor colorWithRed:153/255 green:255/255 blue:153/255 alpha:0.2];
    } else {
        cell.suraName.textColor = [UIColor blackColor];
    }
    
    
    cell.score.text = [[AMRTools abbreviateNumber:[Statistics suraScore:task.name] withDecimal:1] stringByAppendingString:@"c"];
    cell.verseCountLabel.text = [[[Sura suraVerseCount][[Sura.suraNames indexOfObject:task.name]] stringValue] stringByAppendingString:@"v"];
    
    cell.suraName.adjustsFontSizeToFitWidth = YES;

    switch (task.memorizedState) {
        case 0://not memorized
            cell.memorized.hidden = YES;
            break;
            
        case 1://was memorized
            cell.memorized.hidden = NO;
            cell.memorized.image = self.sunImage;
            cell.memorized.alpha = 0.5;
            break;
            
        case 2://is memorized
            cell.memorized.hidden = NO;
            cell.memorized.image = self.sunImage;
            cell.memorized.alpha = 1.0;
            break;
            
        case 3:
            cell.memorized.hidden = NO;
            cell.memorized.image = self.recordImage;
            cell.memorized.alpha = 1.0;
            break;
            
        default:
            break;
    }
    
    NSUInteger days = progress != 0 ? [[NSDate new] timeIntervalSinceDate:[task.history lastObject]] / (60*60*24) : 10000;
    NSUInteger avgDays = task.averageRefreshInterval / (60*60*24);
    if (days < 1000 && days > 0) {
        cell.daysElapsed.text = [NSString stringWithFormat:@"%ldD", self.isLightCalculationBasedOnAverage ? (long)avgDays : (long)days];
    } else {
        if(self.isLightCalculationBasedOnAverage && avgDays > 0) {
            cell.daysElapsed.text = [NSString stringWithFormat:@"%ldD", (long)avgDays];
        } else {
            cell.daysElapsed.text = nil;
        }
    }
    
    if ([task.history count] == 0) {
        [cell.backgroundImage setHidden:NO];
    } else {
        [cell.backgroundImage setHidden:YES];
    }
    
    if ([task index] == [self getMarkedSuraIndex]) {
        cell.content.layer.borderColor = [UIColor blueColor].CGColor;
    }
    else
    if (days >= 30 && [task.history count] > 0) {
        cell.content.layer.borderColor = [UIColor redColor].CGColor;
        
    } else
    
     {
        cell.content.layer.borderColor = [UIColor clearColor].CGColor;
    }
    
    NSInteger memoDays = task.memorizedState == 2 && task.memorizeDate != nil ?
    ([[NSDate new] timeIntervalSinceDate:task.memorizeDate] / (60*60*24))
    : 1000;
    
    if ((days >= 10 || (memoDays <= RecentMemorizedMarkDays && days >= 1)) && task.memorizedState == 2 ) {//is memorized
        //cell.memorized.layer.borderColor = [UIColor redColor].CGColor;
        cell.memorized.image = [cell.memorized.image imageWithRenderingMode: UIImageRenderingModeAlwaysTemplate];
        cell.memorized.tintColor = (memoDays <= RecentMemorizedMarkDays && days >= 1) ? [UIColor orangeColor] : [UIColor redColor];
    }
    
    if (days >= 15 && task.memorizedState == 1 ) {//was memorized
        //imageWithRenderingMode
        cell.memorized.image = [cell.memorized.image imageWithRenderingMode: UIImageRenderingModeAlwaysTemplate];
        cell.memorized.tintColor = [[UIColor redColor] colorWithAlphaComponent:0.5];
        //cell.memorized.layer.borderColor = [UIColor redColor].CGColor;
        
    }
    
    else {
        cell.memorized.layer.borderColor = [UIColor clearColor].CGColor;
    }
    
    cell.content.backgroundColor = [UIColor colorWithRed:0.0/255.0 green:MAX(progress,0) blue:0.0/255.0 alpha:1];
    
    
    NSString *suraIndex = self.overviewMode || self.periodicTaskManager.dataSource.settings.showSuraIndex ?
    [NSString stringWithFormat:@"%lu ",(unsigned long) [Sura.suraNames indexOfObject:task.name] + 1] : @"";
    
    NSString *refreshCount = (self.periodicTaskManager.dataSource.settings.showRefreshCount && !self.overviewMode ? [NSString stringWithFormat:@" [%lu]", (unsigned long)task.history.count] : @"");
    
    
    cell.suraName.text = [NSString stringWithFormat:@"%@%@%@", suraIndex, self.overviewMode ? @"" : [task.name localize], refreshCount];
    
    if (self.overviewMode) {
        cell.suraName.textAlignment = NSTextAlignmentCenter;
        cell.suraNameLeadingConstraint.constant = 3;
        cell.suraNameTrailingConstraint.constant = 3;
        cell.suraNameTopSpace.constant = 3;
        cell.suraNameBottomSpace.constant = 3;
    } else {
        cell.suraName.textAlignment = [AMRTools isRTL] ? NSTextAlignmentRight : NSTextAlignmentLeft;
        cell.suraNameLeadingConstraint.constant = 8;
        cell.suraNameTrailingConstraint.constant = 8;
        cell.suraNameTopSpace.constant = 25;
        cell.suraNameBottomSpace.constant = 25;
    }
    
    cell.suraName.adjustsFontSizeToFitWidth = YES;
    cell.score.textColor = cell.suraName.textColor;
    cell.verseCountLabel.textColor = cell.suraName.textColor;
    cell.daysElapsed.textColor = cell.suraName.textColor;
    if ([AMRTools isRTL]) {
        cell.daysElapsed.textAlignment = NSTextAlignmentLeft;
        cell.score.textAlignment = NSTextAlignmentRight;
        cell.verseCountLabel.textAlignment = NSTextAlignmentRight;
    }
    
    cell.verseCountLabel.adjustsFontSizeToFitWidth = YES;
    
    [cell.memorized setHidden: !self.periodicTaskManager.dataSource.settings.showMemorizationMark || task.memorizedState == NOT_MEMORIZED];

    [cell.verseCountLabel setHidden:self.overviewMode || !self.periodicTaskManager.dataSource.settings.showVerseCount];
    
    [cell.score setHidden:self.overviewMode || !self.periodicTaskManager.dataSource.settings.showCharacterCount];
    
    [cell.daysElapsed setHidden:self.overviewMode || !self.periodicTaskManager.dataSource.settings.showElapsedDaysCount];
    
    return cell;
}

- (void)toggleOverView {
    self.overviewMode = !self.overviewMode;
    [[NSUserDefaults standardUserDefaults] setBool:self.overviewMode forKey:@"overviewMode"];
    [self toast:self.overviewMode ? @"Overview mode On" : @"Overview mode off"];
    [self.collectionView reloadData];
    //[self showSortBar];
}

UIColor *backgroundColorTemp;
UIColor *textColorTemp;

#define systemSoundID 1200
static NSInteger tone = 0;

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"SoundOffFlag"]) {
        AudioServicesPlaySystemSound (systemSoundID + (tone++ % 10));
    }
    
    SuraViewCell * cell = (SuraViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    backgroundColorTemp = cell.content.backgroundColor;
    textColorTemp = cell.suraName.textColor;
    cell.content.backgroundColor = [UIColor greenColor];
    cell.suraName.textColor = [UIColor blackColor];
    cell.verseCountLabel.textColor = [UIColor blackColor];
    cell.score.textColor = [UIColor blackColor];
    cell.daysElapsed.textColor = [UIColor blackColor];
    
}

- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    SuraViewCell *cell = (SuraViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    cell.content.backgroundColor = backgroundColorTemp;
    cell.suraName.textColor = textColorTemp;
    cell.verseCountLabel.textColor = textColorTemp;
    cell.score.textColor = textColorTemp;
    cell.daysElapsed.textColor = textColorTemp;
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        
//    });
    
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return self.overviewMode ? CGSizeMake(CellSmallWidth, CellSmallHeight) : CGSizeMake(CellWidth, CellHeight);
}

- (void)collectionView:(UICollectionView *)collectionView  didSelectItemAtIndexPath:(nonnull NSIndexPath *)indexPath{
    PeriodicTask *task = [self.periodicTaskManager getTaskAtIndex:indexPath.row];

    self.selectedTask = task;
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"single_touch_refresh_flag"]){
        [AMRTools play:@"rahman.mp3"];
        [self refreshTask:self.selectedTask];
    } else {
        [self showSuraMenu];
    }
    
}

- (void)refreshTask:(PeriodicTask *)task{
    [self.periodicTaskManager.dataSource saveSuraLastRefresh:[[NSDate alloc] init] suraName:task.name];
    [self refreshViews];
}

- (void)refreshViews{
    //[self.bannerView loadRequest:[GADRequest request]];
    NSLog(@"refreshViews");
    dispatch_async(dispatch_get_main_queue(), ^{
        [self applyCurrentSort];
        [self refreshScoreButton];
        [self.collectionView reloadData];
    });
}

- (void)reload{
    NSLog(@"reload: hiding HUD");
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        updateInProgress = NO;
    });
    
    [[DataSource shared] load: ^{
        [self refreshViews];
    }];
}

- (void)applyCurrentSort{
    
    switch (self.sortType) {
        case NormalSuraOrderSort:
            [self normalSuraOrderSort];
            self.moshafOrderButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.8];
            self.lightSortButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];
            self.charCountSortButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];
            self.wordCountSortButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];
            self.verseCountSortButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];
            self.refreshCountSortButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];
            self.revalationOrderSortButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];

            break;
        case LightSort:
            [self weakerFirstSuraFirstSort];
            self.moshafOrderButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];
            self.lightSortButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.8];
            self.charCountSortButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];
            self.wordCountSortButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];
            self.verseCountSortButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];
            self.refreshCountSortButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];
            self.revalationOrderSortButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];

            break;
            
        case VersesCountSort:
            [self versesCountSuraSort];
            self.moshafOrderButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];
            self.lightSortButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];
            self.charCountSortButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];
            self.wordCountSortButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];
            self.verseCountSortButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.8];
            self.refreshCountSortButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];
            self.revalationOrderSortButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];

            break;
            
        case WordCountSort:
            [self wordCountSuraSort];
            self.moshafOrderButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];
            self.lightSortButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];
            self.charCountSortButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];
            self.wordCountSortButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.8];
            self.verseCountSortButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];
            self.refreshCountSortButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];
            self.revalationOrderSortButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];
            break;
            
        case CharCountSort:
            [self charCountSuraSort];
            self.moshafOrderButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];
            self.lightSortButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];
            self.charCountSortButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.8];
            self.wordCountSortButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];
            self.verseCountSortButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];
            self.refreshCountSortButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];
            self.revalationOrderSortButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];
            break;
            
        case RevalationOrderSort:;
            [self revalSuraOrderSort];
            self.moshafOrderButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];
            self.lightSortButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];
            self.charCountSortButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];
            self.wordCountSortButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];
            self.verseCountSortButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];
            self.refreshCountSortButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];
            self.revalationOrderSortButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.8];
            
            break;
            
        case RefreshCountSort:
            [self refreshCountSuraSort];
            self.moshafOrderButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];
            self.lightSortButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];
            self.charCountSortButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];
            self.wordCountSortButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];
            self.verseCountSortButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];
            self.refreshCountSortButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.8];
            self.revalationOrderSortButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];
            
            break;
            
        default:
            NSLog(@"Unsupported sort type");
            break;
    }
    
    
    if (self.reversedSortOrder) {
        [self reversedSuraOrderSort];
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    self.bannerView.adSize = (([[UIDevice currentDevice] orientation] ==  UIDeviceOrientationPortrait) ? kGADAdSizeSmartBannerPortrait : kGADAdSizeSmartBannerLandscape);

    
    CGFloat sideLength = sqrt(size.height * size.width * 0.9 / 114.0);
    CellSmallWidth = sideLength;
    CellSmallHeight = sideLength;
    self.bottomBar.frame = CGRectMake(0, size.height - self.bottomBar.frame.size.height, size.width, self.bottomBar.frame.size.height);
    [self.collectionView reloadData];
    //self.bannerView.center = self.adContainerView.center;
    
    CGRect adFrame =  self.bannerView.frame;
    adFrame.origin.y = size.height - adFrame.size.height;
    self.bannerView.frame = adFrame;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - SettingsViewControllerDelegate

- (void)settingsViewController:(SettingsViewController *)settingsViewController didChangeSettings:(Settings *)settings{
    self.periodicTaskManager.dataSource.settings = [settings copy];
    NSLog(@"QuranGardensViewController: received Settings: %@", self.periodicTaskManager.dataSource.settings);
    [self.periodicTaskManager.dataSource saveSettings];
    [self refresh];
    //TODO: Apply new settings
}

#pragma mark - Collection View

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    NSLog(@"scrollViewWillBeginDragging");
    [self showSortBar];
}

#pragma mark - Notifications

- (void)setNotificationForTask: (PeriodicTask *)task withDate: (NSDate *)notificationdate withRepeatPeriod:(NSCalendarUnit)repeatUnit{
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    
    notification.fireDate = notificationdate;
    notification.alertBody =  [NSString stringWithFormat:@"Time to read %@", task.name];
    notification.timeZone = [NSTimeZone defaultTimeZone];
    //notification.applicationIconBadgeNumber = 1;
    
    // https://stackoverflow.com/a/9389200/1356559
    notification.soundName = @"rahman.caf";
    //TODO use notification.repeatInterval
    NSDictionary<NSString *, NSString *> *userInfo = @{ @"uid" : task.name };
    notification.userInfo = userInfo;
    
    notification.repeatInterval = repeatUnit;
    
    
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
}

- (void)cancelNotificationsForTask:(PeriodicTask *)task {
    //https://stackoverflow.com/a/6341476/1356559
    UIApplication *app = [UIApplication sharedApplication];
    NSArray *eventArray = [app scheduledLocalNotifications];
    for (int i=0; i < [eventArray count]; i++)
    {
        UILocalNotification* oneEvent = [eventArray objectAtIndex:i];
        NSDictionary *userInfoCurrent = oneEvent.userInfo;
        NSString *uid = [NSString stringWithFormat:@"%@",[userInfoCurrent valueForKey:@"uid"]];
        if ([uid isEqualToString:task.name])
        {
            //Cancelling local notification
            [app cancelLocalNotification:oneEvent];
            break;
        }
    }
}

- (void)showNotificationsViewController {
    if (!self.notificationsViewController) {
       self.notificationsViewController = [[UIStoryboard storyboardWithName:@"NotificationsStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"NotificationsViewController"];
        
        self.notificationsViewController.delegate =self;
    }
    
    self.notificationsViewController.suraName = [self.selectedTask.name localize];
    
    [self presentViewController:self.notificationsViewController animated:YES completion:nil];
    
}

- (void)notificationControllerDidCancel {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)notificationControllerDidSelectDate:(NSDate *)notificationDate withRepeatPeriod:(NSCalendarUnit)repeatUnit{
    NSLog(@"notification date %@", notificationDate);
    [self setNotificationForTask:self.selectedTask withDate:notificationDate withRepeatPeriod:repeatUnit];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)NotificationControllerDidChooseToDeleteNotification {
    [self cancelNotificationsForTask:self.selectedTask];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark Settings

- (void)showSettingsView{
    self.navigationController.navigationBar.layer.zPosition = -1;
    [self.settingsDismissDetector setHidden:NO];
    [self.settingsView setHidden:NO];
    
}

- (void)HideSettingsView{
    self.navigationController.navigationBar.layer.zPosition = 0;
    [self.settingsDismissDetector setHidden:YES];
    [self.settingsView setHidden:YES];
    
}


@end
