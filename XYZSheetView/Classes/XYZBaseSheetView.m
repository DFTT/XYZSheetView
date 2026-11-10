//
//  XYZBaseSheetView.m
//  XYZSheetView
//
//  Created by 大大东 on 2021/2/23.
//

#import "XYZBaseSheetView.h"
#import "UIView+XYZSheetView.h"

@interface BlurEffectView : UIView
- (instancetype)initWithStyle:(XYZSheetViewBgBlurStyle)style level:(int)level;
@end

@implementation BlurEffectView
{
    UIVisualEffectView *_effectBgView;
    XYZSheetViewBgBlurStyle _style;
    UIViewPropertyAnimator *_animator;
    int _level;
}
- (instancetype)initWithStyle:(XYZSheetViewBgBlurStyle)style level:(int)level {
    if (self = [super init]) {
        _level = MAX(1, MIN(level, 100));
        _style = style;
        
        UIVisualEffectView *view = [[UIVisualEffectView alloc] init];
        [self insertSubview:view atIndex:0];
        _effectBgView = view;
        
        [self p_resetEffect];
        
    }
    return self;
}
- (void)layoutSubviews {
    _effectBgView.frame = self.bounds;
    [super layoutSubviews];
}

- (void)dealloc {
    // UIViewPropertyAnimator 停留在 paused 状态时直接释放会抛异常, 必须先停止并收尾。
    UIViewPropertyAnimator *animator = _animator;
    _animator = nil;
    if (animator.state == UIViewAnimatingStateActive) {
        [animator stopAnimation:YES];
        [animator finishAnimationAtPosition:UIViewAnimatingPositionCurrent];
    }
}

- (void)p_resetEffect {
    
    if (_animator.state == UIViewAnimatingStateActive) {
        return;
    }
    UIBlurEffectStyle stype = -1;
    switch (_style) {
        case XYZSheetViewBgBlurStyleDark:
            stype = UIBlurEffectStyleDark;
            break;
        case XYZSheetViewBgBlurStyleLight:
            stype = UIBlurEffectStyleLight;
            break;
        case XYZSheetViewBgBlurStyleExtraLight:
            stype = UIBlurEffectStyleExtraLight;
            break;
        default:
            break;
    }
    if (stype == -1) {
        return ;
    }
    _effectBgView.effect = nil;
    __weak typeof(self) weakself = self;
    _animator = [[UIViewPropertyAnimator alloc] initWithDuration:0 curve:UIViewAnimationCurveLinear animations:^{
        __strong typeof(weakself) strongself = weakself;
        if (strongself == nil) {
            return;
        }
        strongself->_effectBgView.effect = [UIBlurEffect effectWithStyle:stype];
    }];
    _animator.fractionComplete = _level / 100.0;
    _animator.pausesOnCompletion = YES;
}
@end


inline CGFloat XYZSafeAreaBottomHeight(void) {
    UIWindow *win = UIApplication.sharedApplication.delegate.window;
    if (win == nil) {
        // UIScene工程里AppDelegate通常没有window属性 需要从场景里取
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if (NO == [scene isKindOfClass:UIWindowScene.class]) {continue;}
            win = ((UIWindowScene *)scene).keyWindow;
            if (win) {break;}
        }
    }
    return win.safeAreaInsets.bottom;
}


@interface XYZBaseSheetView ()
{
    NSLayoutConstraint *_beforConst;
    NSLayoutConstraint *_afterConst;
    NSLayoutConstraint *_keyboardConst;
    NSLayoutConstraint *_maxHeightConstraint;
    NSArray<NSLayoutConstraint *> *_fullWidthConstraints;
    NSArray<NSLayoutConstraint *> *_constrainedWidthConstraints;
    
    BlurEffectView *_effectBgView;
    
    NSHashTable *_extraSubVies;
    BOOL _hiding;
    NSUInteger _hideGeneration;
}
@property(nonatomic, strong) UIView *bgContentView;
@property(nonatomic, strong) UIScrollView *centerScrollView;
@end

@implementation XYZBaseSheetView
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self p_commonSetup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self p_commonSetup];
    }
    return self;
}

- (void)p_commonSetup {
    _hideOnTouchOutside        = YES;
    _allowScrollIfOutMaxHeight = YES;
    _maxHeightScale = 0.7;
    _bgViewColor    = [[UIColor blackColor] colorWithAlphaComponent:0.3];
    _bgViewBlurLevel = 100;
    _showDuration = 0.2;
    _hideDuration = 0.2;

    _bgContentView = [[UIView alloc] init];

    self.autoAvoidKeyboard = YES;
}

/// 构建内容视图 (只构建一次, 再次show时复用)
/// 每次show都重建的话, 上一次的子视图和约束都还在, 会与新的约束冲突
- (BOOL)p_setupContentIfNeed {
    if (_afterConst != nil) {
        return YES;
    }
    UIView *centView = [self centerContentView];
    if (nil == centView) {
        NSAssert(NO, @"centerContentView must not nil");
        return NO;
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
    for (NSLayoutConstraint *heightCons in centView.constraints) {
        BOOL isHeight = (heightCons.firstItem == centView && heightCons.firstAttribute == NSLayoutAttributeHeight) ||
                        (heightCons.secondItem == centView && heightCons.secondAttribute == NSLayoutAttributeHeight);
        if (isHeight) {
            heightCons.priority = isScrollView ? 850 : 950;
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
    [self.centerScrollView setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
    [stackView addArrangedSubview:self.centerScrollView];
    if (bottView) {
        [bottView setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        [bottView setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        [stackView addArrangedSubview:bottView];
    }
    
    // 添加stackView 左右约束定宽 高度自撑大(限制最大高度)
    [self addSubview:self.bgContentView];
    self.bgContentView.translatesAutoresizingMaskIntoConstraints = NO;
    // 默认全宽; maxWidth > 0 时改用宽度+对齐约束
    _fullWidthConstraints = @[
        [self.bgContentView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.bgContentView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
    ];
    [NSLayoutConstraint activateConstraints:_fullWidthConstraints];
    [self p_syncWidthConstraints];
    // maxHeigthCons
    _maxHeightConstraint = [self.bgContentView.heightAnchor constraintLessThanOrEqualToAnchor:self.heightAnchor multiplier:self.maxHeightScale];
    _maxHeightConstraint.active = YES;
    _beforConst = [self.bgContentView.topAnchor constraintEqualToAnchor:self.bottomAnchor constant:0];
    _afterConst = [self.bgContentView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:0];
    // 键盘可见时让位给宿主的 keyboardLayoutGuide 约束。
    _afterConst.priority = 999;

    return YES;
}

- (void)showToView:(UIView *)view {
    if (view == nil) {
        return;
    }
    if (self.superview != nil) {
        if (!_hiding) {
            return;
        }
        // 隐藏动画进行中再次展示: 先立即完成隐藏, 再走正常展示流程
        _hideGeneration++;
        _hiding = NO;
        [self.layer removeAllAnimations];
        [self.bgContentView.layer removeAllAnimations];
        [self removeFromSuperview];
        self.bgContentView.transform = CGAffineTransformIdentity;
    }
    if (NO == [view.nextResponder isKindOfClass:[UIViewController class]] &&
        NO == [view isKindOfClass:[UIWindow class]]) {
        NSAssert(NO, @"only support show on UIViewController or UIWindow");
        return;
    }
    if (NO == [self p_setupContentIfNeed]) {
        return;
    }

    // add self to superView
    [view addSubview:self];
    self.accessibilityViewIsModal = YES;
    self.translatesAutoresizingMaskIntoConstraints = NO;
    [self.topAnchor constraintEqualToAnchor:view.topAnchor constant:0].active   = YES;
    [self.leftAnchor constraintEqualToAnchor:view.leftAnchor constant:0].active = YES;
    [self.bottomAnchor constraintEqualToAnchor:view.bottomAnchor constant:0].active = YES;
    [self.rightAnchor constraintEqualToAnchor:view.rightAnchor constant:0].active   = YES;
    // 此时已继承宿主的 trait, 按 horizontalSizeClass 重新决定 maxWidth 是否生效
    [self p_syncWidthConstraints];

    // 键盘位置交给宿主的 keyboardLayoutGuide, 系统随键盘动画自动布局。
    _keyboardConst.active = NO;
    _keyboardConst = [self.bgContentView.bottomAnchor constraintLessThanOrEqualToAnchor:view.keyboardLayoutGuide.topAnchor
                                                                              constant:self.avoidKeyboardOffsetY];
    [self p_syncKeyboardCompensation];
    
    // befor animation
    self.backgroundColor = [UIColor clearColor];
    UIView *blurView = [self p_tryAddEffectBgView];
    _beforConst.active = YES;
    _afterConst.active = NO;
    [self layoutIfNeeded];

    // animation
    _beforConst.active = NO;
    _afterConst.active = YES;
    _keyboardConst.active = _autoAvoidKeyboard;
    [UIView animateWithDuration:_showDuration
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
        
        if (blurView == nil) {
            self.backgroundColor = self->_bgViewColor;
        }
        [self layoutIfNeeded];
    }
                     completion:^(BOOL finished) {
        if (self.showCompletionBlock) {self.showCompletionBlock();}
    }];
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
    _hiding = YES;
    NSUInteger generation = ++_hideGeneration;


    void(^animationsBlock)(void) = ^{
        [self layoutIfNeeded];
        self.backgroundColor = [UIColor clearColor];
        if (self->_effectBgView) {
            [self->_effectBgView removeFromSuperview];
        }
    };
    void(^completionBlock)(BOOL n) = ^(BOOL n){
        // 隐藏过程中又被展示, 本次收尾作废
        if (generation != self->_hideGeneration) { return; }
        self->_hiding = NO;
        [self removeFromSuperview];
        self.accessibilityViewIsModal = NO;
        // 避让键盘的偏移复位, 否则下次show出来是歪的
        self.bgContentView.transform = CGAffineTransformIdentity;
        if (self.hideCompletionBlock) {self.hideCompletionBlock();}
    };
    _keyboardConst.active = NO;
    _afterConst.active = NO;
    _beforConst.active = YES;
    if (animation) {
        [UIView animateWithDuration:_hideDuration
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:animationsBlock
                         completion:completionBlock];
    } else {
        completionBlock(NO);
    }
}

- (UIView *)contentContainerView {
    return  _bgContentView;
}

- (void)registExtraClickAbleSubView:(UIView *)subView {
    if (subView == nil) {return;}
    if (!_extraSubVies) {_extraSubVies = [NSHashTable weakObjectsHashTable];}
    if ([_extraSubVies containsObject:subView]) {return;}
    [_extraSubVies addObject:subView];
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
    BOOL outsideContentBG = !CGRectContainsPoint(self.bgContentView.frame, point);
    BOOL outsideExtraSubview = YES;
    for (UIView *exsubview in _extraSubVies) {
        CGRect exRect = [exsubview convertRect:exsubview.bounds toView:self];
        outsideExtraSubview &= !CGRectContainsPoint(exRect, point);
    }
    if (outsideContentBG && outsideExtraSubview) {
        [self hideWithAnimation:YES];
    }else {
        [super touchesBegan:touches withEvent:event];
    }
}

- (void)setTopCornerRadius:(CGFloat)topCornerRadius {
    _topCornerRadius = topCornerRadius;
    CALayer *layer = self.bgContentView.layer;
    layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    layer.cornerRadius = MAX(0, topCornerRadius);
    layer.masksToBounds = topCornerRadius > 0;
}
#pragma mark - blurBg
- (nullable BlurEffectView *)p_tryAddEffectBgView {
    if (_bgViewBlurStyle == XYZSheetViewBgBlurStyleNone) {
        return nil;
    }
    [_effectBgView removeFromSuperview];
    _effectBgView = nil;
    
    BlurEffectView *view = [[BlurEffectView alloc] initWithStyle:_bgViewBlurStyle level:_bgViewBlurLevel];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    [self insertSubview:view atIndex:0];
    [view.topAnchor constraintEqualToAnchor:self.topAnchor].active = YES;
    [view.leadingAnchor constraintEqualToAnchor:self.leadingAnchor].active = YES;
    [view.trailingAnchor constraintEqualToAnchor:self.trailingAnchor].active = YES;
    [view.bottomAnchor constraintEqualToAnchor:self.bottomAnchor].active = YES;
    
    return _effectBgView = view;
}

#pragma mark - avoidKeyBoard
- (void)setAutoAvoidKeyboard:(BOOL)autoAvoidKeyboard {
    if (_autoAvoidKeyboard != autoAvoidKeyboard) {
        _autoAvoidKeyboard = autoAvoidKeyboard;
        _keyboardConst.active = autoAvoidKeyboard && _afterConst.isActive;
        [self p_syncKeyboardCompensation];
        [self setNeedsLayout];
    }
}

- (void)setAvoidKeyboardOffsetY:(CGFloat)avoidKeyboardOffsetY {
    _avoidKeyboardOffsetY = avoidKeyboardOffsetY;
    [self p_syncKeyboardCompensation];
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (_autoAvoidKeyboard && _afterConst.isActive && !_hiding) {
        [self p_syncKeyboardCompensation];
    }
}

// 位置完全由宿主的 keyboardLayoutGuide 驱动, 不缓存键盘坐标、不做 transform, 也不需要键盘通知。
// guide 隐藏时顶部贴在安全区底(或宿主底), 用常量把容器补回宿主底边; 被键盘顶起时只保留 offset。
- (void)p_syncKeyboardCompensation {
    UIView *host = self.superview;
    if (host == nil || _keyboardConst == nil) { return; }
    CGRect guideFrame = host.keyboardLayoutGuide.layoutFrame;
    CGFloat hiddenTop = CGRectGetMaxY(host.bounds) - host.safeAreaInsets.bottom;
    BOOL docked = CGRectGetHeight(guideFrame) > 0 && CGRectGetMinY(guideFrame) < hiddenTop - 0.5;
    CGFloat constant = docked ? _avoidKeyboardOffsetY : host.safeAreaInsets.bottom;
    if (_keyboardConst.constant != constant) { _keyboardConst.constant = constant; }
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
        scrView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        _centerScrollView = scrView;
    }
    return _centerScrollView;
}

- (void)setMaxHeightScale:(CGFloat)maxHeightScale {
    _maxHeightScale = maxHeightScale;
    if (_maxHeightConstraint && _maxHeightConstraint.multiplier != maxHeightScale) {
        // multiplier不可修改，替换约束以应用新的高度比例。
        _maxHeightConstraint.active = NO;
        _maxHeightConstraint = [self.bgContentView.heightAnchor constraintLessThanOrEqualToAnchor:self.heightAnchor multiplier:maxHeightScale];
        _maxHeightConstraint.active = YES;
    }
}

- (void)setMaxWidth:(CGFloat)maxWidth {
    _maxWidth = (!isfinite(maxWidth) || maxWidth < 0) ? 0 : maxWidth;
    [self p_syncWidthConstraints];
}

- (void)setHorizontalAlignment:(XYZSheetViewHorizontalAlignment)horizontalAlignment {
    _horizontalAlignment = horizontalAlignment;
    [self p_syncWidthConstraints];
}

- (void)p_syncWidthConstraints {
    if (_fullWidthConstraints == nil) {
        return;
    }
    [NSLayoutConstraint deactivateConstraints:_fullWidthConstraints];
    [NSLayoutConstraint deactivateConstraints:_constrainedWidthConstraints];
    _constrainedWidthConstraints = nil;

    // maxWidth 只在横向 regular 时生效, compact 下保持全宽
    BOOL usesMaxWidth = _maxWidth > 0 && self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular;
    if (!usesMaxWidth) {
        [NSLayoutConstraint activateConstraints:_fullWidthConstraints];
        [self setNeedsLayout];
        return;
    }

    // 宽度取 min(maxWidth, 安全区宽度): 999优先, 窄屏时由998回退
    NSLayoutConstraint *maxWidth = [self.bgContentView.widthAnchor constraintEqualToConstant:_maxWidth];
    maxWidth.priority = 999;
    NSLayoutConstraint *fallback = [self.bgContentView.widthAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.widthAnchor];
    fallback.priority = 998;
    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray arrayWithObjects:
        [self.bgContentView.widthAnchor constraintLessThanOrEqualToAnchor:self.safeAreaLayoutGuide.widthAnchor],
        maxWidth,
        fallback,
        nil];
    if (_horizontalAlignment == XYZSheetViewHorizontalAlignmentLeft) {
        [constraints addObject:[self.bgContentView.leadingAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.leadingAnchor]];
    } else if (_horizontalAlignment == XYZSheetViewHorizontalAlignmentRight) {
        [constraints addObject:[self.bgContentView.trailingAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.trailingAnchor]];
    } else {
        [constraints addObject:[self.bgContentView.centerXAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.centerXAnchor]];
    }
    [NSLayoutConstraint activateConstraints:constraints];
    _constrainedWidthConstraints = constraints;
    [self setNeedsLayout];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    if (self.traitCollection.horizontalSizeClass != previousTraitCollection.horizontalSizeClass) {
        [self p_syncWidthConstraints];
    }
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
{
    NSLayoutConstraint *_cancelBottomConstraint;
    CGFloat _bottomSafeInset;
}
@synthesize cancelBtn = _cancelBtn;

- (void)showToView:(UIView *)view {
    // 宿主此时已在window中, 用其当前安全区刷新底部栏 (旋转/折叠/分屏后不会固化旧值)
    _bottomSafeInset = view.safeAreaInsets.bottom;
    _cancelBottomConstraint.constant = -_bottomSafeInset;
    [super showToView:view];
}

- (void)safeAreaInsetsDidChange {
    [super safeAreaInsetsDidChange];
    _bottomSafeInset = self.safeAreaInsets.bottom;
    _cancelBottomConstraint.constant = -_bottomSafeInset;
}


- (nullable UIView *)bottomBarView {
    
    UIView *view = [[UIView alloc] init];
    
    CGFloat lineHeight = 0;
    if (NO == _hideSeparatLine) {
        lineHeight = 5;
        UIView *line = [[UIView alloc] init];
        line.backgroundColor = [UIColor systemGroupedBackgroundColor];
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
    _cancelBottomConstraint = [cancelbtn.bottomAnchor constraintEqualToAnchor:view.bottomAnchor constant:-_bottomSafeInset];
    _cancelBottomConstraint.active = YES;
    
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
