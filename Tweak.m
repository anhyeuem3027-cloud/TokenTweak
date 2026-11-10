
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <stdlib.h>

static NSString * const kSavedLicenseKey = @"SavedLicenseKey";
static NSString * const kAPIEndpoint =
    @"https://ioscrack.pro/licence/api/check_key.php";

static NSString * const kBundleIdentifier = @"fc.vn1";

static BOOL gIsCheckingLicense = NO;
static BOOL gLicenseValidated = NO;
static BOOL gAlertVisible = NO;

#pragma mark - Window

static UIWindow *GetActiveKeyWindow(void) {

    if (@available(iOS 13.0, *)) {

        for (UIScene *scene in
             UIApplication.sharedApplication.connectedScenes) {

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

    return UIApplication.sharedApplication.keyWindow;

#pragma clang diagnostic pop
}

static UIViewController *GetTopViewController(void) {

    UIWindow *window = GetActiveKeyWindow();

    if (!window) return nil;

    UIViewController *controller = window.rootViewController;

    while (controller.presentedViewController) {
        controller = controller.presentedViewController;
    }

    return controller;
}

#pragma mark - Alerts

static void ShowErrorAlert(NSString *message) {

    dispatch_async(dispatch_get_main_queue(), ^{

        UIViewController *controller = GetTopViewController();

        if (!controller) {
            exit(0);
        }

        UIAlertController *alert =
        [UIAlertController
         alertControllerWithTitle:@"XÁC THỰC LICENSE"
         message:message
         preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction *exitAction =
        [UIAlertAction
         actionWithTitle:@"Thoát ứng dụng"
         style:UIAlertActionStyleDestructive
         handler:^(UIAlertAction *action) {
            exit(0);
        }];

        [alert addAction:exitAction];

        [controller presentViewController:alert
                                 animated:YES
                               completion:nil];
    });
}

#pragma mark - License Validation

static void ValidateLicense(NSString *licenseKey) {

    if (gIsCheckingLicense || gLicenseValidated) {
        return;
    }

    if (licenseKey.length == 0) {
        ShowErrorAlert(@"License Key không được để trống.");
        return;
    }

    gIsCheckingLicense = YES;

    NSURLComponents *components =
        [NSURLComponents componentsWithString:kAPIEndpoint];

    components.queryItems = @[
        [NSURLQueryItem queryItemWithName:@"key"
                                   value:licenseKey],
        [NSURLQueryItem queryItemWithName:@"bundle"
                                   value:kBundleIdentifier]
    ];

    NSURL *url = components.URL;

    if (!url) {
        gIsCheckingLicense = NO;
        ShowErrorAlert(@"Không thể tạo địa chỉ xác thực.");
        return;
    }

    NSMutableURLRequest *request =
        [NSMutableURLRequest requestWithURL:url];

    request.HTTPMethod = @"GET";
    request.timeoutInterval = 15.0;

    [request setValue:@"application/json"
   forHTTPHeaderField:@"Accept"];

    NSURLSessionDataTask *task =
    [[NSURLSession sharedSession]
     dataTaskWithRequest:request
     completionHandler:^(NSData *data,
                         NSURLResponse *response,
                         NSError *error) {

        dispatch_async(dispatch_get_main_queue(), ^{

            gIsCheckingLicense = NO;

            if (error || !data) {
                ShowErrorAlert(
                    @"Không thể kết nối máy chủ xác thực. Vui lòng thử lại sau."
                );
                return;
            }

            NSHTTPURLResponse *httpResponse =
                (NSHTTPURLResponse *)response;

            if (httpResponse.statusCode != 200) {
                ShowErrorAlert(
                    @"Máy chủ xác thực đang gặp sự cố."
                );
                return;
            }

            NSError *jsonError = nil;

            id json =
                [NSJSONSerialization
                 JSONObjectWithData:data
                 options:0
                 error:&jsonError];

            if (jsonError ||
                ![json isKindOfClass:[NSDictionary class]]) {

                ShowErrorAlert(
                    @"Phản hồi xác thực không hợp lệ."
                );
                return;
            }

            NSDictionary *result = (NSDictionary *)json;

            id status = result[@"status"];
            id success = result[@"success"];

            BOOL isValid = NO;

            if ([status isKindOfClass:[NSString class]]) {
                isValid =
                    [(NSString *)status
                     caseInsensitiveCompare:@"success"] ==
                    NSOrderedSame;
            }

            if ([success respondsToSelector:@selector(boolValue)] &&
                [success boolValue]) {
                isValid = YES;
            }

            if (!isValid) {

                NSString *serverMessage = result[@"message"];

                if (![serverMessage isKindOfClass:[NSString class]] ||
                    serverMessage.length == 0) {
                    serverMessage =
                        @"License Key không hợp lệ hoặc đã hết hạn.";
                }

                ShowErrorAlert(serverMessage);
                return;
            }

            gLicenseValidated = YES;

            [[NSUserDefaults standardUserDefaults]
             setObject:licenseKey
             forKey:kSavedLicenseKey];

            [[NSUserDefaults standardUserDefaults] synchronize];

            NSLog(@"[License] Validation successful.");
        });
    }];

    [task resume];
}

#pragma mark - License Input

static void ShowLicensePrompt(void) {

    dispatch_async(dispatch_get_main_queue(), ^{

        if (gAlertVisible || gLicenseValidated) {
            return;
        }

        UIViewController *controller = GetTopViewController();

        if (!controller) {
            dispatch_after(
                dispatch_time(DISPATCH_TIME_NOW,
                              1 * NSEC_PER_SEC),
                dispatch_get_main_queue(),
                ^{
                    ShowLicensePrompt();
                }
            );
            return;
        }

        gAlertVisible = YES;

        UIAlertController *alert =
        [UIAlertController
         alertControllerWithTitle:@"THÔNG BÁO HỆ THỐNG"
         message:@"Vui lòng nhập License Key để xác thực bản quyền."
         preferredStyle:UIAlertControllerStyleAlert];

        [alert addTextFieldWithConfigurationHandler:
         ^(UITextField *textField) {

            textField.placeholder = @"Nhập License Key...";
            textField.secureTextEntry = YES;
            textField.autocorrectionType =
                UITextAutocorrectionTypeNo;
            textField.autocapitalizationType =
                UITextAutocapitalizationTypeNone;
            textField.clearButtonMode =
                UITextFieldViewModeWhileEditing;
        }];

        UIAlertAction *confirm =
        [UIAlertAction
         actionWithTitle:@"Xác nhận"
         style:UIAlertActionStyleDefault
         handler:^(UIAlertAction *action) {

            NSString *key =
                [alert.textFields.firstObject.text
                 stringByTrimmingCharactersInSet:
                 NSCharacterSet.whitespaceAndNewlineCharacterSet];

            gAlertVisible = NO;

            if (key.length == 0) {
                ShowErrorAlert(@"Vui lòng nhập License Key.");
                return;
            }

            ValidateLicense(key);
        }];

        [alert addAction:confirm];

        [controller presentViewController:alert
                                 animated:YES
                               completion:nil];
    });
}

#pragma mark - Startup

static void StartLicenseSystem(void) {

    dispatch_async(dispatch_get_main_queue(), ^{

        NSString *savedKey =
            [[NSUserDefaults standardUserDefaults]
             stringForKey:kSavedLicenseKey];

        if (savedKey.length > 0) {

            ValidateLicense(savedKey);

        } else {

            ShowLicensePrompt();
        }
    });
}

__attribute__((constructor))
static void LicenseTweakInit(void) {

    NSLog(@"[License] System initialized.");

    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW,
                      (int64_t)(3 * NSEC_PER_SEC)),
        dispatch_get_main_queue(),
        ^{
            StartLicenseSystem();
        }
    );
}
