//
//  LCDownloadConfig.swift
//  LCDownloadTools
//
//  Created by 郭连城 on 2018/8/8.
//  Copyright © 2018年 郭连城. All rights reserved.
//

import Foundation



enum LCDownloadRequestState {
    case none //仅仅初始化未做任何操作(既未加入任务队列中)
    case wait //等待下载已加入任务队列但未开始
    case loading//正在下载
    case pause //暂停 已存在任务队列中 属于挂起状态
    case cancel//取消任务
}

let maxConcurrentTaskCount = 5 //下载队列并发数

func printLog<T>(_ message: T, file: NSString = #file, method: String = #function, line: Int = #line){
    //    #if DEBUG
    print("\(method)[\(line)]: \(message)")
    //    #endif
}

struct Platform {
    static let isSimulator: Bool = {
        var isSim = false
        #if arch(i386) || arch(x86_64)
        isSim = true
        #endif
        return isSim
    }()
}
