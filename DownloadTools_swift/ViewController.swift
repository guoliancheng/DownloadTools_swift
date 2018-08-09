//
//  ViewController.swift
//  LCDownloadTools
//
//  Created by 郭连城 on 2018/8/7.
//  Copyright © 2018年 郭连城. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    let tableView = UITableView.init()
    
    let modes = ["http://dldir1.qq.com/qqfile/qq/QQ8.4/18357/QQ8.4.exe",
                 "http://dldir1.qq.com/weixin/Windows/WeChatSetup.exe",
                 "http://dlsw.baidu.com/sw-search-sp/soft/31/12612/AdbeRdr11000_zh_CN11.0.1.210.1459417824.exe",
                 "https://res.psy-1.com/music/meditation_snowy_plus-iSwClBy6INhmOyMeCX5A.mp3",
                 "https://res.psy-1.com/music/meditation_grassland_plus-lCMjm75JYOiwH7BSiima.mp3",
                 "https://res.psy-1.com/music/meditation_winter_plus-Fx9bJgqMN6BBvdiDfPui.mp3"]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(LCTableViewCell.self, forCellReuseIdentifier: "a")
        view.addSubview(tableView)
        tableView.frame = view.frame
        tableView.dataSource = self
        tableView.rowHeight = 70
    }
}

extension ViewController:UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return modes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "a") as? LCTableViewCell
        //        cell?.textLabel?.text = modes[indexPath.row]
        cell?.url = modes[indexPath.row]
        return cell!
    }
}


class LCTableViewCell: UITableViewCell {
    
    
    
    var url = ""
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addSubview(buttn)
        buttn.frame = CGRect.init(x: 0, y: 0, width: 100, height: 39)
        buttn.addTarget(self, action: #selector(buttonClick), for: .touchUpInside)
        buttn.setTitle("下载", for: .normal)
        buttn.setTitleColor(UIColor.blue, for: .normal)
        addSubview(progress)
        progress.text = "0"
        progress.frame = CGRect.init(x: 150, y: 0, width: 100, height: 39)
        
        addSubview(progressView)
        progressView.frame = CGRect.init(x: 10, y: 40, width: 300, height: 20)
    }
    
    @objc func buttonClick(){
        let request = LCDownloadRequest.initWithURL(url: url)
        request.delegate = self
        request.httpMethod = "GET"
        request.allowResume = true
        request.startDownload()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var buttn = UIButton()
    var progressView = UIProgressView.init()
    var progress = UILabel.init()
}


extension LCTableViewCell:LCDownloadDelegate{
    func requestDownloadStart(request:LCDownloadRequest){
        guard request.url == url else {
            printLog("url!=url,")
            return
        }
        self.progress.text = "开始下载\(request.progress)"
        printLog(request)
    }
    func requestDownloading(request:LCDownloadRequest){
        guard request.url == url else {
            printLog("url!=url,")
            return
        }
        //        printLog(request.progress)
        self.progressView.progress = request.progress
        //        self.progress.text = "\(request.progress)"
    }
    func requestDownloadPause(request:LCDownloadRequest){
        guard request.url == url else {
            printLog("url!=url,")
            return
        }
        printLog(request)
        self.progress.text = "暂停中\(request.progress)"
    }
    func requestDownloadCancel(request:LCDownloadRequest){
        guard request.url == url else {
            printLog("url!=url,")
            return
        }
        self.progress.text = "取消了\(request.progress)"
        printLog(request)
    }
    func requestDownloadFinish(request:LCDownloadRequest){
        guard request.url == url else {
            printLog("url!=url,")
            return
        }
        self.progress.text = "下完了\(request.progress)"
        printLog("\(request.url),\(request.savePath)")
    }
    
    func requestDownloadFaild(request:LCDownloadRequest,error:Error){
        guard request.url == url else {
            printLog("url!=url,")
            return
        }
        self.progress.text = "出错了\(request.progress)"
        printLog(request)
    }
}

