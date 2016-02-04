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

@interface QuranGardensViewController ()

@property (strong, nonatomic) PeriodicTaskManager *periodicTaskManager;
@property (strong, nonatomic) UIAlertController *menu;

@end

@implementation QuranGardensViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
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
}

- (void)viewWillAppear:(BOOL)animated{
    NSLog(@"Refreshing collection view");
    [self.collectionView reloadData];
}

- (UIAlertController *)menu{
    if (!_menu) {
        _menu = [UIAlertController alertControllerWithTitle:@"Select Action"
                                                    message:@""
                                             preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Reset" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) { [self resetAllTasks]; }];
        
        UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) { }];
        
        UIAlertAction* refreshAction = [UIAlertAction actionWithTitle:@"refresh" style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction * action) { [self refresh]; }];
        
        [_menu addAction:defaultAction];
        [_menu addAction:refreshAction];
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
    NSLog(@">>>>>>> Refresh took place.");
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
    
    [self.collectionView setBackgroundColor:[UIColor blackColor]];
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

    cell.backgroundColor = [UIColor greenColor];
    cell.alpha = MAX([task remainingTimeInterval] / task.cycleInterval, 0.2);

    cell.timeProgressView.progress = cell.alpha;
    cell.suraName.text = [NSString stringWithFormat:@"%u %@", indexPath.row + 1, task.name];
    cell.suraName.adjustsFontSizeToFitWidth = YES;
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(170, 90);
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
}

@end
