//
//  LoginViewController.m
//  QuranGardens
//
//  Created by Amr Lotfy on 1/7/17.
//  Copyright © 2017 Amr Lotfy. All rights reserved.
//

#import "LoginViewController.h"
#import "AppDelegate.h"
#import "AMRTools.h"

@interface LoginViewController ()


@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UITextField *retypePasswordTextField;
@property (weak, nonatomic) IBOutlet UITextField *userName;



@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)onSignUp:(id)sender {

    NSString *name = self.userName.text;
    NSString *email = self.emailTextField.text;
    NSString *password = self.passwordTextField.text;
    NSString *password2 = self.retypePasswordTextField.text;
    
    if (name != nil && email != nil && password != nil && password2 != nil ) {
        [(AppDelegate *)[[UIApplication sharedApplication] delegate] signUpWithEmail:email password:password userName:name completion:^(BOOL success){
            if (success) {
                [AMRTools showMenuWithTitle:@"Success" handlers:nil];
            } else {
                //TODO check connectivity
                [AMRTools showMenuWithTitle:@"Error signing up, check credentials" handlers:nil];
            }
        }];
    }
    

    
    
}

- (IBAction)exit:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
