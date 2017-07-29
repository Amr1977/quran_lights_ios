//
//  SignupViewController.m
//  QuranGardens
//
//  Created by Amr Lotfy on 7/29/17.
//  Copyright © 2017 Amr Lotfy. All rights reserved.
//

#import "SignupViewController.h"
#import "AppDelegate.h"
#import "AMRTools.h"


@interface SignupViewController ()

@property (weak, nonatomic) IBOutlet UITextField *email;
@property (weak, nonatomic) IBOutlet UITextField *password;

@end

@implementation SignupViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(tap)];
    
    [self.view addGestureRecognizer:tap];
}

- (void)tap{
    [self.email resignFirstResponder];
    [self.password resignFirstResponder];
}

- (IBAction)onSignin:(id)sender {
    NSString *email = self.email.text;
    NSString *password = self.password.text;
    
    if (![email isEqualToString:@""] && ![password isEqualToString:@""] && [AMRTools isValidEmail:email]) {
        [(AppDelegate *)[[UIApplication sharedApplication] delegate] signInWithEmail:email password:password completion:^(BOOL success, NSString *error) {
            if (success) {
                [self.navigationController popViewControllerAnimated:YES];
            } else {
                [self presentViewController:[AMRTools showMenuWithTitle:@"Error signing in, check credentials" message:error  handlers:nil] animated:YES completion: nil];
            }
        }];
    } else {
        [self presentViewController:[AMRTools showMenuWithTitle:@"Invalid email/password" message:nil  handlers:nil] animated:YES completion: nil];
    }
}

- (IBAction)onSignUp:(id)sender {
    NSString *email = self.email.text;
    NSString *password = self.password.text;
    
    if (![email isEqualToString:@""] && ![password isEqualToString:@""] && [AMRTools isValidEmail:email]) {
        [(AppDelegate *)[[UIApplication sharedApplication] delegate] signUpWithEmail:email password:password completion:^(BOOL success, NSString *error){
            if (success) {
                [self.navigationController popViewControllerAnimated:YES];
            } else {
                //TODO check connectivity
                [self presentViewController:[AMRTools showMenuWithTitle:@"Error signing up, check credentials" message:error handlers:nil] animated:YES completion: nil];
            }
        }];
    } else {
       [self presentViewController:[AMRTools showMenuWithTitle:@"Invalid email/password" message:nil  handlers:nil] animated:YES completion: nil];
    }
}

@end
