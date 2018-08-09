//
//  LCDownloadDelegate.swift
//  LCDownloadTools
//
//  Created by 郭连城 on 2018/8/8.
//  Copyright © 2018年 郭连城. All rights reserved.
//

import Foundation

@objc protocol LCDownloadDelegate : class {
    
    @objc optional func requestDownloadStart(request:LCDownloadRequest)
    @objc optional func requestDownloading(request:LCDownloadRequest)
    @objc optional func requestDownloadPause(request:LCDownloadRequest)
    @objc optional func requestDownloadCancel(request:LCDownloadRequest)
    @objc optional func requestDownloadFinish(request:LCDownloadRequest)
    @objc optional func requestDownloadFaild(request:LCDownloadRequest,error:Error)

}

