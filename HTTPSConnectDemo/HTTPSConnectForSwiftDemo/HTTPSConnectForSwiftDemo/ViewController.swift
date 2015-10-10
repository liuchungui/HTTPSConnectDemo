//
//  ViewController.swift
//  HTTPSConnectForSwiftDemo
//
//  Created by user on 15/10/10.
//  Copyright © 2015年 BG. All rights reserved.
//

import UIKit

class ViewController: UIViewController, NSURLSessionDataDelegate {
    var trustedCertArr: NSArray?
    override func viewDidLoad() {
        super.viewDidLoad()
        //导入客户端证书
        let cerPath = NSBundle.mainBundle().pathForResource("ca", ofType: "cer")
        if let filePath = cerPath {
            let data = NSData(contentsOfFile: filePath)
            let certificate = SecCertificateCreateWithData(nil, data!)
            trustedCertArr = [certificate!]
            
            //发送请求
            let testUrl = NSURL(string: "https://casetree.cn/web/test/demo.php")
            let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: self, delegateQueue: NSOperationQueue.mainQueue())
            let task = session.dataTaskWithRequest(NSURLRequest(URL: testUrl!))
            task.resume()
        }
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    //MARK: - NSURLSessionDelegate
    func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        var err: OSStatus
        var disposition : NSURLSessionAuthChallengeDisposition = NSURLSessionAuthChallengeDisposition.PerformDefaultHandling
        var trustResult:SecTrustResultType = UInt32(kSecTrustResultInvalid)
        var credential : NSURLCredential? = nil
        
        //获取服务器的trust object
        let serverTrust: SecTrustRef = challenge.protectionSpace.serverTrust!
        
        //将读取的证书设置为serverTrust的根证书
        err = SecTrustSetAnchorCertificates(serverTrust, self.trustedCertArr!)
        
        if(err == noErr){
            //通过本地导入的证书来验证服务器的证书是否可信，如果将SecTrustSetAnchorCertificatesOnly设置为NO，则只要通过本地或者系统证书链任何一方认证就行
            err = SecTrustEvaluate(serverTrust, &trustResult)
        }
        
        if(err == errSecSuccess && (trustResult == UInt32(kSecTrustResultProceed) || trustResult == UInt32(kSecTrustResultUnspecified))){
            //认证成功，则创建一个凭证返回给服务器
            disposition = NSURLSessionAuthChallengeDisposition.UseCredential
            credential = NSURLCredential(trust: serverTrust)
        }
        else{
            disposition = NSURLSessionAuthChallengeDisposition.CancelAuthenticationChallenge
        }
        
        //回调凭证，传递给服务器
        completionHandler(disposition, credential)
    }
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        let result = try! NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers)
        print(result)
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        print(error)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

