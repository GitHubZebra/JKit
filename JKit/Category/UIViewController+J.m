//
//  UIViewController+J.m
//  JKitDemo
//
//  Created by elongtian on 16/1/6.
//  Copyright © 2016年 陈杰. All rights reserved.
//

#import "UIViewController+J.h"
#import <objc/runtime.h>

@interface UIViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (copy, nonatomic) JFinishPickingMedia finishPickingMedia;

@property (copy, nonatomic) JCancelPickingMedia cancelPickingMedia;


@end
static char finishPickingMediaKey, cancelPickingMediaKey;

@implementation UIViewController (J)

#pragma mark 触摸自动隐藏键盘

- (void)j_tapDismissKeyboard
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    UITapGestureRecognizer *singleTapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(j_tapAnywhereToDismissKeyboard:)];
    
    __weak UIViewController *weakSelf = self;
    
    NSOperationQueue *mainQuene =[NSOperationQueue mainQueue];
    
    [nc addObserverForName:UIKeyboardWillShowNotification object:nil queue:mainQuene usingBlock:^(NSNotification *note) {
        
        [weakSelf.view addGestureRecognizer:singleTapGR];
    }];
    
    [nc addObserverForName:UIKeyboardWillHideNotification object:nil queue:mainQuene usingBlock:^(NSNotification *note) {
        
        [weakSelf.view removeGestureRecognizer:singleTapGR];
    }];
}

- (void)j_tapAnywhereToDismissKeyboard:(UIGestureRecognizer *)gestureRecognizer
{
    [self.view endEditing:YES];
}
@end



@implementation UINavigationController (ShouldPopOnBackButton)

/**
 *  感谢https://github.com/onegray/UIViewController-BackButtonHandler
 */
- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item
{
    if (self.viewControllers.count < navigationBar.items.count) {
        
        return YES;
    }
    
    BOOL shouldPop = YES;
    
    UIViewController *viewController = self.topViewController;
    
    if ([viewController respondsToSelector:@selector(j_navigationShouldPopOnBackButton)]) {
        
        shouldPop = [viewController j_navigationShouldPopOnBackButton];
    }
    
    if (shouldPop) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self popViewControllerAnimated:YES];
        });
        
    } else {
        
        for (UIView *subView in [navigationBar subviews]) {
            
            if (subView.alpha < 1.0) {
                
                [UIView animateWithDuration:0.25 animations:^{
                    subView.alpha = 1.0;
                }];
            }
        }
    }
    
    return NO;
}
- (UIImagePickerController *)j_presentImagePickerControllerWithSourceType:(UIImagePickerControllerSourceType)sourceType allowsEditing:(BOOL)allowsEditing completion:(void (^)(void))completion didFinishPickingMedia:(JFinishPickingMedia)finish didCancelPickingMediaWithInfo:(JCancelPickingMedia)cancel
{
    if (sourceType == UIImagePickerControllerSourceTypeCamera) {
        
        if (![UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera]) {
#ifdef DEBUG
            NSLog(@"没有检测到摄像头");
#endif
            return nil;
        }
    }
    
    UIImagePickerController *pickController = [[UIImagePickerController alloc] init];
    [pickController setSourceType:sourceType];
    [pickController setDelegate:self];
    [pickController setAllowsEditing:allowsEditing];
    
    [self presentViewController:pickController animated:YES completion:completion];
    
    self.finishPickingMedia = finish;
    self.cancelPickingMedia = cancel;
    
    return pickController;
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    [picker dismissViewControllerAnimated:YES completion:^{
        
        if (self.finishPickingMedia) {
            self.finishPickingMedia(info);
        }
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    [picker dismissViewControllerAnimated:YES completion:^{
        
        if (self.cancelPickingMedia) {
            self.cancelPickingMedia();
        }
    }];
}

@end