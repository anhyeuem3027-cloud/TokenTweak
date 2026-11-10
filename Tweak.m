
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

static NSString *savedToken = nil;

static UIWindow *GetCurrentKeyWindow(void) {

    if (@available(iOS 13.0, *)) {

        NSSet<UIScene *> *scenes =
            [UIApplication sharedApplication].connectedScenes;

        for (UIScene *scene in scenes) {

            if (scene.activationState !=
                UISceneActivationStateForegroundActive) {
                continue;
            }

            if (![scene isKindOfClass:[UIWindowScene class]]) {
                continue;
            }

            UIWindowScene *windowScene = (UIWindowScene *)scene;

            for (UIWindow *window in windowScene.windows) {
                if (window.isKeyWindow) {
                    return window;
                }
            }
        }

        return nil;
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

    UIWindow *window =
        [UIApplication sharedApplication].keyWindow;

#pragma clang diagnostic pop

    return window;
}

static void ShowTokenAlert(void) {

    dispatch_async(dispatch_get_main_queue(), ^{

        UIWindow *keyWindow = GetCurrentKeyWindow();

        if (!keyWindow) return;

        UIViewController *rootVC = keyWindow.rootViewController;

        if (!rootVC) return;

        while (rootVC.presentedViewController) {
            rootVC = rootVC.presentedViewController;
        }

        UIAlertController *alert =
        [UIAlertController
         alertControllerWithTitle:@"THÔNG BÁO HỆ THỐNG"
         message:@"Vui lòng nhập token để tiếp tục."
         preferredStyle:UIAlertControllerStyleAlert];

        [alert addTextFieldWithConfigurationHandler:
         ^(UITextField *textField) {

            textField.placeholder = @"Nhập token...";
            textField.secureTextEntry = YES;
            textField.autocorrectionType =
                UITextAutocorrectionTypeNo;
            textField.autocapitalizationType =
                UITextAutocapitalizationTypeNone;
            textField.clearButtonMode =
                UITextFieldViewModeWhileEditing;
        }];

        UIAlertAction *confirmAction =
        [UIAlertAction
         actionWithTitle:@"Xác nhận"
         style:UIAlertActionStyleDefault
         handler:^(UIAlertAction *action) {

            UITextField *textField =
                alert.textFields.firstObject;

            savedToken = [textField.text copy];

            NSLog(@"[TokenTweak] Token entered.");
        }];

        [alert addAction:confirmAction];

        [rootVC presentViewController:alert
                             animated:YES
                           completion:nil];
    });
}

__attribute__((constructor))
static void TweakInit(void) {

    NSLog(@"[TokenTweak] Initialized.");

    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW,
                      (int64_t)(3 * NSEC_PER_SEC)),
        dispatch_get_main_queue(),
        ^{
            ShowTokenAlert();
        }
    );
}
