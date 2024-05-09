//
//  XYZListSheet.h
//  TinySweet
//
//  Created by 大大东 on 2020/12/24.
//  Copyright © 2020 xinmeng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XYZBaseSheetView.h"


NS_ASSUME_NONNULL_BEGIN

typedef void(^XYZListSheetActionBlock)(void);

@interface XYZListSheetAction : NSObject

/// 标题
@property (nonatomic, copy) NSString *name;

/// 标题字体
/// default: Regular 16
@property (nonatomic, strong) UIFont *nameFont UI_APPEARANCE_SELECTOR;

/// 标题字体颜色
/// default: black
@property (nonatomic, strong) UIColor *nameFontColor UI_APPEARANCE_SELECTOR;

/// 描述
@property (nonatomic, copy, nullable) NSString *desc;

/// 描述字体
/// default: Regular 13
@property (nonatomic, strong) UIFont *descFont UI_APPEARANCE_SELECTOR;

/// 描述字体颜色
/// default: grayColor
@property (nonatomic, strong) UIColor *descFontColor UI_APPEARANCE_SELECTOR;

/// 点击回调闭包
@property (nonatomic, copy, nullable) XYZListSheetActionBlock action;

+ (instancetype)actionWithName:(NSString *)name
                        action:(_Nullable XYZListSheetActionBlock)action;

+ (instancetype)actionWithName:(NSString *)name
                          desc:(NSString *_Nullable)desc
                        action:(_Nullable XYZListSheetActionBlock)action;

@end



@interface XYZListSheet : XYZCommonSheetView

/// 数据源 (可自定义添加)
@property (nonatomic, strong) NSMutableArray<XYZListSheetAction *> *actions;

/// 列表 Cell 的高度 (defult 50)
@property (nonatomic, assign) CGFloat cellHeight;

/// 更新sheetView, 数据源变化时使用 (if not showing, nothing to do)
- (void)refreshOprations;

@end

NS_ASSUME_NONNULL_END
