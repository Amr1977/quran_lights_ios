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

CGFloat const CellHeight = 50;
CGFloat const CellWidth = 170;

static NSString *const ShowHelpScreenKey = @"Show_help_screen";
static NSString *const ReversedSortOrderOptionKey = @"reversed_sort_order";
static NSString *const SorterTypeOptionKey = @"sorter_type";
static NSString *const InstallDateKey = @"install_date";

typedef NS_OPTIONS(NSUInteger, SorterType) {
    NormalSuraOrderSorter = 0,
    WeakerFirstSorter = 1
};

@interface QuranGardensViewController ()

@property (strong, nonatomic) PeriodicTaskManager *periodicTaskManager;
@property (strong, nonatomic) UIAlertController *menu;
@property (nonatomic) BOOL showHelpScreen;
@property (nonatomic) BOOL menuOpened;

@property (nonatomic) BOOL reversedSortOrder;
@property (nonatomic, assign) SorterType sortType;

@end

@implementation QuranGardensViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    while ([self isDemoOver]) {
        [self infoWithMessage:@"Your demo is over !"];
    }

    [self handleDeviceOrientation];
    
    [self setnavigationBar];
    
    [self initTaskManager];
    
    [self setupCollectionView];
    
    [self applyCurrentSort];
    
    [self AddPeriodicRefresh];
    
    [self startupHelpAlert];
}

- (void)initTaskManager{
    self.periodicTaskManager = [PeriodicTaskManager new];
    [self.periodicTaskManager loadTasks];
    if (![self.periodicTaskManager taskCount]) {
        [self initSuraList];
    }
}

- (void)setnavigationBar{
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

- (void)setMenuButton{
    UIImage *barButtonImage =  [UIImage imageNamed:@"sun.jpg"];
    CGRect imageFrame = CGRectMake(0, 0, 40, 40);
    
    UIButton *someButton = [[UIButton alloc] initWithFrame:imageFrame];
    
    [someButton setBackgroundImage:barButtonImage forState:UIControlStateNormal];
    [someButton addTarget:self
                   action:@selector(showActionMenu)
         forControlEvents:UIControlEventTouchUpInside];
    
    [someButton setShowsTouchWhenHighlighted:YES];
    
    UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithCustomView:someButton];
    [UIView animateWithDuration:1 animations:^{
        self.navigationItem.rightBarButtonItem = menuButton;
    }];
}

- (void)howItWorks{
    
   UIAlertController *howItWorks = [UIAlertController alertControllerWithTitle:@"How it works"
                                          message:@"After you review any Sura remember to tap its cell here to light it up, you have 30 days before light goes almost off unless you review it again.\n\nThat will give you an overview of how frequent you review Suras and how fresh are they in your memory.\n\nLet's add more light to our lives !"
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

- (void)setInstallDate{
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate new] forKey:InstallDateKey];
}

- (BOOL)isDemoOver{
    if (!Demo) {
        return NO;
    }
    NSTimeInterval MonthTimeInterval = 31*24*60*60;
    NSDate *installDate = [[NSUserDefaults standardUserDefaults] objectForKey:InstallDateKey];
    if (!installDate) {
        [self setInstallDate];
        [self infoWithMessage:[NSString stringWithFormat:@"Demo count down: %ld !", lroundf(MonthTimeInterval -[[NSDate new] timeIntervalSinceDate:installDate])]];
        return NO;
    } else {
        [self infoWithMessage:[NSString stringWithFormat:@"Demo count down: %ld !", lroundf(MonthTimeInterval -[[NSDate new] timeIntervalSinceDate:installDate])]];
        
        return [[NSDate new] timeIntervalSinceDate:installDate] > MonthTimeInterval;
    }
}

- (void)viewWillAppear:(BOOL)animated{
    [self.collectionView reloadData];
}

- (UIAlertController *)menu{
    if (!_menu) {
        _menu = [UIAlertController alertControllerWithTitle:@"Select Action"
                                                    message:@""
                                             preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* resetAction = [UIAlertAction actionWithTitle:@"Reset"
                                                              style:UIAlertActionStyleDestructive
                                                            handler:^(UIAlertAction * action) {
                                                                  [self resetAllTasks];
                                                                  self.menuOpened = NO;
                                                              }];
        
        UIAlertAction* howItWorksAction = [UIAlertAction actionWithTitle:@"How it works"
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction * action) {
                                                                  [self howItWorks];
                                                                  self.menuOpened = NO;
                                                              }];
        
        UIAlertAction* sortAction = [UIAlertAction actionWithTitle:@"Sort Suras"
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
                                                                     [self sorter];
                                                                     self.menuOpened = NO;
                                                                 }];
        
        UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction * action) { self.menuOpened = NO; }];
        [_menu addAction:howItWorksAction];
        [_menu addAction:sortAction];
        [_menu addAction:resetAction];
        [_menu addAction:cancelAction];
    }
    return _menu;
}

- (void)sorter{
    UIAlertController *sortAlerController = [UIAlertController alertControllerWithTitle:@"Sort Suras"
                                                                        message:@"Please select prefered sort style:"
                                                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* normalSoraOrderSort = [UIAlertAction actionWithTitle:@"Normal Sura Order" style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
                                                               self.reversedSortOrder = NO;
                                                               [self normalSuraOrderSort];
                                                           }];
    
    UIAlertAction* reverseCurrentOrder = [UIAlertAction actionWithTitle:@"Reverse Current order" style:UIAlertActionStyleDefault
                                                                handler:^(UIAlertAction * action) {
                                                                    [self reversedSuraOrderSort];
                                                                }];
    
    UIAlertAction* weakerFirst = [UIAlertAction actionWithTitle:@"Weaker First" style:UIAlertActionStyleDefault
                                                                handler:^(UIAlertAction * action) {
                                                                    self.reversedSortOrder = NO;
                                                                    [self weakerFirstSuraFirstSort];
                                                                }];
    
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) { self.menuOpened = NO; }];
    
    [sortAlerController addAction:normalSoraOrderSort];
    [sortAlerController addAction:weakerFirst];
    [sortAlerController addAction:reverseCurrentOrder];
    
    [sortAlerController addAction:cancelAction];
    
    [self presentViewController:sortAlerController animated:YES completion:nil];
}

- (void)normalSuraOrderSort{
    NSMutableArray *sortedArray;
    sortedArray = [self.periodicTaskManager.tasks sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
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
    
    self.periodicTaskManager.tasks = sortedArray;
    
    [self.periodicTaskManager saveTasks];
    
    self.sortType = NormalSuraOrderSorter;
    
    [self.collectionView reloadData];
}

- (void)setReversedSortOrder:(BOOL)reversedSortOrder{
    [[NSUserDefaults standardUserDefaults] setBool:reversedSortOrder forKey:ReversedSortOrderOptionKey];
}

- (BOOL)reversedSortOrder{
    return [[NSUserDefaults standardUserDefaults] boolForKey:ReversedSortOrderOptionKey];
}

- (void)setSortType:(SorterType)sortType{
    [[NSUserDefaults standardUserDefaults] setInteger:sortType forKey:SorterTypeOptionKey];
}

- (SorterType)sortType{
    return [[[NSUserDefaults standardUserDefaults] objectForKey:SorterTypeOptionKey] integerValue];
}

- (void)reversedSuraOrderSort{
    self.reversedSortOrder = !self.reversedSortOrder;
    [self.periodicTaskManager sortListReverseOrder];
    [self.collectionView reloadData];
}

- (void)weakerFirstSuraFirstSort{
    self.sortType = WeakerFirstSorter;
    [self.periodicTaskManager sortListWeakerFirst];
    [self.collectionView reloadData];
}

- (void)strongerFirstSuraOrderSort{
    [self.periodicTaskManager sortListStrongestFirst];
    [self.collectionView reloadData];
}

- (void)AddPeriodicRefresh{
    NSInteger RefreshPeriod = 300; // refresh each 5 minutes;
    NSTimer* timer = [NSTimer timerWithTimeInterval:RefreshPeriod target:self selector:@selector(refresh) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}


- (void)showActionMenu{
    self.menuOpened = YES;
    [self presentViewController:self.menu animated:YES completion:nil];
}

- (void)refresh{
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
    self.collectionView=[[UICollectionView alloc] initWithFrame:self.view.frame collectionViewLayout:layout];
    [self.collectionView setDataSource:self];
    [self.collectionView setDelegate:self];
    
    UINib *nib = [UINib nibWithNibName:@"SuraViewCell" bundle: nil];
    [self.collectionView registerNib:nib forCellWithReuseIdentifier:@"cellIdentifier"];
    
    UIImage *image = [UIImage imageNamed:@"star.jpg"];
    self.collectionView.backgroundView = [[UIImageView alloc] initWithImage:image];
    self.collectionView.backgroundView.alpha = 0.8;
    self.collectionView.backgroundView.contentMode = UIViewContentModeScaleAspectFit;
}

NSInteger const intervalInTenDays = 10*24*60*60;
//TODO: create suras in a method and randomize content in another method
- (void)initSuraList{
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    [realm deleteAllObjects];
    for (NSInteger i = 1; i <= 114; i++) {
        PeriodicTask *sura = [[PeriodicTask alloc] init];
        sura.name = [Sura suraNames][i-1];
        sura.cycleInterval = intervalInTenDays;
        sura.lastOccurrence = [NSDate dateWithTimeIntervalSince1970:0];
        [self.periodicTaskManager addPeriodicTask:sura];
    }
    [realm commitWriteTransaction];
    [self.periodicTaskManager saveTasks];
}

- (void)randomizeSuralastOccurrence{
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    for (NSInteger i = 0; i <= 113; i++) {
        PeriodicTask *sura = [self.periodicTaskManager getTaskAtIndex:i];
        NSTimeInterval randomIntervalWithintenDays = arc4random_uniform(intervalInTenDays);
        sura.lastOccurrence = [NSDate dateWithTimeIntervalSinceNow:(-1 * randomIntervalWithintenDays)];
    }
    [realm commitWriteTransaction];
    [self.periodicTaskManager saveTasks];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.periodicTaskManager taskCount];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    SuraViewCell *cell=[collectionView dequeueReusableCellWithReuseIdentifier:@"cellIdentifier" forIndexPath:indexPath];
    
    PeriodicTask *task = [self.periodicTaskManager getTaskAtIndex:indexPath.row];
    
    CGFloat progress = [task remainingTimeInterval] / task.cycleInterval;
    if (progress < 0.3) {
        cell.backgroundColor = [UIColor colorWithRed:1/255 green:MAX(progress,0.2) blue:1/255 alpha:1];
        cell.timeProgressView.progress = progress;
        cell.timeProgressView.progressTintColor  = [UIColor redColor];
    }
    else{
        cell.timeProgressView.progress = progress;
        cell.backgroundColor = [UIColor colorWithRed:1/255 green:progress blue:1/255 alpha:1];
        cell.timeProgressView.progressTintColor  = [UIColor blueColor];
    }
    
    cell.suraName.text = [NSString stringWithFormat:@"%u %@", [Sura.suraNames indexOfObject:task.name] + 1, task.name];
    
    if (!cell.tag) {
        cell.tag = 1;
        
        cell.suraName.adjustsFontSizeToFitWidth = YES;
        
        cell.layer.cornerRadius = 10.0f;
        cell.layer.borderWidth = 1.0f;
        cell.layer.borderColor = [UIColor clearColor].CGColor;
        cell.layer.masksToBounds = YES;
    }
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(CellWidth, CellHeight);
}

- (void)collectionView:(UICollectionView *)collectionView  didSelectItemAtIndexPath:(nonnull NSIndexPath *)indexPath{
    PeriodicTask *task = [self.periodicTaskManager getTaskAtIndex:indexPath.row];
    
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    SuraViewCell *cell = (SuraViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    if (cell.timeProgressView.progress > 0.99) {
        task.lastOccurrence = [NSDate dateWithTimeIntervalSince1970:0];
    } else {
       task.lastOccurrence = [[NSDate alloc] init];
    }
    
    [realm commitWriteTransaction];

    [self applyCurrentSort];

    [self.collectionView reloadData];
}

- (void)applyCurrentSort{
    if (self.sortType == NormalSuraOrderSorter) {
        [self normalSuraOrderSort];
    } else {
        [self weakerFirstSuraFirstSort];
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
    [self.periodicTaskManager saveTasks];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
