//
//  LoginViewController.m
//  Logave
//
//  Created by Александр on 01.04.15.
//  Copyright (c) 2015 BSUIR. All rights reserved.
//

#import "LoginViewController.h"

#import "SWRevealViewController.h"
#import "FrontViewController.h"
#import "RearViewController.h"

@interface LoginViewController ()<SWRevealViewControllerDelegate>

@end

@implementation LoginViewController

@synthesize window = _window;
@synthesize viewController = _viewController;

- (void)viewDidLoad {
    [super viewDidLoad];
    [_loginField setBackgroundColor:[UIColor colorWithRed:216.0f/255.0f green:216.0f/255.0f blue:216.0f/255.0f alpha:1]];
    [_passField setBackgroundColor:[UIColor colorWithRed:216.0f/255.0f green:216.0f/255.0f blue:216.0f/255.0f alpha:1]];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)loginKeyboardHiding:(UITextField *)sender {
    [sender resignFirstResponder];
}

- (IBAction)passwordKeyboardHiding:(UITextField *)sender {
    [sender resignFirstResponder];
}

-(IBAction)touchToHideKeyboard:(id)sender{
    [self.loginField resignFirstResponder];
    [self.passField resignFirstResponder];
}

- (IBAction)loginTouchedUp:(UIButton *)sender {
    
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL
                                                                        URLWithString:@"http://api.logave.com/user/login?"]
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:15.0];
    request.HTTPMethod = @"POST";
    
    //NSString * myName = _loginField.text;
    //NSString * myPassword= [self getMd5For:_passField.text];
    
    NSString * param = [NSString stringWithFormat:@"device=c21592b180d10e601f2080111fc657de&email=%@&password=%@", _loginField.text, [self getMd5For:_passField.text]];
    request.HTTPBody = [param dataUsingEncoding:NSUTF8StringEncoding];
    
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
    
    if (connection) {
        _receivedData = [[NSMutableData data] init];
    }
    [self.loginField setHidden:YES];
    [self.passField setHidden:YES];
    [self.loginPressed setHidden:YES];
}


-(NSString*)getMd5For:(NSString*)inputString{
    const char *cStr = [inputString UTF8String];
    unsigned char digest[16];
    CC_MD5(cStr,(int)strlen(cStr),digest);
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH*2];
    for(int i = 0;i<CC_MD2_DIGEST_LENGTH;i++)
        [output appendFormat:@"%02x",digest[i]];
    return output;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [_receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    
    [_receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    UIAlertView *errorAlert = [[UIAlertView alloc]
                               initWithTitle:@"Error" message:@"Please, check your Internet Connection." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [errorAlert show];
    [self.loginField setHidden:NO];
    [self.passField setHidden:NO];
    [self.loginPressed setHidden:NO];
}



-(NSString*)fixUnicode:(NSString*)input{
    NSString *convertedString = [input mutableCopy];
    CFStringRef transform = CFSTR("Any-Hex/Java");
    CFStringTransform((__bridge CFMutableStringRef)convertedString, NULL, transform, YES);
    return convertedString;
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self.loginField resignFirstResponder];
    [self.passField resignFirstResponder];
    NSString* data = [self fixUnicode:[[NSString alloc] initWithData:_receivedData encoding:NSUTF8StringEncoding]];
    NSError *e = nil;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:_receivedData options:NSJSONReadingMutableContainers error:&e];
    NSLog(@"%@\n",data);
    NSString *userInformation = json[@"data"][@"data"];
    if([userInformation isEqual:@"User is not courier"]){
        UIAlertView *errorAlert = [[UIAlertView alloc]
                                   initWithTitle:@"Authorization Error" message:@"Please, check your login and password." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [errorAlert show];
        [self.loginField setHidden:NO];
        [self.passField setHidden:NO];
        [self.loginPressed setHidden:NO];
    } else {
        NSLog(@"%@",json);

        NSString *key = json[@"data"][@"data"][@"user"][@"key"];
        //NSString *expDate= json[@"data"][@"data"][@"user"][@"expdate"];
        
        UIWindow *window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        self.window = window;
        
        FrontViewController *frontViewController = [[FrontViewController alloc] init];
        [frontViewController setUserKey:key];
        RearViewController *rearViewController = [[RearViewController alloc] init];
        [rearViewController setUserKey:key];
        rearViewController.frontViewController = frontViewController;
        UINavigationController *frontNavigationController = [[UINavigationController alloc] initWithRootViewController: frontViewController];
        UINavigationController *rearNavigationController = [[UINavigationController alloc] initWithRootViewController:rearViewController];
        
        SWRevealViewController *mainRevealController = [[SWRevealViewController alloc]
                                                        initWithRearViewController:rearNavigationController frontViewController:frontNavigationController];
        
        mainRevealController.delegate = self;
        
        self.viewController = mainRevealController;
        
        self.window.rootViewController = self.viewController;
        [self.window makeKeyAndVisible];
    }
    
    //NSString *
    //int a = [status intValue];
    //NSLog(@"\nValue is:%d!",a);
}

@end
