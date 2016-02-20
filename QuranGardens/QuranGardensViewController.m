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

@interface QuranGardensViewController () <UIAlertViewDelegate>

@property (strong, nonatomic) PeriodicTaskManager *periodicTaskManager;
@property (strong, nonatomic) UIAlertController *menu;
@property (nonatomic) BOOL showHelpScreen;

@end

@implementation QuranGardensViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIImage *image = [UIImage imageNamed:@"galaxy.png"];
    self.collectionView.backgroundView = [[UIImageView alloc] initWithImage:image];
    self.collectionView.backgroundView.contentMode = UIViewContentModeCenter;
    
    self.periodicTaskManager = [PeriodicTaskManager new];
    [self.periodicTaskManager loadTasks];
    if (![self.periodicTaskManager taskCount]) {
        [self initSuras];
    }
    [self setupCollectionView];
    UIBarButtonItem *anotherButton = [[UIBarButtonItem alloc] initWithTitle:@"Menu" style:UIBarButtonItemStylePlain target:self action:@selector(showActionMenu)];
    self.navigationItem.rightBarButtonItem = anotherButton;
    
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(orientationChanged:)
     name:UIDeviceOrientationDidChangeNotification
     object:[UIDevice currentDevice]];
    
    [self AddPeriodicrefresh];
    if ([self showHelpScreen]) {
        [self howItWorks];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 1){
        [self setShowHelpScreen:NO];
    }
}

- (void)howItWorks{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"How it works"
                                                        message:@"After you review any Sura remember to tap its cell here to light it up, you have 10 days before light goes off.\nThat will give you an overview of Suras in your memory.\n\nLet's turn light on !"
                                                       delegate:self
                                              cancelButtonTitle:@"Got it"
                                              otherButtonTitles: @"Don't show again",nil];
    
    alertView.alertViewStyle = UIAlertViewStyleDefault;
    
    [alertView show];
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
                                                              handler:^(UIAlertAction * action) { [self resetAllTasks]; }];
        
        UIAlertAction* howItWorksAction = [UIAlertAction actionWithTitle:@"How it works" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) { [self howItWorks]; }];
        
        
        UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) { }];
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
    [self presentViewController:self.menu animated:YES completion:nil];
}

- (void)refresh{
    [self.collectionView reloadData];
}


- (void)orientationChanged:(NSNotification *)note{
    [self.collectionView reloadData];
}

- (void)resetAllTasks{
    [self.periodicTaskManager resetTasks];
    [self refresh];
}

- (void)setupCollectionView{
    self.view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    UICollectionViewFlowLayout *layout=[[UICollectionViewFlowLayout alloc] init];
    self.collectionView=[[UICollectionView alloc] initWithFrame:self.view.frame collectionViewLayout:layout];
    [self.collectionView setDataSource:self];
    [self.collectionView setDelegate:self];
    
    UINib *nib = [UINib nibWithNibName:@"SuraViewCell" bundle: nil];
    [self.collectionView registerNib:nib forCellWithReuseIdentifier:@"cellIdentifier"];
    
    UIImage *image = [UIImage imageNamed:@"dark-stars.jpg"];
    self.collectionView.backgroundView = [[UIImageView alloc] initWithImage:image];
    //self.collectionView.backgroundView.alpha = 0.8;
    self.collectionView.backgroundView.contentMode = UIViewContentModeScaleAspectFit;
}

NSInteger const intervalInTenDays = 10*24*60*60;
//TODO: create suras in a method and randomize content in another method
- (void)initSuras{
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
    if (progress > 0.2) {
        [UIView animateWithDuration:1 animations:^{
            cell.alpha = MAX(progress, 0.2);
        }];
    }
    else{
        cell.alpha = MAX(progress, 0.2);
    }

    cell.timeProgressView.progress = progress;
    
    if (progress < 0.3){
        cell.timeProgressView.progressTintColor  = [UIColor redColor];
    }
    else {
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
        
        cell.backgroundColor = [UIColor greenColor];
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
    task.lastOccurrence = [[NSDate alloc] init];
    [realm commitWriteTransaction];
    
    [self.collectionView reloadData];
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
