#import <XCTest/XCTest.h>
#import "XYZListSheet.h"

// 用约束固定 guide 的垂直位置来模拟键盘弹出/收起，无需弹出系统键盘。
@interface XYZTestKeyboardGuide : UIKeyboardLayoutGuide
@end
@implementation XYZTestKeyboardGuide
@end

@interface XYZTestHostView : UIView
@property (nonatomic, strong) XYZTestKeyboardGuide *testGuide;
@property (nonatomic, strong) NSLayoutConstraint *guideTopConstraint;
@property (nonatomic, strong) NSLayoutConstraint *guideHeightConstraint;
@end
@implementation XYZTestHostView
- (UIEdgeInsets)safeAreaInsets { return UIEdgeInsetsMake(0, 0, 34, 0); }
- (UIKeyboardLayoutGuide *)keyboardLayoutGuide { return self.testGuide; }
@end

@interface XYZLandscapeHostView : UIView
@end
@implementation XYZLandscapeHostView
- (UIEdgeInsets)safeAreaInsets { return UIEdgeInsetsMake(0, 0, 21, 86); }
@end

@interface XYZTraitListSheet : XYZListSheet
@property (nonatomic, strong) UITraitCollection *testTraits;
@end
@implementation XYZTraitListSheet
- (UITraitCollection *)traitCollection {
    return self.testTraits ?: [super traitCollection];
}
@end

// iOS 17+ 语义: 键盘隐藏时 guide 顶部贴宿主底边。
static void XYZPinKeyboardGuide(XYZTestHostView *host, CGFloat top, CGFloat height) {
    if (host.guideTopConstraint == nil) {
        host.guideTopConstraint = [host.testGuide.topAnchor constraintEqualToAnchor:host.topAnchor constant:top];
        host.guideHeightConstraint = [host.testGuide.heightAnchor constraintEqualToConstant:height];
        host.guideTopConstraint.active = YES;
        host.guideHeightConstraint.active = YES;
    } else {
        host.guideTopConstraint.constant = top;
        host.guideHeightConstraint.constant = height;
    }
    [host setNeedsLayout];
    [host layoutIfNeeded];
}

static NSLayoutConstraint *XYZKeyboardConstraint(XYZBaseSheetView *sheet, XYZTestHostView *host) {
    for (NSLayoutConstraint *constraint in host.constraints) {
        if (constraint.firstItem == sheet.contentContainerView && constraint.secondItem == host.testGuide &&
            constraint.firstAttribute == NSLayoutAttributeBottom && constraint.relation == NSLayoutRelationLessThanOrEqual) {
            return constraint;
        }
    }
    return nil;
}

static UITableView *XYZFindTableView(UIView *root) {
    if ([root isKindOfClass:UITableView.class]) { return (UITableView *)root; }
    for (UIView *subview in root.subviews) {
        UITableView *table = XYZFindTableView(subview);
        if (table) { return table; }
    }
    return nil;
}

static BOOL XYZContainsVisualEffectView(UIView *root) {
    if ([root isKindOfClass:UIVisualEffectView.class]) { return YES; }
    for (UIView *subview in root.subviews) {
        if (XYZContainsVisualEffectView(subview)) { return YES; }
    }
    return NO;
}

static XYZListSheet *XYZMakeSheet(void) {
    XYZListSheet *sheet = [[XYZListSheet alloc] init];
    sheet.showDuration = 0;
    [sheet.actions addObject:[XYZListSheetAction actionWithName:@"Action" action:nil]];
    return sheet;
}

@interface XYZBaseSheetViewTests : XCTestCase
@end

@implementation XYZBaseSheetViewTests

- (void)testMaxHeightScaleAppliesWhenReusingSheet {
    UIViewController *host = [[UIViewController alloc] init];
    host.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 400, 1000)];
    XYZListSheet *sheet = [[XYZListSheet alloc] init];
    sheet.autoAvoidKeyboard = NO;
    sheet.showDuration = 0;
    for (NSUInteger index = 0; index < 30; index++) {
        [sheet.actions addObject:[XYZListSheetAction actionWithName:@"Action" action:nil]];
    }

    for (NSNumber *scale in @[@0.7, @0.3, @0.8, @0.8]) {
        sheet.maxHeightScale = scale.doubleValue;
        [sheet showToView:host.view];
        [host.view layoutIfNeeded];
        [sheet layoutIfNeeded];
        XCTAssertEqualWithAccuracy(sheet.contentContainerView.bounds.size.height,
                                   host.view.bounds.size.height * scale.doubleValue, 0.5);
        [sheet hideWithAnimation:NO];
    }
}

- (void)testKeyboardAvoidanceFollowsGuideAndOffset {
    UIViewController *host = [[UIViewController alloc] init];
    XYZTestHostView *view = [[XYZTestHostView alloc] initWithFrame:CGRectMake(0, 0, 400, 1000)];
    view.testGuide = [[XYZTestKeyboardGuide alloc] init];
    [view addLayoutGuide:view.testGuide];
    host.view = view;
    XYZPinKeyboardGuide(view, 966, 34);

    XYZListSheet *sheet = XYZMakeSheet();
    [sheet showToView:view];
    [view layoutIfNeeded];
    [sheet layoutIfNeeded];

    NSLayoutConstraint *keyboardConstraint = XYZKeyboardConstraint(sheet, view);
    XCTAssertNotNil(keyboardConstraint);
    XCTAssertTrue(keyboardConstraint.active);
    XCTAssertEqual(keyboardConstraint.constant, 34);
    XCTAssertEqualWithAccuracy(CGRectGetMaxY(sheet.contentContainerView.frame), 1000, 0.5);

    // guide 被顶起 => 容器跟随, 内容尺寸不变
    CGSize contentSize = sheet.contentContainerView.bounds.size;
    XYZPinKeyboardGuide(view, 700, 300);
    [sheet layoutIfNeeded];
    XCTAssertEqual(keyboardConstraint.constant, 0);
    XCTAssertEqualWithAccuracy(CGRectGetMaxY(sheet.contentContainerView.frame), 700, 0.5);
    XCTAssertEqualWithAccuracy(sheet.contentContainerView.bounds.size.height, contentSize.height, 0.5);

    // offset 直接作用于约束常量: 正值减小避让, 负值增加避让
    sheet.avoidKeyboardOffsetY = 30;
    [view layoutIfNeeded];
    [sheet layoutIfNeeded];
    XCTAssertEqual(keyboardConstraint.constant, 30);
    XCTAssertEqualWithAccuracy(CGRectGetMaxY(sheet.contentContainerView.frame), 730, 0.5);

    sheet.avoidKeyboardOffsetY = -30;
    [view layoutIfNeeded];
    [sheet layoutIfNeeded];
    XCTAssertEqual(keyboardConstraint.constant, -30);
    XCTAssertEqualWithAccuracy(CGRectGetMaxY(sheet.contentContainerView.frame), 670, 0.5);
    sheet.avoidKeyboardOffsetY = 0;

    // 关闭避让: 约束失效, 内容回到宿主底; 重新开启复用同一约束
    sheet.autoAvoidKeyboard = NO;
    XCTAssertFalse(keyboardConstraint.active);
    [view layoutIfNeeded];
    [sheet layoutIfNeeded];
    XCTAssertEqualWithAccuracy(CGRectGetMaxY(sheet.contentContainerView.frame), 1000, 0.5);

    sheet.autoAvoidKeyboard = YES;
    XCTAssertTrue(keyboardConstraint.active);
    [view layoutIfNeeded];
    [sheet layoutIfNeeded];
    XCTAssertEqualWithAccuracy(CGRectGetMaxY(sheet.contentContainerView.frame), 700, 0.5);

    // 重新展示: 约束按新宿主重建, 无键盘时仍贴底
    XYZPinKeyboardGuide(view, 966, 34);
    [sheet hideWithAnimation:NO];
    [sheet showToView:view];
    [view layoutIfNeeded];
    [sheet layoutIfNeeded];
    NSLayoutConstraint *newConstraint = XYZKeyboardConstraint(sheet, view);
    XCTAssertNotNil(newConstraint);
    XCTAssertTrue(newConstraint.active);
    XCTAssertEqual(newConstraint.constant, 34);
    XCTAssertEqualWithAccuracy(CGRectGetMaxY(sheet.contentContainerView.frame), 1000, 0.5);
    [sheet hideWithAnimation:NO];
}

- (void)testKeyboardAvoidanceTracksGuideAcrossHostResize {
    UIViewController *host = [[UIViewController alloc] init];
    XYZTestHostView *view = [[XYZTestHostView alloc] initWithFrame:CGRectMake(25, 31, 951, 669)];
    view.testGuide = [[XYZTestKeyboardGuide alloc] init];
    [view addLayoutGuide:view.testGuide];
    host.view = view;
    UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 1000, 1000)];
    [window addSubview:view];
    XYZPinKeyboardGuide(view, 369, 300);

    XYZListSheet *sheet = XYZMakeSheet();
    [sheet showToView:view];
    [view layoutIfNeeded];
    [sheet layoutIfNeeded];
    CGSize contentSize = sheet.contentContainerView.bounds.size;
    XCTAssertEqualWithAccuracy(CGRectGetMaxY(sheet.contentContainerView.frame), 369, 0.5);

    // 折叠: 宿主与 guide 一起变, 位置跟随新 guide, 内容高度不变
    view.frame = CGRectMake(25, 31, 466, 678);
    XYZPinKeyboardGuide(view, 409, 269);
    [view layoutIfNeeded];
    [sheet layoutIfNeeded];
    XCTAssertEqualWithAccuracy(CGRectGetMaxY(sheet.contentContainerView.frame), 409, 0.5);
    XCTAssertEqualWithAccuracy(sheet.contentContainerView.bounds.size.height, contentSize.height, 0.5);
    XCTAssertEqual(XYZKeyboardConstraint(sheet, view).constant, 0);

    // 键盘收起: guide 回到底部, 容器贴底
    XYZPinKeyboardGuide(view, 644, 34);
    [view layoutIfNeeded];
    [sheet layoutIfNeeded];
    XCTAssertEqual(XYZKeyboardConstraint(sheet, view).constant, 34);
    XCTAssertEqualWithAccuracy(CGRectGetMaxY(sheet.contentContainerView.frame), 678, 0.5);
    [sheet hideWithAnimation:NO];
}

- (void)testTopCornersCanChangeAndClearAcrossSizes {
    XYZListSheet *sheet = [[XYZListSheet alloc] init];
    CALayer *layer = sheet.contentContainerView.layer;
    sheet.topCornerRadius = 16;
    XCTAssertEqual(layer.cornerRadius, 16);
    XCTAssertEqual(layer.maskedCorners, kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner);
    XCTAssertTrue(layer.masksToBounds);
    sheet.contentContainerView.bounds = CGRectMake(0, 0, 500, 300);
    sheet.topCornerRadius = 24;
    XCTAssertEqual(layer.cornerRadius, 24);
    sheet.topCornerRadius = 0;
    XCTAssertEqual(layer.cornerRadius, 0);
    XCTAssertFalse(layer.masksToBounds);
    sheet.topCornerRadius = -1;
    XCTAssertEqual(layer.cornerRadius, 0);
}

- (void)testMaxWidthAndHorizontalAlignment {
    UIViewController *host = [[UIViewController alloc] init];
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 400, 1000)];
    host.view = view;

    XYZTraitListSheet *sheet = [[XYZTraitListSheet alloc] init];
    sheet.testTraits = [UITraitCollection traitCollectionWithHorizontalSizeClass:UIUserInterfaceSizeClassRegular];
    sheet.autoAvoidKeyboard = NO;
    sheet.showDuration = 0;
    [sheet.actions addObject:[XYZListSheetAction actionWithName:@"Action" action:nil]];

    sheet.maxWidth = 300;
    [sheet showToView:view];
    [view layoutIfNeeded];
    UIView *content = sheet.contentContainerView;
    XCTAssertEqualWithAccuracy(CGRectGetWidth(content.frame), 300, 0.5);
    XCTAssertEqualWithAccuracy(CGRectGetMidX(content.frame), 200, 0.5);

    sheet.horizontalAlignment = XYZSheetViewHorizontalAlignmentLeft;
    [view layoutIfNeeded];
    [sheet layoutIfNeeded];
    XCTAssertEqualWithAccuracy(CGRectGetMinX(content.frame), 0, 0.5);

    sheet.horizontalAlignment = XYZSheetViewHorizontalAlignmentRight;
    [view layoutIfNeeded];
    [sheet layoutIfNeeded];
    XCTAssertEqualWithAccuracy(CGRectGetMaxX(content.frame), 400, 0.5);

    // 超过宿主宽度时回退为安全区宽度
    sheet.maxWidth = 500;
    [view layoutIfNeeded];
    [sheet layoutIfNeeded];
    XCTAssertEqualWithAccuracy(CGRectGetWidth(content.frame), 400, 0.5);

    // 恢复全宽
    sheet.maxWidth = 0;
    sheet.horizontalAlignment = XYZSheetViewHorizontalAlignmentCenter;
    [view layoutIfNeeded];
    [sheet layoutIfNeeded];
    XCTAssertEqualWithAccuracy(CGRectGetWidth(content.frame), 400, 0.5);
    XCTAssertEqualWithAccuracy(CGRectGetMinX(content.frame), 0, 0.5);

    for (NSNumber *invalidWidth in @[@(INFINITY), @(-INFINITY), @(NAN), @(-1)]) {
        sheet.maxWidth = 300;
        XCTAssertNoThrow(sheet.maxWidth = invalidWidth.doubleValue);
        XCTAssertEqual(sheet.maxWidth, 0);
        [view layoutIfNeeded];
        [sheet layoutIfNeeded];
        XCTAssertEqualWithAccuracy(CGRectGetWidth(content.frame), 400, 0.5);
    }

    [sheet hideWithAnimation:NO];
}

- (void)testMaxWidthOnlyAppliesInRegularWidth {
    UIViewController *host = [[UIViewController alloc] init];
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 400, 1000)];
    host.view = view;

    XYZTraitListSheet *sheet = [[XYZTraitListSheet alloc] init];
    sheet.testTraits = [UITraitCollection traitCollectionWithHorizontalSizeClass:UIUserInterfaceSizeClassRegular];
    sheet.autoAvoidKeyboard = NO;
    sheet.showDuration = 0;
    [sheet.actions addObject:[XYZListSheetAction actionWithName:@"Action" action:nil]];
    sheet.maxWidth = 300;
    [sheet showToView:view];
    [view layoutIfNeeded];
    [sheet layoutIfNeeded];
    UIView *content = sheet.contentContainerView;
    XCTAssertEqualWithAccuracy(CGRectGetWidth(content.frame), 300, 0.5);

    // compact: maxWidth 不生效, 保持全宽
    UITraitCollection *regular = sheet.testTraits;
    sheet.testTraits = [UITraitCollection traitCollectionWithHorizontalSizeClass:UIUserInterfaceSizeClassCompact];
    [sheet traitCollectionDidChange:regular];
    [view layoutIfNeeded];
    [sheet layoutIfNeeded];
    XCTAssertEqualWithAccuracy(CGRectGetWidth(content.frame), 400, 0.5);

    // 回到 regular: 属性值保留, 重新生效
    UITraitCollection *compact = sheet.testTraits;
    sheet.testTraits = regular;
    [sheet traitCollectionDidChange:compact];
    [view layoutIfNeeded];
    [sheet layoutIfNeeded];
    XCTAssertEqualWithAccuracy(CGRectGetWidth(content.frame), 300, 0.5);

    // compact 下调整 alignment 不应产生偏移
    sheet.testTraits = compact;
    [sheet traitCollectionDidChange:regular];
    sheet.horizontalAlignment = XYZSheetViewHorizontalAlignmentLeft;
    [view layoutIfNeeded];
    [sheet layoutIfNeeded];
    XCTAssertEqualWithAccuracy(CGRectGetWidth(content.frame), 400, 0.5);
    XCTAssertEqualWithAccuracy(CGRectGetMinX(content.frame), 0, 0.5);
    [sheet hideWithAnimation:NO];
}

- (void)testMaxWidthMatchesCurrentHorizontalSizeClass {
    UIViewController *host = [[UIViewController alloc] init];
    UIWindow *window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    host.view = [[UIView alloc] initWithFrame:window.bounds];
    window.rootViewController = host;
    [window makeKeyAndVisible];

    XYZListSheet *sheet = [[XYZListSheet alloc] init];
    sheet.autoAvoidKeyboard = NO;
    sheet.showDuration = 0;
    [sheet.actions addObject:[XYZListSheetAction actionWithName:@"Action" action:nil]];
    sheet.maxWidth = 300;
    [sheet showToView:host.view];
    [host.view layoutIfNeeded];
    [sheet layoutIfNeeded];

    CGFloat hostWidth = CGRectGetWidth(host.view.bounds);
    BOOL regular = sheet.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular;
    CGFloat expected = regular ? MIN(300, hostWidth) : hostWidth;
    XCTAssertEqualWithAccuracy(CGRectGetWidth(sheet.contentContainerView.frame), expected, 0.5);
    [sheet hideWithAnimation:NO];
}

- (void)testTraitOverridePropagationUpdatesMaxWidth {
    UIViewController *parent = [[UIViewController alloc] init];
    UIViewController *child = [[UIViewController alloc] init];
    parent.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 600, 1000)];
    child.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 600, 1000)];
    [parent addChildViewController:child];
    [parent.view addSubview:child.view];
    [child didMoveToParentViewController:parent];
    UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 600, 1000)];
    window.rootViewController = parent;
    [window makeKeyAndVisible];

    // 用 override trait 走真实的 trait 传播路径, 而不是手动调 traitCollectionDidChange
    [parent setOverrideTraitCollection:[UITraitCollection traitCollectionWithHorizontalSizeClass:UIUserInterfaceSizeClassRegular]
                 forChildViewController:child];

    XYZListSheet *sheet = XYZMakeSheet();
    sheet.autoAvoidKeyboard = NO;
    sheet.maxWidth = 300;
    [sheet showToView:child.view];
    [parent.view layoutIfNeeded];
    [sheet layoutIfNeeded];
    XCTAssertEqualWithAccuracy(CGRectGetWidth(sheet.contentContainerView.frame), 300, 0.5);

    [parent setOverrideTraitCollection:[UITraitCollection traitCollectionWithHorizontalSizeClass:UIUserInterfaceSizeClassCompact]
                 forChildViewController:child];
    [parent.view layoutIfNeeded];
    [sheet layoutIfNeeded];
    XCTAssertEqualWithAccuracy(CGRectGetWidth(sheet.contentContainerView.frame), 600, 0.5);

    [sheet hideWithAnimation:NO];
}

- (void)testReshowOnAnotherHostRebuildsConstraints {
    UIViewController *hostA = [[UIViewController alloc] init];
    UIView *viewA = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 400, 1000)];
    hostA.view = viewA;
    UIViewController *hostB = [[UIViewController alloc] init];
    UIView *viewB = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 800)];
    hostB.view = viewB;

    XYZListSheet *sheet = XYZMakeSheet();
    [sheet showToView:viewA];
    [viewA layoutIfNeeded];
    [sheet layoutIfNeeded];
    XCTAssertEqualWithAccuracy(CGRectGetMaxY(sheet.contentContainerView.frame), 1000, 0.5);
    [sheet hideWithAnimation:NO];

    [sheet showToView:viewB];
    [viewB layoutIfNeeded];
    [sheet layoutIfNeeded];
    XCTAssertEqualWithAccuracy(CGRectGetWidth(sheet.bounds), 300, 0.5);
    XCTAssertEqualWithAccuracy(CGRectGetHeight(sheet.bounds), 800, 0.5);
    XCTAssertEqualWithAccuracy(CGRectGetMaxY(sheet.contentContainerView.frame), 800, 0.5);
    XCTAssertTrue(sheet.superview == viewB);
    [sheet hideWithAnimation:NO];
}

- (void)testMaxWidthKeepsKeyboardAvoidance {
    UIViewController *host = [[UIViewController alloc] init];
    XYZTestHostView *view = [[XYZTestHostView alloc] initWithFrame:CGRectMake(0, 0, 400, 1000)];
    view.testGuide = [[XYZTestKeyboardGuide alloc] init];
    [view addLayoutGuide:view.testGuide];
    host.view = view;
    XYZPinKeyboardGuide(view, 700, 300);

    XYZTraitListSheet *sheet = [[XYZTraitListSheet alloc] init];
    sheet.testTraits = [UITraitCollection traitCollectionWithHorizontalSizeClass:UIUserInterfaceSizeClassRegular];
    sheet.showDuration = 0;
    [sheet.actions addObject:[XYZListSheetAction actionWithName:@"Action" action:nil]];
    sheet.maxWidth = 300;
    [sheet showToView:view];
    [view layoutIfNeeded];
    [sheet layoutIfNeeded];

    XCTAssertEqualWithAccuracy(CGRectGetWidth(sheet.contentContainerView.frame), 300, 0.5);
    XCTAssertEqualWithAccuracy(CGRectGetMaxY(sheet.contentContainerView.frame), 700, 0.5);

    // 切到 compact: 宽度恢复全宽, 键盘避让位置不变
    UITraitCollection *regular = sheet.testTraits;
    sheet.testTraits = [UITraitCollection traitCollectionWithHorizontalSizeClass:UIUserInterfaceSizeClassCompact];
    [sheet traitCollectionDidChange:regular];
    [view layoutIfNeeded];
    [sheet layoutIfNeeded];
    XCTAssertEqualWithAccuracy(CGRectGetWidth(sheet.contentContainerView.frame), 400, 0.5);
    XCTAssertEqualWithAccuracy(CGRectGetMaxY(sheet.contentContainerView.frame), 700, 0.5);
    [sheet hideWithAnimation:NO];
}

- (void)testKeyboardAvoidanceWhenShownWithKeyboardVisible {
    UIViewController *host = [[UIViewController alloc] init];
    XYZTestHostView *view = [[XYZTestHostView alloc] initWithFrame:CGRectMake(0, 0, 400, 1000)];
    view.testGuide = [[XYZTestKeyboardGuide alloc] init];
    [view addLayoutGuide:view.testGuide];
    host.view = view;
    XYZPinKeyboardGuide(view, 700, 300);

    XYZListSheet *sheet = XYZMakeSheet();
    sheet.avoidKeyboardOffsetY = -20;
    [sheet showToView:view];
    [view layoutIfNeeded];
    [sheet layoutIfNeeded];

    NSLayoutConstraint *keyboardConstraint = XYZKeyboardConstraint(sheet, view);
    XCTAssertNotNil(keyboardConstraint);
    XCTAssertTrue(keyboardConstraint.active);
    XCTAssertEqual(keyboardConstraint.constant, -20);
    XCTAssertEqualWithAccuracy(CGRectGetMaxY(sheet.contentContainerView.frame), 680, 0.5);
    [sheet hideWithAnimation:NO];
}

- (void)testListRowsSpanFullWidthWithHorizontalSafeArea {
    UIViewController *host = [[UIViewController alloc] init];
    XYZLandscapeHostView *view = [[XYZLandscapeHostView alloc] initWithFrame:CGRectMake(0, 0, 951, 669)];
    host.view = view;

    XYZListSheet *sheet = [[XYZListSheet alloc] init];
    sheet.showDuration = 0;
    for (int i = 0; i < 3; i++) {
        [sheet.actions addObject:[XYZListSheetAction actionWithName:@"哈哈哈哈" action:nil]];
    }
    [sheet showToView:view];
    [view layoutIfNeeded];
    [sheet layoutIfNeeded];

    UIView *content = sheet.contentContainerView;
    UITableView *table = XYZFindTableView(content);
    XCTAssertNotNil(table);
    UITableViewCell *cell = [table cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    XCTAssertNotNil(cell);

    // 左右安全区不应内缩行内容, 否则会和全宽的取消栏对不齐
    CGFloat contentWidth = CGRectGetWidth(content.frame);
    XCTAssertEqualWithAccuracy(CGRectGetMinX(cell.contentView.frame), 0, 0.5);
    XCTAssertEqualWithAccuracy(CGRectGetWidth(cell.contentView.frame), contentWidth, 0.5);
    CGRect cancelRect = [sheet.cancelBtn convertRect:sheet.cancelBtn.bounds toView:content];
    XCTAssertEqualWithAccuracy(CGRectGetWidth(cancelRect), contentWidth, 0.5);
    [sheet hideWithAnimation:NO];
}

- (void)testBlurBackgroundReleasesAfterAnimatedHide {
    UIViewController *host = [[UIViewController alloc] init];
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 400, 1000)];
    host.view = view;

    for (NSNumber *level in @[@100, @50, @1]) {
        @autoreleasepool {
            XYZListSheet *sheet = [[XYZListSheet alloc] init];
            sheet.bgViewBlurStyle = XYZSheetViewBgBlurStyleDark;
            sheet.bgViewBlurLevel = level.intValue;
            sheet.showDuration = 0.05;
            sheet.hideDuration = 0.05;
            [sheet.actions addObject:[XYZListSheetAction actionWithName:@"Action" action:nil]];
            [sheet showToView:view];
            [view layoutIfNeeded];
            [sheet layoutIfNeeded];
            XCTAssertTrue(XYZContainsVisualEffectView(sheet));

            [sheet hideWithAnimation:YES];
            XCTestExpectation *hidden = [self expectationWithDescription:@"hidden"];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                XCTAssertNil(sheet.superview);
                [hidden fulfill];
            });
            [self waitForExpectations:@[hidden] timeout:2];
        }
        // 离开 autoreleasepool 时释放 sheet 与 BlurEffectView, 验证 animator 不会因 paused 状态崩溃
    }
}

@end
