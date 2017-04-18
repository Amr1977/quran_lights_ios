//
//  FeedBackViewController.m
//  QuranGardens
//
//  Created by Amr Lotfy on 4/18/17.
//  Copyright © 2017 Amr Lotfy. All rights reserved.
//

#import "FeedBackViewController.h"

@interface FeedBackViewController ()

@property (weak, nonatomic) IBOutlet UITableView *usersFeedbacksTableView;

@property (weak, nonatomic) IBOutlet UIView *userFeedbackContainer;


@property (weak, nonatomic) IBOutlet UIView *ratingMeterContainer;

@property (weak, nonatomic) IBOutlet UITextView *userFeedbackTextView;

@property (weak, nonatomic) IBOutlet UIButton *postBtn;

@property (weak, nonatomic) IBOutlet UITextField *userFeedbackNameTextField;

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;


@property (weak, nonatomic) IBOutlet UIButton *shareBtn;


//TODO cell id: "feedbackCell"



@end

@implementation FeedBackViewController


- (IBAction)onShareTapped:(id)sender {
}




- (IBAction)onPostTapped:(id)sender {
}







- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
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

@end
