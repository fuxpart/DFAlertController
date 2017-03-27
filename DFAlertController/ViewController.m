//
//  ViewController.m
//  DFAlertController
//
//  Created by fuxp on 2017/3/27.
//  Copyright © 2017年 fuxp. All rights reserved.
//

#import "ViewController.h"
#import "DFAlertController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)logIn:(UIButton *)sender {
    DFAlertController *alert = [DFAlertController alertControllerWithTitle:@"Log in" message:nil];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"User name";
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.keyboardType = UIKeyboardTypeASCIICapable;
    }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"Password";
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.keyboardType = UIKeyboardTypeASCIICapable;
        textField.secureTextEntry = YES;
    }];
    DFAlertAction *cancel = [DFAlertAction actionWithTitle:@"Cancel" handler:nil];
    DFAlertAction *ok = [DFAlertAction actionWithTitle:@"OK" handler:^(DFAlertAction * _Nonnull action) {
        NSLog(@"user name: %@", [action.controller.textFields firstObject].text);
        NSLog(@"password: %@", [action.controller.textFields lastObject].text);
    }];
    [alert addAction:cancel];
    [alert addAction:ok];
    [alert show];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
