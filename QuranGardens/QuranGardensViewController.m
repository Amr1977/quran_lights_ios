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

CGFloat const CellHeight = 57;
CGFloat const CellWidth = 150;
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

@end

@implementation QuranGardensViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.sunImage = [UIImage imageNamed:@"sun.jpg"];
    
    [self handleDeviceOrientation];
    
    [self setNavigationBar];
    
    [self initTaskManager];
    
    [self setupCollectionView];
    
    [self applyCurrentSort];
    
    [self AddPeriodicRefresh];
    
    [self startupHelpAlert];
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

- (void)setMenuButton{
    UIImage *barButtonImage = [UIImage imageNamed:@"sun.jpg"];
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
        
        UIAlertAction* settingsAction = [UIAlertAction actionWithTitle:@"Settings"
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
                                                               [self settings];
                                                               self.menuOpened = NO;
                                                           }];
        
        UIAlertAction* saveAction = [UIAlertAction actionWithTitle:@"Save To File"
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * action) {
                                                                   [self save];
                                                                   self.menuOpened = NO;
                                                               }];
        
        UIAlertAction* loadAction = [UIAlertAction actionWithTitle:@"Load from File"
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
                                                               [self load];
                                                               self.menuOpened = NO;
                                                           }];
        
        UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction * action) { self.menuOpened = NO; }];
        [_menu addAction:howItWorksAction];
        [_menu addAction:settingsAction];
        [_menu addAction:saveAction];
        [_menu addAction:loadAction];
        [_menu addAction:resetAction];
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
            NSLog(@"memorized: %d",self.selectedTask.memorizedState);
            [self.periodicTaskManager.dataSource saveMemorizedStateForTask:self.selectedTask];
            [self.collectionView reloadData];
        };
    }
    operations[@"Remove last refresh"] = ^(){NSLog(@"TODO !!");};
    
    operations[@"Was Memorized"] = ^(){
        self.selectedTask.memorizedState = 1;
        [self.periodicTaskManager.dataSource saveMemorizedStateForTask:self.selectedTask];
        NSLog(@"was memorized: %d",self.selectedTask.memorizedState);
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
    
    UIImage *image = [UIImage imageNamed:@"star.jpg"];
    self.collectionView.backgroundView = [[UIImageView alloc] initWithImage:image];
    self.collectionView.backgroundView.alpha = 0.8;
    self.collectionView.backgroundView.contentMode = UIViewContentModeScaleAspectFit;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.periodicTaskManager taskCount];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    SuraViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cellIdentifier" forIndexPath:indexPath];
    PeriodicTask *task = [self.periodicTaskManager getTaskAtIndex:indexPath.row];
    
    task.cycleInterval = self.periodicTaskManager.dataSource.settings.fadeTime;
    
    CGFloat progress = [task remainingTimeInterval] / self.periodicTaskManager.dataSource.settings.fadeTime;
    
    if (progress < 0.30) {
        cell.suraName.textColor = [UIColor colorWithRed:153/255 green:255/255 blue:153/255 alpha:1];
    } else {
        cell.suraName.textColor = [UIColor blackColor];
    }
    
    cell.suraName.adjustsFontSizeToFitWidth = YES;

    //TODO: remove this after testing
    
    switch (task.memorizedState) {
        case 0://not memorized
            cell.memorized.hidden = YES;
            break;
            
        case 1://was memorized
            cell.memorized.hidden = NO;
            cell.memorized.image = self.sunImage;
            cell.memorized.alpha = 0.5;
            if (!cell.memorized.image) {
                NSLog(@"nil image");
            }
            break;
            
        case 2://is memorized
            cell.memorized.hidden = NO;
            cell.memorized.image = self.sunImage;
            cell.memorized.alpha = 1.0;
            if (!cell.memorized.image) {
                NSLog(@"nil image");
            }
            break;
            
        default:
            break;
    }
    
    
    NSUInteger days = [[NSDate new] timeIntervalSinceDate:task.lastOccurrence] / (60*60*24);
    if (days < 1000 && days > 0) {
        cell.daysElapsed.text = [NSString stringWithFormat:@"%ld", (long)days];
    } else {
        cell.daysElapsed.text = nil;
    }
    
    cell.backgroundColor = [UIColor colorWithRed:1/255 green:MAX(progress,0.2) blue:1/255 alpha:1];
    cell.suraName.text = [NSString stringWithFormat:@"%lu %@ ", (unsigned long) [Sura.suraNames indexOfObject:task.name] + 1, task.name];
   
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
        [history addObject:task.lastOccurrence];
        [self.periodicTaskManager.dataSource saveSuraLastRefresh:task.lastOccurrence suraName:task.name];
    }
    
    //TODO: create another way to undo last action on cell
    NSTimeInterval intervalSinceLastRefresh = -1 * [task.lastOccurrence timeIntervalSinceNow];
    if (intervalSinceLastRefresh <= 5) {
        //undo action
        [history removeLastObject];
        if ([history count] < 1) {
            task.lastOccurrence = [NSDate dateWithTimeIntervalSince1970:[Sura.suraNames indexOfObject:task.name]];
        } else {
            task.lastOccurrence = [history lastObject];
        }
    } else {
        //sura reviewed now
        task.lastOccurrence = [[NSDate alloc] init];
    }
    
    [self.periodicTaskManager.dataSource saveSuraLastRefresh:task.lastOccurrence suraName:task.name];
    [self applyCurrentSort];
    [self.collectionView reloadData];
    
}

- (void)applyCurrentSort{
    
    switch (self.sortType) {
        case NormalSuraOrderSort:
            [self normalSuraOrderSort];
            break;
        case LightSort:
            [self weakerFirstSuraFirstSort];
            break;
            
        case VersesCountSort:
            [self versesCountSuraSort];
            break;
            
        case WordCountSort:
            [self wordCountSuraSort];
            break;
            
        case CharCountSort:
            [self charCountSuraSort];
            break;
            
        case RevalationOrderSort:;
            [self revalSuraOrderSort];
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
