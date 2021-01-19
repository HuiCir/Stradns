
class Stradns: URLSessionDelegate{
    private var originIP = "112.90.70.72"
    private var domainName = "www.baidu.com"
    private var ipAddress:String = ""

    func Hello(){
        print("Hello Stradns!")
    }
    
    //URLSessionDetegate方法,用于https的证书单向认证
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust{
            print("服务端证书认证")
            
            //启用服务端单向认证
            let serverTrust:SecTrust = challenge.protectionSpace.serverTrust!
            SecTrustGetCertificateAtIndex(serverTrust, 0)
            let credential = URLCredential(trust: serverTrust)
            challenge.sender!.continueWithoutCredential(for: challenge)
            challenge.sender?.use(credential, for: challenge)
            
            completionHandler(URLSession.AuthChallengeDisposition.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
        }
    }
    
         
    // 使用URLSession进行请求数据
    func httpsGet(urlString: String) {
        let configuration = URLSessionConfiguration.default
        if let url = URL(string:"https://"+urlString){
        let request = URLRequest(url: url)
        let session = URLSession(configuration:configuration,delegate:self,delegateQueue:OperationQueue.main)
        let dataTask = session.dataTask(with: request,completionHandler: {(data, response, error) -> Void in
            if error != nil{
                print("访问失败，错误报告如下：")
                print(error!.localizedDescription)
            }else{
                let str = String(data: data!, encoding: String.Encoding.utf8)
                print("访问成功，获取数据如下：")
                print(str)
            }
        })
        //使用resume方法启动任务
        dataTask.resume()
        }else{
            print("URL初始化失败")
        }
    }

    //DNS获取域名对应IP
    func getIPAddress(domainName: String) -> String {
        var result = ""
        //通过域名创建Host
        let host = CFHostCreateWithName(nil,domainName as CFString).takeRetainedValue()
        CFHostStartInfoResolution(host, .addresses, nil)
        var success: DarwinBoolean = false
        //由Host解析主机IP
        if let addresses = CFHostGetAddressing(host, &success)?.takeUnretainedValue() as NSArray?,let theAddress = addresses.firstObject as? NSData {
            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            if getnameinfo(theAddress.bytes.assumingMemoryBound(to: sockaddr.self), socklen_t(theAddress.length),&hostname, socklen_t(hostname.count), nil,0,NI_NUMERICHOST) == 0{
                    let numAddress = String(cString: hostname)
                    result = numAddress
                    print(domainName+"-->"+numAddress)
                }
            }else{
                print("dns error")
            }
        return result
    }
    
    //判断dns是否正确
    func dnsDetection(domainName:String, ipAddress:String)->Bool{
        if getIPAddress(domainName: domainName)==ipAddress{
            return true
        }
        return false
    }
}
