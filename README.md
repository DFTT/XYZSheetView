# XYZSheetView
#### 是什么

一个比较简单的CustomSheetView，和系统提供的风格不同，

只需要继承并重写几个方法就能满足一般的业务需要

#### 怎么用

代码量其实不多，简单看看就能明白

- ```XYZBaseSheetView```：不能直接使用，提供了基本定义及代码结构
- ```XYZCommonSheetView```：不能直接使用，继承自```XYZBaseSheetView```，额外提供了底部barView
- ```XYZListSheet```：可以直接使用，较为简单的ListSheetView

###### 建议用法：

每个项目中的sheetView风格基本类似，可以继承实现一个```XXXSheetView```，业务中的sheetView在分别基于此实现

重点需要重写的方法为：

```objective-c
//*****************************   subclass need overdide  ****************************/


/// 可选实现(要求: 竖直方向上约束完备<自撑大 或 有高度约束>)
- (nullable UIView *)topBarView;

/// 可选实现(要求: 竖直方向上约束完备<自撑大 或 有高度约束>
///              请处理底部 safeAreaHeight)
- (nullable UIView *)bottomBarView;

/// 必须实现(要求: 竖直方向上约束完备<自撑大 或 有高度约束>
///              如果是滚动视图 请注意滚动冲突 可以设置 allowScrollIfOutMaxHeight = NO)
- (nonnull  UIView *)centerContentView;

```

#### 后续

长期更新维护，请提需求
