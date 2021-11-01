# XYZSheetView
### 是什么

一个比较简单的CustomSheetView，只需要继承并重写几个方法就能满足一般的业务需要

### 怎么用
代码量其实不多, 简单看看就能明白
- ```XYZBaseSheetView```：不能直接使用，提供了基本定义及代码结构
- ```XYZCommonSheetView```：不能直接使用，继承自```XYZBaseSheetView```，额外提供了底部barView
- ```XYZListSheet```：可以直接使用，较为简单的ListSheetView

##### 已支持：
1. 支持点击空白处隐藏/收键盘(如果第一响应者是自己或自己的子视图)
2. 支持设置最大高度, 当内容高度超过设置的最大高度时, 自动支持滚动
3. 支持TopLeft&TopRight圆角
4. 支持自动躲避键盘(支持修正偏移量)

##### 建议用法：
每个项目中的sheetView风格基本类似，可以继承实现一个```XXXSheetView```，业务中的sheetView在分别基于此实现, 需要重写的方法为：

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

##### 安装：
- 源码安装: 拖拽XYZSheetView/Classes文件夹到项目中即可
- cocoapods: 
```
    source "https://github.com/DFTT/XYZPodspecs.git"
    pod 'XYZSheetView'
``` 
### 后续


