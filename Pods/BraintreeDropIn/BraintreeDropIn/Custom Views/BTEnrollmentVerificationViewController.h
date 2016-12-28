#import <UIKit/UIKit.h>
#if __has_include("BraintreeUIKit.h")
#import "BraintreeUIKit.h"
#else
#import <BraintreeUIKit/BraintreeUIKit.h>
#endif

@interface BTEnrollmentVerificationViewController : UIViewController <UITextFieldDelegate, BTUIKFormFieldDelegate>
typedef void (^BTEnrollmentHandler)(NSString* authCode, BOOL resendSms);

- (instancetype)initWithPhone:(NSString *)mobilePhoneNumber
            mobileCountryCode:(NSString *)mobileCountryCode
                      handler:(BTEnrollmentHandler)handler;

- (void)smsErrorHidden:(BOOL)hidden;
- (void)confirm;

@end
