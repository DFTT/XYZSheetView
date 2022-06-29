//
//  ViewController.m
//  XYZSheetView
//
//  Created by 大大东 on 2021/2/23.
//

#import "ViewController.h"
#import "XYZListSheet.h"
#import "SimpleSheet.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    [btn setTitle:@"list Sheet 2s后刷新高度" forState:UIControlStateNormal];
    [self.view  addSubview:btn];
    [btn addTarget:self action:@selector(btnAction) forControlEvents:UIControlEventTouchUpInside];
    btn.frame = CGRectMake(0, 200, self.view.bounds.size.width, 30);
    
    UIButton *btn2 = [UIButton buttonWithType:UIButtonTypeSystem];
    [btn2 setTitle:@"custom Sheet" forState:UIControlStateNormal];
    [self.view  addSubview:btn2];
    [btn2 addTarget:self action:@selector(btn2Action) forControlEvents:UIControlEventTouchUpInside];
    btn2.frame = CGRectMake(0, 200 + 40, self.view.bounds.size.width, 30);
    
    UIButton *btn3 = [UIButton buttonWithType:UIButtonTypeSystem];
    [btn3 setTitle:@"custom Sheet 高度超出可滚动" forState:UIControlStateNormal];
    [self.view  addSubview:btn3];
    [btn3 addTarget:self action:@selector(btn3Action) forControlEvents:UIControlEventTouchUpInside];
    btn3.frame = CGRectMake(0, 200 + 40 * 2, self.view.bounds.size.width, 30);
    
    
    UIView *blueView = [[UIView alloc] initWithFrame:CGRectMake(0, 50, 200, 20)];
    blueView.backgroundColor = UIColor.systemBlueColor;
    [self.view addSubview:blueView];
}

- (void)btnAction {
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:10];
    for (int i = 0; i < 3; i++) {
        XYZListSheetAction *action = [XYZListSheetAction actionWithName:@"哈哈哈哈" action:nil];
        [arr addObject:action];
    }

    XYZListSheet *s = [[XYZListSheet alloc] init];
    s.actions = arr;
    s.topCornerRadius = 16;
    s.bgViewBlurStyle = XYZSheetViewBgBlurStyleLight;
    s.bgViewBlurLevel = 1;
    
    [s showToView:self.view];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        for (int i = 0; i < 30; i++) {
            XYZListSheetAction *action = [XYZListSheetAction actionWithName:@"哈哈哈哈" action:nil];
            [arr addObject:action];
        }
        s.actions = arr;
        [s refreshOprations];
    });
    
}

- (void)btn2Action {
    SimpleSheet *sheet = [[SimpleSheet alloc] init];
    sheet.tHeight = 200;
    sheet.bgViewBlurStyle = XYZSheetViewBgBlurStyleLight;
    [sheet showToView:self.view];
}

- (void)btn3Action {
    SimpleSheet *sheet = [[SimpleSheet alloc] init];
    sheet.tHeight = 2000;
    sheet.topCornerRadius = 16;
    sheet.avoidKeyboardOffsetY = 200;
    [sheet showToView:self.view];
}


@end
