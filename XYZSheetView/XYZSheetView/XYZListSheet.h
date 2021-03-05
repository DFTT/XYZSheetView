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

/// 显示的名字
@property (nonatomic, copy) NSString *name;

/// 点击回调闭包
@property (nonatomic, copy, nullable) XYZListSheetActionBlock action;

+ (instancetype)actionWithName:(NSString *)name action:(_Nullable XYZListSheetActionBlock)action;

@end



@interface XYZListSheet : XYZCommonSheetView

/// 数据源 (可自定义添加)
@property (nonatomic, strong) NSMutableArray<XYZListSheetAction *> *actions;

/// 列表 Cell 的高度 (defult 50)
@property (nonatomic, assign) CGFloat cellHeight;

/// 更新sheetView, 数据源变化时使用 (if not showing, nothing todo)
- (void)refreshOprations;

@end

NS_ASSUME_NONNULL_END
