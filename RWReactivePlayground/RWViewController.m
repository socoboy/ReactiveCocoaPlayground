//
//  RWViewController.m
//  RWReactivePlayground
//
//  Created by Colin Eberhardt on 18/12/2013.
//  Copyright (c) 2013 Colin Eberhardt. All rights reserved.
//

#import "RWViewController.h"
#import "RWDummySignInService.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <MBProgressHUD/MBProgressHUD.h>

@interface RWViewController ()

@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *signInButton;
@property (weak, nonatomic) IBOutlet UILabel *signInFailureText;

@property (strong, nonatomic) RWDummySignInService *signInService;

- (RACSignal *)signInSignal;
@end

@implementation RWViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.signInService = [RWDummySignInService new];
    
    // initially hide the failure message
    self.signInFailureText.hidden = YES;
    
    RACSignal *validUserSignal = [self.usernameTextField.rac_textSignal map:^id(NSString *text) {
        return @([self isValidUsername:text]);
    }];
    
    RACSignal *validPasswordSignal = [self.passwordTextField.rac_textSignal map:^id(NSString *text) {
        return @([self isValidPassword:text]);
    }];
    
    RAC(self.usernameTextField, backgroundColor) = [validUserSignal map:^id(NSNumber *isValid) {
        return isValid.boolValue ? [UIColor clearColor] : [UIColor yellowColor];
    }];
    
    RAC(self.passwordTextField, backgroundColor) = [validPasswordSignal map:^id(NSNumber *isValid) {
        return isValid.boolValue ? [UIColor clearColor] : [UIColor yellowColor];
    }];
    
    RAC(self.signInButton, enabled) = [RACSignal combineLatest:@[validUserSignal, validPasswordSignal] reduce:^id(NSNumber *userValid, NSNumber *passowordValid){
        return @(userValid.boolValue && passowordValid.boolValue);
    }];
    
    [[[[self.signInButton rac_signalForControlEvents:UIControlEventTouchUpInside] doNext:^(id x) {
        [self.view endEditing:YES];
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.signInButton.enabled = NO;
        self.signInFailureText.hidden = YES;
    }] flattenMap:^RACStream *(id value) {
        return [self signInSignal];
    }] subscribeNext:^(NSNumber *signedIn) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        self.signInButton.enabled = YES;
        self.signInFailureText.hidden = signedIn.boolValue;
        if (signedIn.boolValue) {
            [self performSegueWithIdentifier:@"signInSuccess" sender:self];
        }
    }];
}

- (BOOL)isValidUsername:(NSString *)username {
  return username.length > 3;
}

- (BOOL)isValidPassword:(NSString *)password {
  return password.length > 3;
}

- (RACSignal *)signInSignal {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [self.signInService signInWithUsername:self.usernameTextField.text
                                      password:self.passwordTextField.text
                                      complete:^(BOOL success) {
                                          [subscriber sendNext:@(success)];
                                          [subscriber sendCompleted];
                                      }];
        return nil;
    }];
}

@end
