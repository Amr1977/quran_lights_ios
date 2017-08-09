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
#import "AppDelegate.h"

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
    self.tableView.layer.cornerRadius = 10.0;
    self.tableView.layer.masksToBounds = YES;

    [self setAddUser];
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
    [((AppDelegate *)[[UIApplication sharedApplication] delegate]) syncHistory];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    [cell setSelected:indexPath.row == [self currentUser] animated:YES];
}


- (void)setAddUser {
    //overview mode
    UIButton *addUserButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 100, 30)];
    [addUserButton setTitle:@"Add User" forState:UIControlStateNormal];//🔍🔇🔈
    [addUserButton addTarget:self
                       action:@selector(addUser)
             forControlEvents:UIControlEventTouchUpInside];
    
    [addUserButton setShowsTouchWhenHighlighted:YES];
    UIBarButtonItem *adduserItem = [[UIBarButtonItem alloc] initWithCustomView:addUserButton];
    self.navigationItem.rightBarButtonItems = @[adduserItem];
}

- (void)addUser {
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle: [@"Add Profile" localize]
                                                                              message: [@"Enter Profile Name" localize]
                                                                       preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = [@"name" localize];
        textField.textColor = [UIColor blueColor];
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.borderStyle = UITextBorderStyleRoundedRect;
    }];
//    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
//        textField.placeholder = @"password";
//        textField.textColor = [UIColor blueColor];
//        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
//        textField.borderStyle = UITextBorderStyleRoundedRect;
//        textField.secureTextEntry = YES;
//    }];
    [alertController addAction:[UIAlertAction actionWithTitle:[@"OK" localize] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSArray * textfields = alertController.textFields;
        UITextField * namefield = textfields[0];
        //UITextField * passwordfiled = textfields[1];
        NSLog(@"name: %@",namefield.text);//,passwordfiled.text);
        [[DataSource shared] addUser:namefield.text];
        [self.tableView reloadData];
        
    }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:[@"Cancel" localize] style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}


@end
