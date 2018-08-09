//
//  LCDownloadRequest.swift
//  LCDownloadTools
//
//  Created by 郭连城 on 2018/8/8.
//  Copyright © 2018年 郭连城. All rights reserved.
//

import Foundation

class LCDownloadRequest:NSObject{
    
    
   convenience init(url:String) {
        self.init()
        self.url = url
        self.httpMethod = "GET"
        self.doInit()
    }
    /**
     * 实例化请求对象 已经存在则返回 不存在则创建一个并返回
     **/
    class func initWithURL(url:String)->LCDownloadRequest{
        var request = LCDownloadManager.downloadManagerInstance.requestForURL(url: url)
        
        if (request == nil) {
            request = LCDownloadRequest.init(url: url)
        }
        return request!
    }
 
    func requestUrl()->URL{
        return URL.init(string: url)!
    }
    
    
    func doInit(){
        self.request = URLRequest.init(url: self.requestUrl())
        self.request.cachePolicy = .reloadRevalidatingCacheData
        
        //    self.request.timeoutInterval = 60;
//        self.request.httpMethod = self.httpMethod
        self.allowResume = false
        self.resumeData = self.readResumeData()
//        [self setHeadInfo]
    }
    /**
     * 读取本地保存的文件下载断点位置信息数据
     **/
    func readResumeData()->Data?{
        let resumeDataPath = DownloadPathUtils.resumeDatatTmpPath() + "/" + DownloadPathUtils.cachedFileNameForKey(key: url)
        if let resume_Data = NSData.init(contentsOfFile: resumeDataPath){
            return resume_Data as Data
        }
        return nil
    }
    /**
     *开始下载任务 适用于首次添加下载任务
     **/
    func startDownload(){
        self.manager?.startRequestTask(request: self)
    }
    /**
     * 暂停下载任务
     * 注意初始化时allowResume 属性为YES 否则无效
     **/
    func pauseDownload(){
    if (!self.allowResume) {
        printLog("CLDownload ERROR: 当前设置的 allowResume 属性为 不支持断点续传, 如果需要请打开此属性")
        return
    }
        
    if (self.state == .pause) {
        printLog("CLDownload ERROR: 任务暂停失败 因为此任务本身处于暂停状态")
        return
    }
//    __weak typeof(self) wself = self;
        self.task?.cancel(byProducingResumeData: { [weak self](resumeData) in
            // resumeData : 包含了继续下载的开始位置\下载的url
            self?.resumeData = resumeData
            self?.task = nil
            self?.manager?.pauseRequest(request: self!)
            self?.resumeDatatWriteToFile()
        })
    }
    
    //断点缓存数据写入文件
    func resumeDatatWriteToFile(){
        if (self.resumeData == nil) {
            printLog("ERROR resumeData 为空")
            return
        }
        let tmpPath = DownloadPathUtils.resumeDatatTmpPath() + "/" + DownloadPathUtils.cachedFileNameForKey(key: url)
        
       let isTrue = (self.resumeData! as NSData).write(toFile: tmpPath, atomically: false)
        
        if (!isTrue) {
            printLog("ERROR resumeData 缓存数据写入失败")
        }
    }
    //移除断点缓存数据
    func deleteResumeDatat() {
    let tmpPath = DownloadPathUtils.resumeDatatTmpPath() + "/" + DownloadPathUtils.cachedFileNameForKey(key: url)
        if FileManager.default.fileExists(atPath: tmpPath){
           try? FileManager.default.removeItem(atPath: tmpPath)
        }
    }
    
    /**
     * 恢复下载任务
     * 注意初始化时allowResume 属性为YES 否则无效
     **/
    func resumeDownload(){
        guard self.allowResume else {
            printLog("CLDownload ERROR: 当前设置的 allowResume 属性为 不支持断点续传, 如果需要请打开此属性")
            return
        }
        
        guard self.state == .pause else{
            printLog("CLDownload ERROR: 任务恢复失败 因为此任务本身处于非暂停状态")
            return
        }
        self.manager?.startRequestTask(request: self)
        self.resumeData = nil
    }
    
    /**
     * 取消下载任务
     **/
    func cancelDownload(){
        if (self.state == .loading) {
            self.task?.cancel()
        }
        self.manager?.cancelRequest(request: self)
    }

    
    
    
    private override init() {
        
    }
    deinit {
        print("dealloc -- CLDownloadRequest")
    }
    
    
    private(set) var request : URLRequest!//请求对象
    
    var state : LCDownloadRequestState = .none            //请求状态
    var httpMethod : String = ""{                        //请求方式 默认GET
        didSet{ self.request.httpMethod = httpMethod }
    }
    var tempPath : String {                          //临时文件目录 暂未使用
        return DownloadPathUtils.downloadTmpPath()
    }
    
    var savePath : String{                      //保存文件路径 默认 Document/CLDownload/
        return DownloadPathUtils.downloadPath()
    }
    
    var saveFileName : String = ""                    //保存文件名 默认服务器返回的文件名
    var username : String    = ""                      //用户名 暂未想好怎么用
    var password : String    = ""                     //密码   暂未想好怎么用
    var allowResume:Bool = false                   //是否支持断点续传 默认NO
    var task: URLSessionDownloadTask?                //下载任务对象
    weak var delegate: LCDownloadDelegate?         //代理
    var progress : Float = 0                      //下载进度 范围0.0~1.0
    var url : String = ""              //下载文件的远程地址URL
    private(set) var resumeData:Data?         //断点续传的Data(包含URL信息)
    
    weak var manager = LCDownloadManager.downloadManagerInstance
}
