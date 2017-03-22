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
@property (weak, nonatomic) IBOutlet UIButton *signin;



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
- (IBAction)onSignin:(id)sender {
    NSString *email = self.emailTextField.text;
    NSString *password = self.passwordTextField.text;
    
    [(AppDelegate *)[[UIApplication sharedApplication] delegate] signInWithEmail:email password:password completion:^(BOOL success, NSString *error) {
        if (success) {
            [self presentViewController:[AMRTools showMenuWithTitle:@"user signed in" message:nil  handlers:nil] animated:YES completion: nil];
        } else {
            [self presentViewController:[AMRTools showMenuWithTitle:@"Error signing in, check credentials" message:nil  handlers:nil] animated:YES completion: nil];
        }
    }];
}

- (IBAction)onSignUp:(id)sender {

    NSString *name = self.userName.text;
    NSString *email = self.emailTextField.text;
    NSString *password = self.passwordTextField.text;
    NSString *password2 = self.retypePasswordTextField.text;
    
    if (name != nil && email != nil && password != nil && password2 != nil && [password isEqualToString:password2]) {
        NSError *signOutError;
        BOOL status = [[FIRAuth auth] signOut:&signOutError];
        if (!status) {
            NSLog(@"Error signing out: %@", signOutError);
            return;
        }
        [(AppDelegate *)[[UIApplication sharedApplication] delegate] signUpWithEmail:email password:password userName:name completion:^(BOOL success, NSString *error){
            if (success) {
                [self presentViewController:[AMRTools showMenuWithTitle:@"Success" message:nil handlers:nil] animated:YES completion: nil];
            } else {
                //TODO check connectivity
                [self presentViewController:[AMRTools showMenuWithTitle:@"Error signing up, check credentials" message:nil handlers:nil] animated:YES completion: nil];
            }
        }];
    }
    
}

- (IBAction)exit:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
