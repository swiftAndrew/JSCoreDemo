//
//  ViewController.swift
//  JSCoreDemo
//
//  Created by anlu on 2017/9/16.
//  Copyright © 2017年 anlu. All rights reserved.
//

import UIKit
import JavaScriptCore


// 定义协议SwiftJavaScriptDelegate 该协议必须遵守JSExport协议
@objc protocol SwiftJavaScriptDelegate: JSExport {
    
    // js调用App的微信支付功能 演示最基本的用法
    func wxPay(_ orderNo: String)
    
    // js调用App的微信分享功能 演示字典参数的使用
    func wxShare(_ dict: [String: AnyObject])
    
    // js调用App方法时传递多个参数 并弹出对话框 注意js调用时的函数名
    func showDialog(_ title: String, message: String)
    
    // js调用App的功能后 App再调用js函数执行回调
    func callHandler(_ handleFuncName: String)
    
}

// 定义一个模型 该模型实现SwiftJavaScriptDelegate协议
@objc class SwiftJavaScriptModel: NSObject, SwiftJavaScriptDelegate {
    
    weak var controller: UIViewController?
    weak var jsContext: JSContext?
    
    func wxPay(_ orderNo: String) {
        
        print("订单号：", orderNo)
        
        // 调起微信支付逻辑
    }
    
    func wxShare(_ dict: [String: AnyObject]) {
        
        print("分享信息：", dict)
        
        // 调起微信分享逻辑
    }
    
    func showDialog(_ title: String, message: String) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default, handler: nil))
        self.controller?.present(alert, animated: true, completion: nil)
    }
    
    func callHandler(_ handleFuncName: String) {
        
        let jsHandlerFunc = self.jsContext?.objectForKeyedSubscript("\(handleFuncName)")
        let dict = ["name": "sean", "age": 18] as [String : Any]
        let _ = jsHandlerFunc?.call(withArguments: [dict])
    }
}

class ViewController: UIViewController,UIWebViewDelegate {
    var webView: UIWebView!
    var jsContext: JSContext!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        test()
        
        addWebView()
    }

    
    /*
     JSContext：JSContext是JS的执行环境，通过evaluateScript()方法可以执行JS代码
     JSValue：JSValue封装了JS与ObjC中的对应的类型，以及调用JS的API等
     JSExport：JSExport是一个协议，遵守此协议，就可以定义我们自己的协议，在协议中声明的API都会在JS中暴露出来，这样JS才能调用原生的API
     */
    func test() -> Void
    {
        //通过JSContext 执行js代码
        let context = JSContext()
        let result:JSValue = (context?.evaluateScript("1+3"))!
        print(result)
        
        //定义js的变量和函数
        context?.evaluateScript("var num1= 10;var num2=20;")
        context?.evaluateScript("function sum(p1,p2){return p1+p2;}")
        
        //通过js方法名调用方法
        let result2 = context?.evaluateScript("sum(num1,num2);")
        print(result2!)
        
        // 通过下标来获取js方法并调用方法
        let squareFunc = context?.objectForKeyedSubscript("sum")
        let result3 = squareFunc?.call(withArguments: [10, 20]).toString()
        print(result3 ?? "100")  // 输出30
        
        
     
    }
    
    func addWebView() -> Void {
        
        self.webView = UIWebView(frame: self.view.bounds)
        self.view.addSubview(self.webView)
        self.webView.delegate = self
        self.webView.scalesPageToFit = true
        
        // 加载本地Html页面
        let url = Bundle.main.url(forResource: "demo", withExtension: "html")
        let request = URLRequest(url: url!)
        
        // 加载网络Html页面 请设置允许Http请求
        //let url = NSURL(string: "http://www.mayanlong.com");
        //let request = NSURLRequest(URL: url!)
        
        self.webView.loadRequest(request)
    }
   
    func webViewDidStartLoad(_ webView: UIWebView) {
        
        self.jsContext = webView.value(forKeyPath: "documentView.webView.mainFrame.javaScriptContext") as! JSContext
        let model = SwiftJavaScriptModel()
        model.controller = self
        model.jsContext = self.jsContext
        
        // 这一步是将SwiftJavaScriptModel模型注入到JS中，在JS就可以通过WebViewJavascriptBridge调用我们暴露的方法了。
        self.jsContext.setObject(model, forKeyedSubscript: "WebViewJavascriptBridge" as NSCopying & NSObjectProtocol)
        
        // 注册到本地的Html页面中
        let url = Bundle.main.url(forResource: "demo", withExtension: "html")
        self.jsContext.evaluateScript(try? String(contentsOf: url!, encoding: String.Encoding.utf8))
        
        // 注册到网络Html页面 请设置允许Http请求
        //let url = "http://www.mayanlong.com";
        //let curUrl = self.webView.request?.URL?.absoluteString    //WebView当前访问页面的链接 可动态注册
        //self.jsContext.evaluateScript(try? String(contentsOfURL: NSURL(string: url)!, encoding: NSUTF8StringEncoding))
        
        self.jsContext.exceptionHandler = { (context, exception) in
            print("exception：", exception as Any)
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}

