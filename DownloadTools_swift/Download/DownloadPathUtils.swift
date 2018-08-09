//
//  DownloadPathUntil.swift
//  LCDownloadTools
//
//  Created by 郭连城 on 2018/8/8.
//  Copyright © 2018年 郭连城. All rights reserved.
//

import Foundation

//import CommonCrypto

class DownloadPathUtils {
    
    /**
     * 默认下载临时路径
     **/
    class func downloadTmpPath()->String{
        let documentPaths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
            let docsDir = documentPaths.first
            let tmpPath = docsDir!.appending("CLDownloadTmpFiles")
//            print("看看 path少不少//\(tmpPath)")
            DownloadPathUtils.checkFilePath(path: tmpPath)
            return tmpPath
    }
    
    /**
     * 默认下载路径
     **/
    class func downloadPath()->String{
        let documentPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let docsDir = documentPaths.first
        let tmpPath = docsDir! + "/" + "LCDownload"
//        print("看看 path少不少//\(tmpPath)")
        DownloadPathUtils.checkFilePath(path: tmpPath)
        return tmpPath
    }
    
    /**
     * 获取app  tmp 目录
     **/
    class func resumeDatatTmpPath()->String{
        let tmpDir = NSTemporaryDirectory()
        return tmpDir
    }
    
    
    /**
     * 计算URL的MD5值作为缓存数据文件名
     **/
    class func cachedFileNameForKey(key:String)->String{
        return key.md5
    }


    class func checkFilePath(path:String){
        
        var pointer = ObjCBool.init(false)//下边的方法也可以
//        let pointer = UnsafeMutablePointer<ObjCBool>.allocate(capacity: 1);
        let fileManager = FileManager.default
        
        let existed = fileManager.fileExists(atPath: path, isDirectory: &pointer)
    
        if (!(pointer.boolValue && existed)) {
            
            do{
               try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
            }catch let error {
                print(error)
            }
        }
    }
 

}



extension String {
    var md5 : String{
        let str = self.cString(using: String.Encoding.utf8)
        let strLen = CC_LONG(self.lengthOfBytes(using: String.Encoding.utf8))
        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)
        CC_MD5(str!, strLen, result)
        let hash = NSMutableString()
        for i in 0 ..< digestLen {
            hash.appendFormat("%02x", result[i])
        }
        result.deinitialize(count: digestLen)
        return String(format: hash as String)
    }
}
