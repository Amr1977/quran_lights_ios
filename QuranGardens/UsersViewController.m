//
//  UsersViewController.m
//  QuranGardens
//
//  Created by Amr Lotfy on 5/23/17.
//  Copyright © 2017 Amr Lotfy. All rights reserved.
//

#import "UsersViewController.h"
#import "DataSource.h"

@interface UsersViewController ()



@property (weak, nonatomic) IBOutlet UITableView *tableView;




@end

@implementation UsersViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateUI];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[[DataSource shared] getUsers] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    }
    cell.textLabel.text = ((User *) [[DataSource shared] getUsers][indexPath.row]).name;
    
    return cell;
}

- (void)updateUI {
    
    NSInteger currentUserIndex = 0;
    User *currentUser = [[DataSource shared] getCurrentUser];
    for (User *user in [[DataSource shared] getUsers]) {
        if (user == currentUser) {
            break;
        }
        currentUserIndex++;
    }
    
    NSIndexPath* selectedCellIndexPath = [NSIndexPath indexPathForRow:currentUserIndex inSection:0];
    [self.tableView selectRowAtIndexPath:selectedCellIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    User *user =[[DataSource shared] getUsers][indexPath.row];
    [[DataSource shared] setCurrentUser:user];
    [self.tableView reloadData];
    //[self updateUI];
}





@end
