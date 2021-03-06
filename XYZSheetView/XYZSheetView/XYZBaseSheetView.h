//
//  XYZBaseSheetView.h
//  XYZSheetView
//
//  Created by 大大东 on 2021/2/23.
//

#import <UIKit/UIKit.h>

FOUNDATION_EXTERN CGFloat XYZSafeAreaBottomHeight(void);

NS_ASSUME_NONNULL_BEGIN

@interface XYZBaseSheetView : UIView

/// 点击空白区域时自动隐藏
/// defult YES
@property (nonatomic, assign) BOOL hideOnTouchOutside;

/// 背景透明度
/// defult 0.3
@property (nonatomic, assign) CGFloat backAlpha;

/// 展示最大高度与容器高度的比例
/// defult 0.7
@property (nonatomic, assign) CGFloat maxHeightScale;

/// 当内容高度超出maxHeightScale标记的高度时, 是否允许sheetView滚动
/// defult YES
@property (nonatomic, assign) BOOL allowScrollIfOutMaxHeight;

/// 切圆角的半径(TopLeft & TopRight) >0才显示
/// defult 0
@property (nonatomic, assign) CGFloat topCornerRadius;

/// 显示动画持续时间
/// defult 0.2
@property (nonatomic, assign) NSTimeInterval showDuration;

/// 隐藏动画持续时间
/// defult 0.2
@property (nonatomic, assign) NSTimeInterval hideDuration;


/**
 展示 (if showing, nothing todo)
 @param view 只能是UIViewController.view 或 UIWindow
 */
- (void)showToView:(UIView *)view;

/**
 刷新sheet (if not showing, nothing todo)
 如果展示后, 由于接口返回或用户操作导致数据发生改变, 可用此方法刷新sheet高度
 */
//- (void)refreshSheetHegit;

/**
 隐藏
 @param animation 是否带动画
 */
- (void)hideWithAnimation:(BOOL)animation;




//*****************************   subclass need overdide  ****************************/


/// 可选实现(要求: 竖直方向上约束完备<自撑大 或 有高度约束>)
- (nullable UIView *)topBarView;

/// 可选实现(要求: 竖直方向上约束完备<自撑大 或 有高度约束>
///              请处理底部 safeAreaHeight)
- (nullable UIView *)bottomBarView;

/// 必须实现(要求: 竖直方向上约束完备<自撑大 或 有高度约束>
///              如果是滚动视图 请注意滚动冲突 可以设置 allowScrollIfOutMaxHeight = NO)
- (nonnull  UIView *)centerContentView;
@end





@interface XYZCommonSheetView : XYZBaseSheetView

/// 底部按钮
@property (nonatomic, strong, readonly) UIButton *cancelBtn;

/// 底部分隔条
@property (nonatomic, assign) BOOL hideSeparatLine;

/// 底部按钮点击回调
@property (nonatomic, copy  ) void(^cancelBtnClick)(void);

@end
NS_ASSUME_NONNULL_END
