//
//  XYZListSheet.m
//  TinySweet
//
//  Created by 大大东 on 2020/12/24.
//  Copyright © 2020 xinmeng. All rights reserved.
//

#import "XYZListSheet.h"

@implementation XYZListSheetAction
- (instancetype)init {
    self = [super init];
    if (self) {
        _nameFont = [UIFont systemFontOfSize:16];
        _nameFontColor = [UIColor blackColor];
        
        _descFont = [UIFont systemFontOfSize:13];
        _descFontColor = [UIColor grayColor];
    }
    return self;
}
+ (instancetype)actionWithName:(NSString *)name action:(XYZListSheetActionBlock)action {
    return [self actionWithName:name desc:nil action:action];
}
+ (instancetype)actionWithName:(NSString *)name
                          desc:(NSString * _Nullable)desc
                        action:(XYZListSheetActionBlock _Nullable)action {
    XYZListSheetAction *sheetAction = [XYZListSheetAction new];
    sheetAction.name = name;
    sheetAction.desc = desc;
    sheetAction.action = action;
    return sheetAction;
}
@end



@interface XYZSheetCell : UITableViewCell
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *descLabel;
@property (nonatomic, strong) CALayer *line;
@end
@implementation XYZSheetCell
{
    UIStackView *_stackView;
}
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        
        _descLabel = [[UILabel alloc] init];
        _descLabel.textAlignment = NSTextAlignmentCenter;
        _descLabel.numberOfLines = 3;
        
        _line = [CALayer new];
        _line.backgroundColor = [UIColor lightGrayColor].CGColor;
        
        UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[_titleLabel, _descLabel]];
        stack.axis = UILayoutConstraintAxisVertical;
        stack.spacing = 0;
        stack.distribution = UIStackViewDistributionFillProportionally;
        _stackView = stack;
        [self.contentView addSubview:stack];
        [self.contentView.layer addSublayer:_line];
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat width = self.contentView.bounds.size.width, height = self.contentView.bounds.size.height;
    CGFloat lineHeight = 1.0 / [UIScreen mainScreen].scale;
    _line.frame = CGRectMake(0, height - lineHeight, width, lineHeight);
    CGFloat offset = 15;
    _stackView.frame = CGRectMake(offset, 2, width - offset * 2, height - 4);
}
@end


@interface XYZListSheet()<UITableViewDelegate, UITableViewDataSource>
{
    NSLayoutConstraint *_tableViewHeight;
}
@property (nonatomic, strong) UITableView *tableView;
@end
@implementation XYZListSheet

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _cellHeight = 50;
        _actions    = [NSMutableArray array];
        
        self.allowScrollIfOutMaxHeight = NO;
    }
    return self;
}

#pragma mark - Overdide
- (UIView *)topBarView {
    return nil;
}
- (UIView *)centerContentView {
    UITableView *tableView = [self tableView];
    _tableViewHeight = [tableView.heightAnchor constraintEqualToConstant:self.cellHeight * self.actions.count];
    _tableViewHeight.active = YES;
    return tableView;
}

- (void)showToView:(UIView *)view {
    if (self.actions.count == 0) return;

    [super showToView:view];
}


- (void)refreshOprations {
    if (!self.superview || !self.window) return;
    if (self.actions.count == 0) { [self hideWithAnimation:YES];  return;}
    
    [self.tableView reloadData];
    
    CGFloat newH = self.cellHeight * self.actions.count;
    if (_tableViewHeight.constant != newH) {
        _tableViewHeight.constant = newH;
        [UIView animateWithDuration:0.15 animations:^{
            [self layoutIfNeeded];
        }];
    }
}

#pragma mark - <UITableViewDataSource>

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.actions.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.cellHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    XYZSheetCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(XYZSheetCell.class)];

    XYZListSheetAction *action = self.actions[indexPath.row];
    
    cell.titleLabel.text = action.name;
    cell.titleLabel.font = action.nameFont;
    cell.titleLabel.textColor = action.nameFontColor;
    
    if (action.desc == nil) {
        cell.descLabel.hidden = YES;
    }else {
        cell.descLabel.text = action.desc;
        cell.descLabel.font = action.descFont;
        cell.descLabel.textColor = action.descFontColor;
        cell.descLabel.hidden = NO;
    }

    cell.line.hidden = indexPath.row == self.actions.count - 1;
    return cell;
}

#pragma mark - <UITableViewDelegate>

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    XYZListSheetAction *action = self.actions[indexPath.row];
    if (action.action) action.action();
    
    [self hideWithAnimation:YES];
}

#pragma mark - getters

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.estimatedRowHeight = 0;
        _tableView.estimatedSectionFooterHeight = 0;
        _tableView.estimatedSectionHeaderHeight = 0;
        _tableView.backgroundColor = [UIColor whiteColor];
        _tableView.alwaysBounceVertical = NO;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.sectionFooterHeight = _tableView.sectionHeaderHeight = 0;
        
        if (@available(iOS 11.0, *)) {
            _tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        if (@available(iOS 15.0, *)) {
            _tableView.sectionHeaderTopPadding = 0;
        }
        
        _tableView.tableFooterView = [[UIView alloc] init];
        [_tableView registerClass:XYZSheetCell.class forCellReuseIdentifier:NSStringFromClass(XYZSheetCell.class)];
    }
    return _tableView;
}

@end
