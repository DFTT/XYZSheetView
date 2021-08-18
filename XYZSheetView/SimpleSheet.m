//
//  SimpleSheet.m
//  XYZSheetView
//
//  Created by 大大东 on 2021/3/5.
//

#import "SimpleSheet.h"

@implementation SimpleSheet


- (nullable UIView *)topBarView {
    UILabel *label = [[UILabel alloc] init];
    label.backgroundColor = [UIColor redColor];
    label.text = @"热烈祝贺中华热门共和国完成第一个百年大计";
    [label.heightAnchor constraintEqualToConstant:50].active = YES;
    return label;
}
- (nonnull  UIView *)centerContentView {
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = [UIColor orangeColor];
    [view.heightAnchor constraintEqualToConstant:_tHeight].active = YES;
    
    UITextField *tf = [[UITextField alloc] init];
    tf.frame = CGRectMake(10, 20, 200, 100);
    tf.placeholder = @"我是一个输入框";
    [view addSubview:tf];
    return view;
}

@end
