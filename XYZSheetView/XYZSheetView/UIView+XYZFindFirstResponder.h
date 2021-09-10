//
//  UIView+XYZFindFirstResponder.h
//  XYZSheetView
//
//  Created by 大大东 on 2021/9/10.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (XYZFindFirstResponder)

/// 从自身开始深度遍历寻找为第一响应者的子视图
- (nullable UIView *)findFirstResponderInSelfViewTree;

@end

NS_ASSUME_NONNULL_END
