//
//  MyViewController.m
//  BDVRClientSample
//
//  Created by 韩俊强 on 16/3/31.
//  Copyright © 2016年 Baidu. All rights reserved.
//

#import "MyViewController.h"

@interface MyViewController ()

@end

@implementation MyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
  
    self.view.backgroundColor = [UIColor whiteColor];
    
    UITextField *textField = [[UITextField alloc]initWithFrame:CGRectMake(8, 60, [UIScreen mainScreen].bounds.size.width - 16, 60)];
    textField.backgroundColor = [UIColor greenColor];
    textField.text = self.string;
    [self.view addSubview:textField];
    
    UIButton *btn = [[UIButton alloc]initWithFrame:CGRectMake(100, 130, 100, 50)];
    btn.backgroundColor = [UIColor orangeColor];
    [btn setTitle:@"返回" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(backVC:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
}

- (void)backVC:(UIButton*)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
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
