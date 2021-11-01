//
//  XYZBaseSheetView.m
//  XYZSheetView
//
//  Created by 大大东 on 2021/2/23.
//

#import "XYZBaseSheetView.h"
#import "UIView+XYZSheetView.h"


inline CGFloat XYZSafeAreaBottomHeight(void) {
    CGFloat bottom = 0;
    if (@available(iOS 11.0, *)) {
        bottom = UIApplication.sharedApplication.delegate.window.safeAreaInsets.bottom;
    }
    return bottom;
}


@interface XYZBaseSheetView ()
{
    NSLayoutConstraint *_beforConst;
    NSLayoutConstraint *_afterConst;
    CAShapeLayer *_maskLayer;
}
@property(nonatomic, strong) UIView *bgContentView;
@property(nonatomic, strong) UIScrollView *centerScrollView;
@end

@implementation XYZBaseSheetView
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _hideOnTouchOutside        = YES;
        _allowScrollIfOutMaxHeight = YES;
        _maxHeightScale = 0.7;
        _backAlpha    = 0.3;
        _showDuration = 0.2;
        _hideDuration = 0.2;

        _bgContentView = [[UIView alloc] init];
        
        self.autoAvoidKeyboard = YES;
    }
    return self;
}

- (void)showToView:(UIView *)view {
    if (view == nil || self.superview != nil) {
        return;
    }
    if (NO == [view.nextResponder isKindOfClass:[UIViewController class]] &&
        NO == [view isKindOfClass:[UIWindow class]]) {
        NSAssert(NO, @"only support show on UIViewController or UIWindow");
        return;
    }
    UIView *centView = [self centerContentView];
    if (nil == centView) {
        NSAssert(NO, @"centerContentView must not nil");
        return;
    }
    // centerView
    [self.centerScrollView addSubview:centView];
    centView.translatesAutoresizingMaskIntoConstraints = NO;
    [centView.topAnchor constraintEqualToAnchor:self.centerScrollView.topAnchor constant:0].active = YES;
    [centView.bottomAnchor constraintEqualToAnchor:self.centerScrollView.bottomAnchor constant:0].active = YES;
    [centView.leftAnchor constraintEqualToAnchor:self.centerScrollView.leftAnchor constant:0].active = YES;
    [centView.widthAnchor constraintEqualToAnchor:self.centerScrollView.widthAnchor constant:0].active = YES;
    // centerScrollView的窗口高度 先尽量等于centView 后面的总高度约束优先级高 会确保总高度不会超出maxHeightScale
    NSLayoutConstraint *cons = [self.centerScrollView.heightAnchor  constraintEqualToAnchor:centView.heightAnchor];
    cons.priority = 900;
    cons.active   = YES;
    BOOL isScrollView = [centView isKindOfClass:[UIScrollView class]];
    for (NSLayoutConstraint *cons in centView.constraints) {
        if (cons.firstItem == centView && cons.firstAttribute == NSLayoutAttributeHeight) {
            cons.priority = isScrollView ? 850 : 950;
            break;
        }
    }
    
    // stackView
    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.distribution = UIStackViewDistributionEqualSpacing;
    [self.bgContentView addSubview:stackView];
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    [stackView.leftAnchor constraintEqualToAnchor:self.bgContentView.leftAnchor].active = YES;
    [stackView.rightAnchor constraintEqualToAnchor:self.bgContentView.rightAnchor].active = YES;
    [stackView.topAnchor constraintEqualToAnchor:self.bgContentView.topAnchor].active = YES;
    [stackView.bottomAnchor constraintEqualToAnchor:self.bgContentView.bottomAnchor].active = YES;
    
    // topview bottomView
    UIView *topView  = [self topBarView];
    UIView *bottView = [self bottomBarView];
    
    if (topView) {
        [topView setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        [topView setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        [stackView addArrangedSubview:topView];
    }
    // 优先被压缩
    [self.centerScrollView setContentCompressionResistancePriority:NSURLSessionTaskPriorityLow forAxis:UILayoutConstraintAxisVertical];
    [stackView addArrangedSubview:self.centerScrollView];
    if (bottView) {
        [bottView setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        [bottView setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        [stackView addArrangedSubview:bottView];
    }
    
    // 添加stackView 左右约束定宽 高度自撑大(限制最大高度)
    [self addSubview:self.bgContentView];
    self.bgContentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.bgContentView.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:0].active = YES;
    [self.bgContentView.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:0].active = YES;
    // maxHeigthCons
    [self.bgContentView.heightAnchor constraintLessThanOrEqualToAnchor:self.heightAnchor multiplier:self.maxHeightScale].active = YES;
    _beforConst = [self.bgContentView.topAnchor constraintEqualToAnchor:self.bottomAnchor constant:0];
    _afterConst = [self.bgContentView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:0];

    
    // add self to superView
    [view addSubview:self];
    self.translatesAutoresizingMaskIntoConstraints = NO;
    [self.topAnchor constraintEqualToAnchor:view.topAnchor constant:0].active   = YES;
    [self.leftAnchor constraintEqualToAnchor:view.leftAnchor constant:0].active = YES;
    [self.bottomAnchor constraintEqualToAnchor:view.bottomAnchor constant:0].active = YES;
    [self.rightAnchor constraintEqualToAnchor:view.rightAnchor constant:0].active   = YES;
    
    // befor animation
    self.backgroundColor = [UIColor clearColor];
    _beforConst.active = YES;
    _afterConst.active = NO;
    [self layoutIfNeeded];
    
    // animation
    _beforConst.active = NO;
    _afterConst.active = YES;
    [UIView animateWithDuration:_showDuration
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:self.backAlpha];
        [self layoutIfNeeded];
    }
                     completion:nil];
}

//- (void)refreshSheetHegit {
//    if (!self.superview || !self.window) return;
//
//    [UIView animateWithDuration:.1 animations:^{
//        [self layoutIfNeeded];
//    }];
//}

- (void)hideWithAnimation:(BOOL)animation {
    if (!self.superview) return;

    void(^animationsBlock)(void) = ^{
        [self layoutIfNeeded];
        self.backgroundColor = [UIColor clearColor];
    };
    void(^completionBlock)(BOOL n) = ^(BOOL n){
        [self removeFromSuperview];
    };
    if (animation) {
        _afterConst.active = NO;
        _beforConst.active = YES;
        [UIView animateWithDuration:_hideDuration
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:animationsBlock
                         completion:completionBlock];
    } else {
        completionBlock(NO);
    }
}

#pragma mark - Touch
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    // 收键盘
    UIView *firstResSubView = [self findFirstResponderInSelfViewTree];
    if (firstResSubView) {
        [firstResSubView resignFirstResponder];
        return;
    }
    // 收起自己
    if (NO == _hideOnTouchOutside) {
        [super touchesBegan:touches withEvent:event];
        return;
    }
    CGPoint point = [touches.anyObject locationInView:self];
    if (!CGRectContainsPoint(self.bgContentView.frame, point)) {
        [self hideWithAnimation:YES];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    BOOL maskNot = (_topCornerRadius > 0 && !CGRectIsEmpty(_bgContentView.frame) && !_maskLayer);
    BOOL maskNeedUpdate = (_maskLayer && !CGRectEqualToRect(_maskLayer.frame, _bgContentView.bounds));
    if (maskNot || maskNeedUpdate) {
        CAShapeLayer *mask = [CAShapeLayer layer];
        mask.frame         = _bgContentView.bounds;
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:mask.bounds byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight  cornerRadii:CGSizeMake(_topCornerRadius, _topCornerRadius)];
        mask.path = path.CGPath;
        
        _bgContentView.layer.mask = _maskLayer = mask;
    }
}
#pragma mark - avoidKeyBoard
- (void)setAutoAvoidKeyboard:(BOOL)autoAvoidKeyboard {
    if (_autoAvoidKeyboard != autoAvoidKeyboard) {
        _autoAvoidKeyboard = autoAvoidKeyboard;
        if (autoAvoidKeyboard) {
            [self observeKeyboardNotify];
        }else {
            [self rmKeyboardNotifyObserver];
        }
    }
}
- (void)observeKeyboardNotify {
    [self rmKeyboardNotifyObserver];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(kb_willShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(kb_willHidden:) name:UIKeyboardWillHideNotification object:nil];
}
- (void)rmKeyboardNotifyObserver {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
}
- (void)kb_willShow:(NSNotification *)notify {
    [self p_reciveKeyboardNotification:notify frWillShow:YES];
}
- (void)kb_willHidden:(NSNotification *)notify {
    [self p_reciveKeyboardNotification:notify frWillShow:NO];
}
- (void)p_reciveKeyboardNotification:(NSNotification *)notify frWillShow:(BOOL)willShow {
    if (self.window == nil) {
        return;
    }
    if (![self findFirstResponderInSelfViewTree]) {
        return;
    }
    CGRect kbToRect = [notify.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat animationDuration = [notify.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
    
    CGRect alertRect = [self.bgContentView convertRect:self.bgContentView.bounds toView:self.window];
    
    CGFloat offsetY = CGRectGetMaxY(alertRect) - CGRectGetMinY(kbToRect);
    CGAffineTransform transf = CGAffineTransformIdentity;
    if (willShow) {
        if (offsetY <= 0) {
            return;
        }
        transf = CGAffineTransformMakeTranslation(0, -offsetY + self.avoidKeyboardOffsetY);
    }
    
    [UIView animateWithDuration:animationDuration > 0 ? animationDuration : 0.2 animations:^{
        self.bgContentView.transform = transf;
    }];
}

#pragma mark - Lazy
- (nullable UIView *)topBarView {
    return nil;
}

- (nullable UIView *)bottomBarView {
    return nil;
}

- (nonnull  UIView *)centerContentView {
    NSAssert(NO, @"subclass must override -centerContentView");
    return [UIView new];
}

#pragma mark - Get

- (UIScrollView *)centerScrollView {
    if (!_centerScrollView) {
        UIScrollView *scrView = [[UIScrollView alloc] init];
        scrView.bounces = NO;
        scrView.showsHorizontalScrollIndicator = NO;
        scrView.translatesAutoresizingMaskIntoConstraints = NO;
        if (@available(iOS 11.0, *)) {
            scrView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        _centerScrollView = scrView;
    }
    return _centerScrollView;
}

- (void)setAllowScrollIfOutMaxHeight:(BOOL)allowScrollIfOutMaxHeight {
    _allowScrollIfOutMaxHeight = allowScrollIfOutMaxHeight;
    self.centerScrollView.scrollEnabled = allowScrollIfOutMaxHeight;
    if (allowScrollIfOutMaxHeight == NO) {
        self.centerScrollView.contentOffset = CGPointZero;
    }
}
@end






@implementation XYZCommonSheetView
@synthesize cancelBtn = _cancelBtn;


- (nullable UIView *)bottomBarView {
    
    UIView *view = [[UIView alloc] init];
    
    CGFloat lineHeight = 0;
    if (NO == _hideSeparatLine) {
        lineHeight = 5;
        UIView *line = [[UIView alloc] init];
        if (@available(iOS 13.0, *)) {
            line.backgroundColor = [UIColor systemGroupedBackgroundColor];
        }else {
            line.backgroundColor = [UIColor groupTableViewBackgroundColor];
        }
        [view addSubview:line];
        line.translatesAutoresizingMaskIntoConstraints = NO;
        [line.topAnchor constraintEqualToAnchor:view.topAnchor constant:0].active = YES;
        [line.leftAnchor constraintEqualToAnchor:view.leftAnchor constant:0].active = YES;
        [line.rightAnchor constraintEqualToAnchor:view.rightAnchor constant:0].active = YES;
        [line.heightAnchor constraintEqualToConstant:lineHeight].active = YES;
    }
    
    UIButton *cancelbtn = self.cancelBtn;
    [view addSubview:cancelbtn];
    cancelbtn.translatesAutoresizingMaskIntoConstraints = NO;
    [cancelbtn.topAnchor constraintEqualToAnchor:view.topAnchor constant:lineHeight].active = YES;
    [cancelbtn.leftAnchor constraintEqualToAnchor:view.leftAnchor constant:0].active = YES;
    [cancelbtn.rightAnchor constraintEqualToAnchor:view.rightAnchor constant:0].active = YES;
    [cancelbtn.heightAnchor constraintEqualToConstant:49].active = YES;
    CGFloat bCons = -(XYZSafeAreaBottomHeight());
    [cancelbtn.bottomAnchor constraintEqualToAnchor:view.bottomAnchor constant:bCons].active = YES;
        
    view.backgroundColor = self.cancelBtn.backgroundColor;
    return view;
}
#pragma mark Action
- (void)cancelBtnAction {
    if (_cancelBtnClick) {
        _cancelBtnClick();
    }
    [self hideWithAnimation:YES];
}
#pragma mark Get
- (UIButton *)cancelBtn {
    if (!_cancelBtn) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.backgroundColor = [UIColor whiteColor];
        btn.titleLabel.font = [UIFont systemFontOfSize:17];
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [btn setTitle:@"取消" forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(cancelBtnAction) forControlEvents:UIControlEventTouchUpInside];
        _cancelBtn = btn;
    }
    return _cancelBtn;
}
@end
