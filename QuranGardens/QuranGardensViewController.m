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

CGFloat const CellHeight = 80;
CGFloat const CellWidth = 140;
NSInteger const RefreshPeriod = 300; // refresh each 5 minutes;

static NSString *const ShowHelpScreenKey = @"Show_help_screen";
static NSString *const ReversedSortOrderOptionKey = @"reversed_sort_order";
static NSString *const SorterTypeOptionKey = @"sorter_type";

@interface QuranGardensViewController ()

@property (strong, nonatomic) PeriodicTaskManager *periodicTaskManager;
@property (strong, nonatomic) UIAlertController *menu;
@property (strong, nonatomic) UIAlertController *suraMenu;
@property (strong, nonatomic) PeriodicTask *selectedTask;
@property (nonatomic) BOOL showHelpScreen;
@property (nonatomic) BOOL menuOpened;

@property (nonatomic) BOOL reversedSortOrder;
@property (nonatomic, assign) SorterType sortType;

@property (strong,nonatomic) UIImage *sunImage;
@property (strong,nonatomic) UIImage *recordImage;

@property (strong, nonatomic) Statistics* statistics;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *score;

@property (strong, nonatomic) UIButton *moshafOrderButton;
@property (strong, nonatomic) UIButton *lightSortButton;
@property (strong, nonatomic) UIButton *charCountSortButton;
@property (strong, nonatomic) UIButton *moshafOrderButton4;
@property (strong, nonatomic) UIButton *moshafOrderButton5;


@end

@implementation QuranGardensViewController

UIImage *barButtonImage;
UIImage *barButtonImageActive;

- (void)viewDidLoad
{
    [super viewDidLoad];
    barButtonImage = [[UIImage imageNamed:@"sun.jpg"] imageWithRenderingMode: UIImageRenderingModeAlwaysTemplate];
    barButtonImageActive = [[UIImage imageNamed:@"sun.jpg"] imageWithRenderingMode: UIImageRenderingModeAlwaysTemplate];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncHistory) name:@"HistoryLoadedFromFireBase" object:nil];
    
    self.sunImage = [UIImage imageNamed:@"sun.jpg"];
    self.recordImage = [UIImage imageNamed:@"record.png"];
    
    [self handleDeviceOrientation];
    
    [self setNavigationBar];
    
    [self initTaskManager];
    
    [self setupCollectionView];
    
    [self applyCurrentSort];
    
    [self AddPeriodicRefresh];
    
    [self startupHelpAlert];
    
    //TODO: make singleton of data source to avoid this
    self.statistics = [[Statistics alloc] initWithDataSource:self.periodicTaskManager.dataSource];
    [self refreshScoreButton];
    
}

- (void)refreshScoreButton{
    NSInteger todayScore =  [self.statistics todayScore];
    NSInteger yesterdayScore = [self.statistics yesterdayScore];
    NSInteger total = [self.statistics totalScore];
    
    NSString *totalString = [AMRTools abbreviateNumber:total withDecimal:1];
    NSString *todayString = [AMRTools abbreviateNumber:todayScore withDecimal:1];

    self.score.title = [NSString stringWithFormat:@"Score: %@(%@)",totalString, todayString];
    
    UIColor *color = ((todayScore > yesterdayScore)? [UIColor greenColor] : [UIColor whiteColor]);
    [self.score setTintColor:color];
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

- (void)syncHistory{
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableDictionary<NSString *,NSMutableArray<NSNumber *> *> *fbRefreshHistory = delegate.fbRefreshHistory;
    NSMutableDictionary<NSString *,NSNumber *> *fbMemoHistory = delegate.fbMemorizationState;
    
    if (fbRefreshHistory == nil) {
        fbRefreshHistory = @{}.mutableCopy;
        delegate.fbRefreshHistory = @{}.mutableCopy;
    }
    
    if (fbMemoHistory == nil) {
        fbMemoHistory = @{}.mutableCopy;
        delegate.fbMemorizationState = @{}.mutableCopy;
    }
    
    for (NSInteger index = 0; index < 114; index++) {
        NSString *indexStr = [NSString stringWithFormat:@"%ld", (long)(index + 1)];
        if (fbRefreshHistory[indexStr] == nil) {
            fbRefreshHistory[indexStr] = @[].mutableCopy;
        }
        NSString *suraName = [Sura suraNames][index];
        NSMutableArray<NSNumber *>* localHistory  = [self mapDatesToNumbers:[self.periodicTaskManager.dataSource loadRefreshHistoryForSuraName:[Sura suraNames][index]].mutableCopy];
        
        NSMutableArray<NSNumber *>* remoteHistory = fbRefreshHistory[indexStr];
        if (remoteHistory == nil) {
            remoteHistory = @[].mutableCopy;
        }
        
        //update remote
        for (NSNumber *number in localHistory) {
            if ([remoteHistory indexOfObject:number] == NSNotFound) {
                [delegate refreshSura:suraName withDate:number];
                [remoteHistory addObject:number];
            }
        }
        
        delegate.fbRefreshHistory[indexStr] = [delegate sort:remoteHistory];
        NSMutableArray *datesArray = [self mapNumbersToDates: delegate.fbRefreshHistory[indexStr]];
        [self.periodicTaskManager.dataSource setHistory:suraName history:datesArray];
    }
    
    [delegate updateTimeStamp];
    
    [self.collectionView reloadData];
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


- (void)setMenuButton{

    CGRect imageFrame = CGRectMake(0, 0, 40, 40);
    
    UIButton *settingsButton = [[UIButton alloc] initWithFrame:imageFrame];
    [settingsButton setTitle:@"S" forState:UIControlStateNormal];
    //settingsButton.tintColor = [UIColor yellowColor];
    [settingsButton setBackgroundImage:self.sunImage forState:UIControlStateNormal];
    [settingsButton addTarget:self
                   action:@selector(settings)
         forControlEvents:UIControlEventTouchUpInside];
    
    [settingsButton setShowsTouchWhenHighlighted:YES];
    UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithCustomView:settingsButton];
    
    
    //sort by normal order
    self.moshafOrderButton = [[UIButton alloc] initWithFrame:imageFrame];
    [self.moshafOrderButton setTitle:@"B" forState:UIControlStateNormal];
    
    
    [self.moshafOrderButton setBackgroundImage:barButtonImage forState:UIControlStateNormal];
    [self.moshafOrderButton addTarget:self
                   action:@selector(fastAccessNormalSuraOrderSort)
         forControlEvents:UIControlEventTouchUpInside];
    
    [self.moshafOrderButton setShowsTouchWhenHighlighted:YES];
    UIBarButtonItem *moshafOrderItem = [[UIBarButtonItem alloc] initWithCustomView:self.moshafOrderButton];
    
    
    //sort by light strength
    self.lightSortButton = [[UIButton alloc] initWithFrame:imageFrame];
    [self.lightSortButton setTitle:@"L" forState:UIControlStateNormal];
    
    [self.lightSortButton setBackgroundImage:barButtonImage forState:UIControlStateNormal];
    [self.lightSortButton addTarget:self
                          action:@selector(fastAccessWeakerFirstSuraFirstSort)
                forControlEvents:UIControlEventTouchUpInside];
    
    [self.lightSortButton setShowsTouchWhenHighlighted:YES];
    UIBarButtonItem *lightSortItem = [[UIBarButtonItem alloc] initWithCustomView:self.lightSortButton];
    
    //sort by character count
    self.charCountSortButton = [[UIButton alloc] initWithFrame:imageFrame];
    [self.charCountSortButton setTitle:@"C" forState:UIControlStateNormal];
    
    [self.charCountSortButton setBackgroundImage:barButtonImage forState:UIControlStateNormal];
    [self.charCountSortButton addTarget:self
                        action:@selector(fastAccessCharCountSuraSort)
              forControlEvents:UIControlEventTouchUpInside];
    
    [self.charCountSortButton setShowsTouchWhenHighlighted:YES];
    UIBarButtonItem *charCountSortItem = [[UIBarButtonItem alloc] initWithCustomView:self.charCountSortButton];

    [UIView animateWithDuration:1 animations:^{
        //self.navigationItem.rightBarButtonItem = menuButton;
        self.navigationItem.rightBarButtonItems = @[menuButton, moshafOrderItem, lightSortItem, charCountSortItem];
    }];
}

- (void)howItWorks{
    
   UIAlertController *howItWorks = [UIAlertController alertControllerWithTitle:@"How it works"
                                          message:@"After you review any Sura remember to tap its cell here to get it refreshed, you have limited days before light goes almost off unless you review it again.\n\nThat will give you an overview of how frequent you review Suras and how fresh are they in your memory.\n\nLet's add more light to our lives !"
                                   preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault
                                                          handler:nil];
    
    UIAlertAction* doNotShowAgain = [UIAlertAction actionWithTitle:@"Don't show again" style:UIAlertActionStyleDefault
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
    [self applyCurrentSort];
    [self refreshScoreButton];
    [self.collectionView reloadData];
}

- (UIAlertController *)menu{
    if (!_menu) {
        _menu = [UIAlertController alertControllerWithTitle:@"Select Action"
                                                    message:@""
                                             preferredStyle:UIAlertControllerStyleAlert];
        
//        UIAlertAction* resetAction = [UIAlertAction actionWithTitle:@"Reset"
//                                                              style:UIAlertActionStyleDestructive
//                                                            handler:^(UIAlertAction * action) {
//                                                                  [self resetAllTasks];
//                                                                  self.menuOpened = NO;
//                                                              }];
        
        UIAlertAction* howItWorksAction = [UIAlertAction actionWithTitle:@"How it works"
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction * action) {
                                                                  [self howItWorks];
                                                                  self.menuOpened = NO;
                                                              }];
        
        UIAlertAction* settingsAction = [UIAlertAction actionWithTitle:@"Settings"
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
        
        UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
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
- (void)showMenuWithTitle:(NSString *)title handlers:(NSDictionary *)handlers{
    UIAlertController *menu = [UIAlertController alertControllerWithTitle:title
                                                                  message:@""
                                                           preferredStyle:UIAlertControllerStyleAlert];
    
    for (NSString *actionTitle in [handlers allKeys]) {
        UIAlertAction* action = [UIAlertAction actionWithTitle:actionTitle
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action) {
                                                           void (^ block)() = handlers[actionTitle];
                                                           block();
                                                       }];
        [menu addAction:action];
    }
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                           style:UIAlertActionStyleDefault
                                                         handler:nil];
    
    

    [menu addAction:cancelAction];
    
    [self presentViewController:menu animated:YES completion:nil];
}

//TODO: save/load memorization state

- (void)showSuraMenu{
    NSMutableDictionary *operations = @{}.mutableCopy;
    operations[@"Refresh"] = ^(){[self refreshTask:self.selectedTask];};
    if(self.selectedTask.memorizedState != 2){
        operations[@"Memorized"] = ^(){
            self.selectedTask.memorizedState = 2;
            NSLog(@"memorized: %ld",(long)self.selectedTask.memorizedState);
            [self.periodicTaskManager.dataSource saveMemorizedStateForTask:self.selectedTask];
            [self.collectionView reloadData];
        };
    }
    
    operations[@"Being Memorized"] = ^(){
        self.selectedTask.memorizedState = 3;
        NSLog(@"memorized: %ld",(long)self.selectedTask.memorizedState);
        [self.periodicTaskManager.dataSource saveMemorizedStateForTask:self.selectedTask];
        [self.collectionView reloadData];
    };
    
    operations[@"Not Memorized"] = ^(){
        self.selectedTask.memorizedState = 0;
        NSLog(@"memorized: %ld",(long)self.selectedTask.memorizedState);
        [self.periodicTaskManager.dataSource saveMemorizedStateForTask:self.selectedTask];
        [self.collectionView reloadData];
    };
    
    operations[@"Remove last refresh"] = ^(){NSLog(@"TODO !!");};
    
    operations[@"Was Memorized"] = ^(){
        self.selectedTask.memorizedState = 1;
        [self.periodicTaskManager.dataSource saveMemorizedStateForTask:self.selectedTask];
        NSLog(@"was memorized: %ld",(long)self.selectedTask.memorizedState);
        [self.collectionView reloadData];
    };
    
    [self showMenuWithTitle:self.selectedTask.name handlers:operations];
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
    SettingsViewController *settingsViewController = [[SettingsViewController alloc] init];
    settingsViewController.settings = [self.periodicTaskManager.dataSource.settings copy];
    settingsViewController.delegate = self;
    
    [self.navigationController pushViewController:settingsViewController animated:YES];
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
        } else if (firstOrder < secondOrder ) {
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
    if (self.periodicTaskManager.dataSource.settings.sortType == CharCountSort) {
        self.periodicTaskManager.dataSource.settings.descendingSort = !self.periodicTaskManager.dataSource.settings.descendingSort;
        [self.periodicTaskManager.dataSource saveSettings];
        [self.collectionView reloadData];
    }
    
    [self charCountSuraSort];
    [self applyCurrentSort];
}

- (void)fastAccessNormalSuraOrderSort{
    if (self.periodicTaskManager.dataSource.settings.sortType == NormalSuraOrderSort) {
        self.periodicTaskManager.dataSource.settings.descendingSort = !self.periodicTaskManager.dataSource.settings.descendingSort;
        [self.periodicTaskManager.dataSource saveSettings];
    }
    
    [self normalSuraOrderSort];
    [self applyCurrentSort];
}

- (void)fastAccessWeakerFirstSuraFirstSort{
    if (self.periodicTaskManager.dataSource.settings.sortType == LightSort) {
        self.periodicTaskManager.dataSource.settings.descendingSort = !self.periodicTaskManager.dataSource.settings.descendingSort;
        [self.periodicTaskManager.dataSource saveSettings];
        [self.collectionView reloadData];
    }
    
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
    UIAlertController *confirmation = [UIAlertController alertControllerWithTitle:@"Are You sure ?"
                                                                        message:message
                                                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* noAction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleDefault
                                                          handler:nil];
    
    UIAlertAction* yesAction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) { yesBlock(); }];
    
    [confirmation addAction:noAction];
    [confirmation addAction:yesAction];
    
    [self presentViewController:confirmation animated:YES completion:nil];
}

- (void)infoWithMessage:(NSString *)message {
    UIAlertController *confirmation = [UIAlertController alertControllerWithTitle:@"Info"
                                                                          message:message
                                                                   preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* noAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault
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
    
    self.view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    UICollectionViewFlowLayout *layout=[[UICollectionViewFlowLayout alloc] init];
    
    //http://stackoverflow.com/questions/28325277/how-to-set-cell-spacing-and-uicollectionview-uicollectionviewflowlayout-size-r
    layout.minimumInteritemSpacing = 2;
    layout.minimumLineSpacing = 2;

    self.collectionView=[[UICollectionView alloc] initWithFrame:self.view.frame collectionViewLayout:layout];
    [self.collectionView setDataSource:self];
    [self.collectionView setDelegate:self];
    
    UINib *nib = [UINib nibWithNibName:@"SuraViewCell" bundle: nil];
    [self.collectionView registerNib:nib forCellWithReuseIdentifier:@"cellIdentifier"];
    
//    UIImage *image = [UIImage imageNamed:@"star.jpg"];
//    self.collectionView.backgroundView = [[UIImageView alloc] initWithImage:image];
//    self.collectionView.backgroundView.alpha = 0.8;
    self.collectionView.backgroundView.contentMode = UIViewContentModeScaleAspectFit;
    [self addSwipeHandlerToView:self.collectionView direction:@"left" handler:@selector(settings)];
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
        cell.memorized.layer.cornerRadius = cell.memorized.frame.size.width / 2.0;
        cell.memorized.layer.borderWidth = 2.0;
        cell.memorized.image = self.sunImage;
        cell.layer.shouldRasterize = YES;
        cell.layer.rasterizationScale = [[UIScreen mainScreen] scale];
    }
    PeriodicTask *task = [self.periodicTaskManager getTaskAtIndex:indexPath.row];
    
    task.cycleInterval = self.periodicTaskManager.dataSource.settings.fadeTime;
    
    CGFloat progress = [task remainingTimeInterval] / self.periodicTaskManager.dataSource.settings.fadeTime;
    
    if (progress < 0.20) {
        cell.suraName.textColor = [UIColor colorWithRed:153/255 green:255/255 blue:153/255 alpha:1];
        cell.daysElapsed.textColor = [UIColor colorWithRed:153/255 green:255/255 blue:153/255 alpha:1];
    } else {
        cell.suraName.textColor = [UIColor blackColor];
        cell.daysElapsed.textColor = [UIColor blackColor];
    }
    
    cell.score.text = [AMRTools abbreviateNumber:[Statistics suraScore:task.name] withDecimal:1];
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
    if (days < 1000 && days > 0) {
        cell.daysElapsed.text = [NSString stringWithFormat:@"%ld", (long)days];
    } else {
        cell.daysElapsed.text = nil;
    }
    
    if (days >= 30) {
        cell.content.layer.borderColor = [UIColor redColor].CGColor;
        
    } else {
        cell.content.layer.borderColor = [UIColor clearColor].CGColor;
    }
    
    if (days >= 10 && task.memorizedState == 2 ) {//is memorized
        //cell.memorized.layer.borderColor = [UIColor redColor].CGColor;
        cell.memorized.image = [cell.memorized.image imageWithRenderingMode: UIImageRenderingModeAlwaysTemplate];
        cell.memorized.tintColor = [UIColor redColor];
    } if (days >= 15 && task.memorizedState == 1 ) {//was memorized
        //imageWithRenderingMode
        cell.memorized.image = [cell.memorized.image imageWithRenderingMode: UIImageRenderingModeAlwaysTemplate];
        cell.memorized.tintColor = [[UIColor redColor] colorWithAlphaComponent:0.5];
        //cell.memorized.layer.borderColor = [UIColor redColor].CGColor;
        
    }
    else {
        cell.memorized.layer.borderColor = [UIColor clearColor].CGColor;
    }
    
    cell.content.backgroundColor = [UIColor colorWithRed:1/255 green:MAX(progress,0.1) blue:1/255 alpha:1];
    cell.suraName.text = [NSString stringWithFormat:@"%lu %@ ", (unsigned long) [Sura.suraNames indexOfObject:task.name] + 1, task.name];
    
    cell.score.textColor = cell.daysElapsed.textColor;
   
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(CellWidth, CellHeight);
}

- (void)collectionView:(UICollectionView *)collectionView  didSelectItemAtIndexPath:(nonnull NSIndexPath *)indexPath{
    PeriodicTask *task = [self.periodicTaskManager getTaskAtIndex:indexPath.row];

    self.selectedTask = task;
    
    [self showSuraMenu];
    [self applyCurrentSort];
    [self.collectionView reloadData];
}

- (void)refreshTask:(PeriodicTask *)task{
    NSMutableArray<NSDate *>* history = [self.periodicTaskManager.dataSource loadRefreshHistoryForSuraName:task.name].mutableCopy;
    if(!history){
        history = @[].mutableCopy;
    }
    
    //task.lastOccurrence = [[NSDate alloc] init];
    
    [self.periodicTaskManager.dataSource saveSuraLastRefresh:[[NSDate alloc] init] suraName:task.name];
    [self applyCurrentSort];
    [self refreshScoreButton];
    [self.collectionView reloadData];
    
    
}

//- (UIImage*)menuButtonImageActive:(BOOL)active {
//    static UIImage *image = [UIImage imageNamed:@"sun.jpg"];
//    static UIImage *imageActive = [image imageWithRenderingMode: UIImageRenderingModeAlwaysTemplate];
//
//    static BOOL firstTime = YES;
//
//    if (firstTime) {
//        imageActive = imageActive.set
//    }
//
//    if (active) {
//        return imageActive;
//    } else {
//        return image;
//    }
//
//}

- (void)applyCurrentSort{
    
    switch (self.sortType) {
        case NormalSuraOrderSort:
            [self normalSuraOrderSort];
            self.moshafOrderButton.tintColor = [UIColor yellowColor];
            self.lightSortButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];
            self.charCountSortButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];

            break;
        case LightSort:
            [self weakerFirstSuraFirstSort];
            self.moshafOrderButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];
            self.lightSortButton.tintColor = [UIColor yellowColor];
            self.charCountSortButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];
            break;
            
        case VersesCountSort:
            [self versesCountSuraSort];
            self.moshafOrderButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];
            self.lightSortButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];
            self.charCountSortButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];
            break;
            
        case WordCountSort:
            [self wordCountSuraSort];
            self.moshafOrderButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];
            self.lightSortButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];
            self.charCountSortButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];
            break;
            
        case CharCountSort:
            [self charCountSuraSort];
            self.moshafOrderButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];
            self.lightSortButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];
            self.charCountSortButton.tintColor = [UIColor yellowColor];
            break;
            
        case RevalationOrderSort:;
            [self revalSuraOrderSort];
             self.moshafOrderButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];
            self.moshafOrderButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];
            self.charCountSortButton.tintColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];
            
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
    [self.collectionView reloadData];
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

@end
