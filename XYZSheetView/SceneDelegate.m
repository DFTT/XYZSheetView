//
//  SceneDelegate.m
//  XYZSheetView
//

#import "SceneDelegate.h"
#import "ViewController.h"

@implementation SceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    if (NO == [scene isKindOfClass:[UIWindowScene class]]) { return; }
    UIWindow *window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[ViewController new]];
    self.window = window;
    [window makeKeyAndVisible];
}

@end
