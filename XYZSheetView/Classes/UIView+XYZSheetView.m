//
//  UIView+XYZSheetView.m
//  XYZSheetView
//
//  Created by 大大东 on 2021/9/10.
//

#import "UIView+XYZSheetView.h"

@implementation UIView (XYZSheetView)

- (UIView *)findFirstResponderInSelfViewTree {
    if (self.isFirstResponder) {
        return self;
    }
    if (!self.userInteractionEnabled || self.isHidden || self.alpha < 0.01) {
        return nil;
    }
    __block UIView *targetView = nil;
    [self.subviews enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        targetView = [obj findFirstResponderInSelfViewTree];
        if (targetView) {
            *stop = YES;
        }
    }];
    return targetView;
}
@end
