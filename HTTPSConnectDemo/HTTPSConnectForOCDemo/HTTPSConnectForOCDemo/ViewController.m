//
//  ViewController.m
//  HTTPSConnectForOCDemo
//
//  Created by user on 15/10/10.
//  Copyright © 2015年 BG. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()<NSURLSessionDataDelegate>
@property (nonatomic, strong) NSArray *trustedCerArr;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //导入客户端证书
    NSString *cerPath = [[NSBundle mainBundle] pathForResource:@"ca" ofType:@"cer"];
    NSData *data = [NSData dataWithContentsOfFile:cerPath];
    SecCertificateRef certificate = SecCertificateCreateWithData(NULL, (__bridge CFDataRef) data);
    self.trustedCerArr = @[(__bridge_transfer id)certificate];
    
    //发送请求
    NSURL *testURL = [NSURL URLWithString:@"https://casetree.cn/web/test/demo.php"];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:[NSURLRequest requestWithURL:testURL]];
    [task resume];
    // Do any additional setup after loading the view, typically from a nib.
}

#pragma mark - NSURLSessionDelegate
- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * __nullable credential))completionHandler{
    
    OSStatus err;
    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    SecTrustResultType  trustResult = kSecTrustResultInvalid;
    NSURLCredential *credential = nil;
    
    //获取服务器的trust object
    SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;
    
    //将读取的证书设置为serverTrust的根证书
    err = SecTrustSetAnchorCertificates(serverTrust, (__bridge CFArrayRef)self.trustedCerArr);
    
    if(err == noErr){
        //通过本地导入的证书来验证服务器的证书是否可信，如果将SecTrustSetAnchorCertificatesOnly设置为NO，则只要通过本地或者系统证书链任何一方认证就行
        err = SecTrustEvaluate(serverTrust, &trustResult);
    }
    
    if (err == errSecSuccess && (trustResult == kSecTrustResultProceed || trustResult == kSecTrustResultUnspecified)){
        //认证成功，则创建一个凭证返回给服务器
        disposition = NSURLSessionAuthChallengeUseCredential;
        credential = [NSURLCredential credentialForTrust:serverTrust];
    }
    else{
        disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
    }
    
    //回调凭证，传递给服务器
    if(completionHandler){
        completionHandler(disposition, credential);
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data{
    NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    NSLog(@"%@", result);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error{
    if(error){
        NSLog(@"%@", error);
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
