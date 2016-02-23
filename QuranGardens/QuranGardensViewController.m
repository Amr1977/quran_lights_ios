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

NSString *const ShowHelpScreenKey = @"Show_help_screen";

@interface QuranGardensViewController ()

@property (strong, nonatomic) PeriodicTaskManager *periodicTaskManager;
@property (strong, nonatomic) UIAlertController *menu;
@property (nonatomic) BOOL showHelpScreen;
@property (nonatomic) BOOL menuOpened;

@end

@implementation QuranGardensViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self handleDeviceOrientation];
    
    [self setnavigationBar];
    
    [self initTaskManager];
    
    [self setupCollectionView];
    
    [self AddPeriodicrefresh];
    
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
                                          message:@"After you review any Sura remember to tap its cell here to light it up, you have 10 days before light goes almost off unless you review it again.\n\nThat will give you an overview of how frequent you review Suras and how fresh are they in your memory.\n\nLet's add more light to our lives !"
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
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Reset" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                  [self resetAllTasks];
                                                                  self.menuOpened = NO;
                                                              }];
        
        UIAlertAction* howItWorksAction = [UIAlertAction actionWithTitle:@"How it works" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                  [self howItWorks];
                                                                  self.menuOpened = NO;
                                                              }];
        
        
        UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction * action) { self.menuOpened = NO; }];
        [_menu addAction:howItWorksAction];
        [_menu addAction:defaultAction];
        [_menu addAction:cancelAction];
    }
    return _menu;
}

- (void)AddPeriodicrefresh{
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
        [UIView animateWithDuration:1 animations:^{
            cell.backgroundColor = [UIColor colorWithRed:1/255 green:MAX(progress,0.2) blue:1/255 alpha:1];
            cell.timeProgressView.progress = progress;
            cell.timeProgressView.progressTintColor  = [UIColor redColor];
        }];
    }
    else{
        cell.timeProgressView.progress = progress;
        cell.backgroundColor = [UIColor colorWithRed:1/255 green:progress blue:1/255 alpha:1];
        cell.timeProgressView.progressTintColor  = [UIColor blueColor];
    }
    
    cell.suraName.text = [NSString stringWithFormat:@"%u %@", indexPath.row + 1, task.name];
    
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
    [self areYouSureDialogWithMessage:@"Did you review this Sura ?" yesBlock:^{
        PeriodicTask *task = [self.periodicTaskManager getTaskAtIndex:indexPath.row];
        
        RLMRealm *realm = [RLMRealm defaultRealm];
        [realm beginWriteTransaction];
        task.lastOccurrence = [[NSDate alloc] init];
        [realm commitWriteTransaction];
        
        [self.collectionView reloadData];
    }];
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
