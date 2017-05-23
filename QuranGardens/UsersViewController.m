//
//  UsersViewController.m
//  QuranGardens
//
//  Created by Amr Lotfy on 5/23/17.
//  Copyright © 2017 Amr Lotfy. All rights reserved.
//

#import "UsersViewController.h"
#import "DataSource.h"
#import "NSString+Localization.h"

@interface UsersViewController ()



@property (weak, nonatomic) IBOutlet UITableView *tableView;




@end

@implementation UsersViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self setTitle:[@"Profiles" localize]];
    [self.navigationController.navigationBar setTitleTextAttributes:
     @{NSForegroundColorAttributeName:[UIColor whiteColor]}];
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

NSInteger currentUserIndex = 0;

- (void)updateUI {
    
    currentUserIndex = [self currentUser];
    
    NSIndexPath* selectedCellIndexPath = [NSIndexPath indexPathForRow:currentUserIndex inSection:0];
    [self.tableView selectRowAtIndexPath:selectedCellIndexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
}

- (NSInteger)currentUser{
    NSInteger index = 0;
    User *currentUser = [[DataSource shared] getCurrentUser];
    NSArray *users = [[DataSource shared] getUsers];
    for (User *user in users) {
        if (user == currentUser) {
            break;
        }
        index++;
    }
    
    return index;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSArray *users = [[DataSource shared] getUsers];
    if (indexPath.row >= users.count) {
        return;
    }
    User *user =users[indexPath.row];
    [[DataSource shared] setCurrentUser:user];
    [self.tableView reloadData];
    [self updateUI];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    [cell setSelected:indexPath.row == [self currentUser] animated:YES];
}





@end
