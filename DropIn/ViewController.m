//
//  ViewController.m
//  DropIn
//
//  Created by MTS Dublin on 21/12/2016.
//  Copyright © 2016 BraintreeEMEA. All rights reserved.
//

#import "ViewController.h"
#import "BraintreeCore.h"
#import "BraintreeDropIn.h"
#import "Braintree3DSecure.h"


@interface ViewController () <BTCardFormViewControllerDelegate, BTViewControllerPresentingDelegate>

@property (nonatomic, strong) BTThreeDSecureDriver *threeDriver;
@property (nonatomic, strong) BTAPIClient *braintreeClient;

@end

@implementation ViewController

NSString *resultCheck;
NSString *clientToken;


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    // TODO: Switch this URL to your own authenticated API
    NSURL *clientTokenURL = [NSURL URLWithString:@"http://orcodevbox.co.uk/BTOrcun/tokenGen.php"];
    NSMutableURLRequest *clientTokenRequest = [NSMutableURLRequest requestWithURL:clientTokenURL];
    [clientTokenRequest setValue:@"text/plain" forHTTPHeaderField:@"Accept"];
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:clientTokenRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        // TODO: Handle errors
        clientToken = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        // Log the client token to confirm that it is returned from the server
        NSLog(@"%@",clientToken);
        
        self.braintreeClient = [[BTAPIClient alloc] initWithAuthorization:clientToken];
        
        
        // As an example, you may wish to present our Drop-in UI at this point.
        // Continue to the next section to learn more...
    }] resume];
    
    
}



- (IBAction)launchDropInUI:(id)sender {
    

    BTDropInRequest *request = [[BTDropInRequest alloc] init];
    
    // If I enable these lines, Add Card button does nothing... Reported to dev team
    //request.threeDSecureVerification = true;
    //request.amount = @"12.99";
    BTDropInController *dropIn = [[BTDropInController alloc] initWithAuthorization:clientToken request:request handler:^(BTDropInController * _Nonnull controller, BTDropInResult * _Nullable result, NSError * _Nullable error) {
        
        if (error != nil) {
            NSLog(@"ERROR");
        } else if (result.cancelled) {
            NSLog(@"CANCELLED");
         [self dismissViewControllerAnimated:YES completion:nil];
        } else {
            
            
            // Use the BTDropInResult properties to update your UI
            // result.paymentOptionType
            // result.paymentMethod
            // result.paymentIcon
            // result.paymentDescription
            
            
            
            // Create 3D Secure driver as mentioned in our 3D Secure guide.
            BTThreeDSecureDriver *threeDSecure = [[BTThreeDSecureDriver alloc] initWithAPIClient:self.braintreeClient delegate:self];
            
            // Dismiss drop-in ui
            [self dismissViewControllerAnimated:YES completion:nil];
            
            if (![result.paymentMethod.type  isEqual: @"PayPal"]) {
                // Kick off 3D Secure flow. This example uses a value of $12.99
                [threeDSecure verifyCardWithNonce:result.paymentMethod.nonce
                                           amount:[NSDecimalNumber decimalNumberWithString:@"12.99"]
                                       completion:^(BTThreeDSecureCardNonce *card, NSError *error) {
                                           if (error) {
                                               // Handle errors
                                               NSLog(@"error: %@",error);
                                               return;
                                               
                                           }
                                           
                                           // Use resulting `card`...
                                           NSLog(@"3D Secure Card nonce: %@",card.nonce);
                                           
                                           // Is liability shifted?
                                           NSLog(@"Is liability shifted? %d", card.liabilityShifted);
                                           
                                           // Is liability shift possible?
                                           NSLog(@"Is liability shift possible? %d", card.liabilityShiftPossible);
                                           
                                           
                                           
                                           
                                           // Send 3D Secure nonce to server
                                           [self postNonceToServer:card.nonce];
                                       }];
                
            } else {
                
                // If the payment method is not a card (e.g. PayPal), don't run it through 3d Secure and send it as it is
                [self postNonceToServer:result.paymentMethod.nonce];
                
            }
            
        }
    }];
    [self presentViewController:dropIn animated:YES completion:nil];

    
}

- (void)paymentDriver:(id)driver requestsPresentationOfViewController:(UIViewController *)viewController {
    [self presentViewController:viewController animated:YES completion:nil];
}

- (void)cardTokenizationCompleted:(BTPaymentMethodNonce *)tokenizedCard error:(NSError *)error sender:(BTCardFormViewController *)sender {
    
    NSLog(@"%@",error);

}

- (void)paymentDriver:(id)driver requestsDismissalOfViewController:(UIViewController *)viewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)postNonceToServer:(NSString *)paymentMethodNonce {
    
    double price = 12.99;
    
    
    NSLog(@"%@",paymentMethodNonce);
    NSURL *paymentURL = [NSURL URLWithString:@"http://orcodevbox.co.uk/BTOrcun/iosPayment.php"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:paymentURL];
    
    request.HTTPBody = [[NSString stringWithFormat:@"amount=%ld&payment_method_nonce=%@", (long)price,paymentMethodNonce] dataUsingEncoding:NSUTF8StringEncoding];
    request.HTTPMethod = @"POST";
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        NSString *paymentResult = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        // TODO: Handle success and failure
        
        // Logging the HTTP request so we can see what is being sent to the server side
        NSLog(@"Request body %@", [[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding]);
        
        
        // Log the transaction result
        NSLog(@"%@",paymentResult);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            // Checking the result for the string "Successful" and updating GUI elements
            if ([paymentResult containsString:@"Successful"]) {
                NSLog(@"Transaction is successful!");
                resultCheck = @"Transaction successful";
                
                
            } else {
                NSLog(@"Transaction failed! Contact Mat!");
                resultCheck = @"Transaction failed!Contact Mat!";
                
            }
            
            // Create an alert controller to display the transaction result
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:resultCheck
                                                                           message:paymentResult
                                                                    preferredStyle:UIAlertControllerStyleActionSheet];
            
            
            UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK" style:
                                            UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                                                
                                                NSLog(@"You pressed button OK");
                                            }];
            
            [alert addAction:defaultAction];
            
            [self presentViewController:alert animated:YES completion:nil];
        });
    }] resume];
    
    
}




- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
