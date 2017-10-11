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
#import "MBProgressHUD.h"
#import "FireBaseManager.h"


@interface SignupViewController ()

@property (weak, nonatomic) IBOutlet UITextField *email;
@property (weak, nonatomic) IBOutlet UITextField *password;

@property (weak, nonatomic) IBOutlet UIButton *showPassword;
@property (weak, nonatomic) IBOutlet UIButton *signup;
@property (weak, nonatomic) IBOutlet UIButton *signin;
@property (weak, nonatomic) IBOutlet UIButton *reset;

@end

@implementation SignupViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(tap)];
    
    [self.view addGestureRecognizer:tap];
    
    [self.navigationController.navigationBar setTitleTextAttributes:
     @{NSForegroundColorAttributeName:[UIColor whiteColor]}];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if([FireBaseManager shared].userID != nil) {
        NSString *email = [[NSUserDefaults standardUserDefaults] stringForKey:@"email"];
        NSString *password = [[NSUserDefaults standardUserDefaults] stringForKey:@"password"];
        
        self.email.text = email;
        self.password.text = password;
        self.title = @"Signed in";
    } else {
        self.title = @"Sign in to cloud";
    }
}

- (void)tap{
    [self.email resignFirstResponder];
    [self.password resignFirstResponder];
}

- (IBAction)onSignin:(id)sender {
    NSString *email = self.email.text;
    NSString *password = self.password.text;
    
    if (![email isEqualToString:@""] && ![password isEqualToString:@""] && [AMRTools isValidEmail:email]) {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [[FireBaseManager shared] signInWithEmail:email password:password completion:^(BOOL success, NSString *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:self.view animated:YES];
            });
            if (success) {
                [self.navigationController popViewControllerAnimated:YES];
            } else {
                [self presentViewController:[AMRTools showMenuWithTitle:@"Error signing in" message:error  handlers:nil] animated:YES completion: nil];
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
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [[FireBaseManager shared] signUpWithEmail:email password:password completion:^(BOOL success, NSString *error){
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:self.view animated:YES];
            });
            if (success) {
                [self.navigationController popViewControllerAnimated:YES];
            } else {
                //TODO check connectivity
                [self presentViewController:[AMRTools showMenuWithTitle:@"Error signing up" message:error handlers:nil] animated:YES completion: nil];
            }
        }];
    } else {
       [self presentViewController:[AMRTools showMenuWithTitle:@"Invalid email/password" message:nil  handlers:nil] animated:YES completion: nil];
    }
}

- (IBAction)resetPassword {
    if ([AMRTools isValidEmail:self.email.text]) {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [[FIRAuth auth] sendPasswordResetWithEmail:self.email.text completion:^(NSError *_Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:self.view animated:YES];
            });
            if (error == nil) {
                [AMRTools showMenuWithTitle:@"Check your mail!"
                                    message:@"Verification mail sent"
                             viewController:self
                                  okHandler:nil
                              cancelHandler:nil];
            } else {
                [AMRTools showMenuWithTitle:@"Error!"
                                    message:[error localizedDescription]
                             viewController:self
                                  okHandler:nil
                              cancelHandler:nil];
            }
        }];
    } else {
        [AMRTools showMenuWithTitle:@"Invalid mail!"
                            message:nil
                     viewController:self
                          okHandler:nil
                      cancelHandler:nil];
    }
}


- (IBAction)toggleShowPassword:(id)sender {
    self.password.secureTextEntry = !self.password.secureTextEntry;
}

- (IBAction)onSignOut:(id)sender {
    [FireBaseManager shared].userID = nil;
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"email"];
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"password"];
    NSError *error;
    [[FIRAuth auth] signOut:&error];
    self.email.text = nil;
    self.password.text = nil;
    self.title = @"Sign in to cloud";
    
}



@end
