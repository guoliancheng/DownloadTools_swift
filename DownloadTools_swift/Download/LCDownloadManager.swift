//
//  LCDownloadManager.swift
//  LCDownloadTools
//
//  Created by 郭连城 on 2018/8/8.
//  Copyright © 2018年 郭连城. All rights reserved.
//

import Foundation
import UIKit

class LCDownloadManager: NSObject {
    static let downloadManagerInstance = LCDownloadManager()
    
    var queue : OperationQueue
    
    private override init() {
        self.queue = {
            let operationQueue = OperationQueue()
            
            operationQueue.maxConcurrentOperationCount = 100
            operationQueue.isSuspended = false
            operationQueue.qualityOfService = .utility
            
            return operationQueue
        }()
        super.init()
        
        
        let defaultSessionConfig = URLSessionConfiguration.default
        defaultSessionConfig.httpMaximumConnectionsPerHost = 100
//        defaultSessionConfig.requestCachePolicy = .reloadRevalidatingCacheData
//        defaultSessionConfig.timeoutIntervalForRequest = 120; //给定时间内没有数据传输的超时时间
//        defaultSessionConfig.timeoutIntervalForResource = 60; //给定时间内服务器查找资源超时时间
         defaultSession = URLSession.init(configuration: defaultSessionConfig,
                                          delegate: self,
                                          delegateQueue: queue)
    }
    
    func requestForURL(url:String)->LCDownloadRequest?{
        for tmpRequest in self.taskList {
            if (tmpRequest.url == url) {
                return tmpRequest
            }
        }
        return nil
    }
    
    //MARK:- 控制下载队列数量
    func refreshDownloadTask(){
        downloadQueue.async {
            var startCount = 0
            var hasTaskRuning = false
            for req in self.taskList {
                if (req.state == .loading) {
                    startCount += 1
                    hasTaskRuning = true
                }else if (req.state == .wait) {
                    req.state = .loading;
                    req.task?.resume()
                    startCount += 1
                    hasTaskRuning = true
                    DispatchQueue.main.async(execute: {
                        req.delegate?.requestDownloadStart?(request: req)
                    })
                }
                if (startCount >= maxConcurrentTaskCount) {
                    break
                }
            }
//            if !Platform.isSimulator{
//                DispatchQueue.main.async(execute: {
//                    UIApplication.shared.isNetworkActivityIndicatorVisible = hasTaskRuning
//                })
//            }
        }
    }

    /**
     * 添加下载任务/恢复下载任务
     **/
    func updateTaskListRequst(request:LCDownloadRequest){
        downloadQueue.async {
            if self.taskList.contains(request){
                printLog("包含此下载请求..将其调整至任务队列最后")
                let tmpRequest = request
                
                if  let index = self.taskList.index(of: request){
                    self.taskList.remove(at: index)
                    self.taskList.append(tmpRequest)
                }
            }else {
                printLog("不包含此下载请求..将其加入任务队列中")
                self.taskList.append(request)
            }
            DispatchQueue.main.sync {
                self.refreshDownloadTask()
            }
        }
    }
    
    /**
     *移除下载任务 条件如下
     * 1)下载完成
     * 2)下载失败
     **/
    func removeTasklistAtRequest(request:LCDownloadRequest) {
//        if (!request) {
//            return
//        }
        downloadQueue.async {
            if let index = self.taskList.index(of: request){
                self.taskList.remove(at: index)
            }
            DispatchQueue.main.async {
                self.refreshDownloadTask()
            }
        }
    }

    func startRequestTask(request:LCDownloadRequest){
        if(request.request == nil) {
            printLog("CLDownload ERROR Request is nil, check your URL and other parameters you use to build your request")
            return
        }
        
        var task : URLSessionDownloadTask
        if (request.allowResume && request.resumeData != nil) {
            task = self.defaultSession.downloadTask(withResumeData: request.resumeData!)
        }else {
            task = self.defaultSession.downloadTask(with: request.request)
        }
        request.task = task
        request.state = .wait
        self.updateTaskListRequst(request: request)
    }
    
    /// 暂停任务
    ///
    /// - Parameter request: request description
    func pauseRequest(request:LCDownloadRequest){
        request.state = .pause
        self.refreshDownloadTask()
        DispatchQueue.main.async {
            request.delegate?.requestDownloadPause?(request: request)
        }
    }
    
    
    /// 取消下载任务
    ///
    /// - Parameter request: request description
    func cancelRequest(request:LCDownloadRequest){
        request.state = .cancel
        request.deleteResumeDatat()
        self.removeTasklistAtRequest(request: request)
        DispatchQueue.main.async {
            request.delegate?.requestDownloadCancel?(request: request)
        }
    }
    
    
    let downloadQueue = DispatchQueue.init(label: "sss", qos: DispatchQoS.utility) //DispatchQueue(label: "LCdownloadQueue")
    
    var taskList :[LCDownloadRequest] = []
    var defaultSession : URLSession!
}


extension LCDownloadManager:URLSessionDelegate,URLSessionDownloadDelegate{
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {

        for request in self.taskList {
            guard request.task?.currentRequest?.url?.absoluteString == downloadTask.currentRequest?.url?.absoluteString else{
                break
            }

            self.removeTasklistAtRequest(request: request)
            
            request.deleteResumeDatat() //移除断点续传缓存数据文件
            let savePath = request.savePath + "/" + request.saveFileName

            do{
               try FileManager.default.moveItem(at: location.absoluteURL, to: URL.init(fileURLWithPath: savePath))
            }catch let error{
                printLog("CLDownload ERROR Failed to save downloaded file at requested path [\(request.savePath)] with error \(error)")
                DispatchQueue.main.async {
                    request.delegate?.requestDownloadFaild?(request: request, error: error)
                }
                return
            }
            DispatchQueue.main.async {
                request.delegate?.requestDownloadFinish?(request: request)
            }
            return
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                              didWriteData bytesWritten: Int64,
                                      totalBytesWritten: Int64,
                              totalBytesExpectedToWrite: Int64) {
        
        
        let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        for request in taskList{
            guard request.task?.currentRequest?.url?.absoluteString == downloadTask.currentRequest?.url?.absoluteString else{
                break
            }
            if (request.progress > request.progress) {
                printLog("CLDownload ERROR 下载进度异常....")
            }
            if request.saveFileName.isEmpty{
                if let fileName = downloadTask.response?.suggestedFilename{
                    request.saveFileName = fileName
                }
            }
            request.progress = progress
            DispatchQueue.main.async {
                request.delegate?.requestDownloading?(request: request)
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                           didResumeAtOffset fileOffset: Int64,
                                     expectedTotalBytes: Int64) {
        /**
         * fileOffset：继续下载时，文件的开始位置
         * expectedTotalBytes：剩余的数据总数
         */
        printLog("didResumeAtOffset  fileOffset: \(fileOffset)  expectedTotalBytes: \(expectedTotalBytes)")
    }
    
    //MARK: - NSURLSessionTaskDelegate
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
        var matchingRequest : LCDownloadRequest?
        for request in taskList{
            if(request.task == task) {
                matchingRequest = request
                break
            }
        }
        
        if matchingRequest != nil{
            self.removeTasklistAtRequest(request: matchingRequest!)
        }
        
        
        guard error != nil else{
            printLog("错误为空,下载完成")
            DispatchQueue.main.async {
                matchingRequest?.delegate?.requestDownloadFinish?(request: matchingRequest!)
            }
            return
        }
        
        let nsError:NSError = error! as NSError
        
        if nsError.code == NSURLErrorCancelled {
            printLog("CLDownload ERROR 请求取消")
        }
        if nsError.code == URLError.cancelled.rawValue {
            printLog("CLDownload ERROR 请求取消")
        }
        
        if(error != nil) {
            printLog("CLDownload ERROR Failed to  downloaded  with error \(error!)")
            DispatchQueue.main.async {
                matchingRequest?.delegate?.requestDownloadFaild?(request: matchingRequest!, error: error!)
            }
        }
    }
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        printLog("出错了这里\(String(describing: error))")
    }
    
    
    
    
    //MARK:- NSURLSession Authentication delegates
    
    func urlSession(_ session: URLSession, task: URLSessionTask,
                    didReceive challenge: URLAuthenticationChallenge,
                completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust{
            
            let credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
            let disposition = Foundation.URLSession.AuthChallengeDisposition.useCredential
            completionHandler(disposition,credential)
        }
        
        
        
        var matchingRequest : LCDownloadRequest?
        for request in taskList{
            if request.task == task{
                matchingRequest = request
            }
        }

        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPBasic || challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPDigest{
            
            if(challenge.previousFailureCount == 3) {
            completionHandler(URLSession.AuthChallengeDisposition.rejectProtectionSpace, nil)
            } else {
                let userName = matchingRequest?.username ?? ""
                let passWord = matchingRequest?.password ?? ""
                let credential = URLCredential.init(user: userName, password: passWord, persistence: URLCredential.Persistence.none)
                
                    completionHandler(URLSession.AuthChallengeDisposition.useCredential, credential)
            }
        }
    }
}

