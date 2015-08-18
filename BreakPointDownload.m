//
//  BreakPointDownload.m
//  BreakPointDownload
//
//  Created by LZXuan on 15-7-16.
//  Copyright (c) 2015年 轩哥. All rights reserved.
//

#import "BreakPointDownload.h"
#import "NSString+Hashing.h"

/*
 ⾸首先来了解下这个东⻄西: Range头域
 Range头域可以请求实体的⼀一个或者多个⼦子范围。例如,   表⽰示头500个字节:bytes=0-499   表⽰示第⼆二个500字节:bytes=500-999   表⽰示最后500个字节:bytes=-500   表⽰示500字节以后的范围:bytes=500-   第⼀一个和最后⼀一个字节:bytes=0-0,-1   同时指定⼏几个范围:bytes=500-600,601-999
 实现断点下载就是在httpRequest中加⼊入 Range 头。
 [request addValue:@"bytes=500-" forHTTPHeaderField:@"Range"];
 ⾄至于能否正常实现断点续传,还要看服务器是否⽀支持。 如果⽀支持,⼀一切没问题。 如果不⽀支持可能出现两种情况,1.不理会你得range值,每次都重
 新下载数据;2.直接下载失败。
 */
@implementation BreakPointDownload
{
    NSFileHandle *_fileHandle;//文件句柄
}
- (void)downloadDataWithUrl:(NSString *)url loadingBlock:(DownloadBlock)myblock {
    if (_httpRequest) {
        [_httpRequest cancel];
        _httpRequest = nil;
    }
    //保存 block
    self.myBlock = myblock;
    
    //发送请求之前先获取本地文件已经下载的大小，然后告知服务器从哪里下载
    //先获取路径
    NSString *filePath = [self getFullPathWithFileUrl:url];
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        //检测文件是否存在
        //不存在那么要创建
        [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
    }
    //获取路径下的文件大小
    NSDictionary *fileDict = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
    unsigned long long fileSize = fileDict.fileSize;
    //保存已经下载文件的大小
    self.loadedFileSize = fileSize;
    
    //下载文件之前 先打开文件
    _fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
    
    //把文件大小告知服务器
    //创建可变请求 增加请求头
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    //增加请求头 告知服务器 从 哪个字节之后开始下载
    [request addValue:[NSString stringWithFormat:@"bytes=%llu-",fileSize] forHTTPHeaderField:@"Range"];
    //创建请求连接 开始异步下载
    _httpRequest = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
    
}

#pragma mark - 获取文件在沙盒中Documents下的全路径
- (NSString *)getFullPathWithFileUrl:(NSString *)url {
    //我们把url 作为文件名字-》但是url 中可能存在一些非法字符不能作为文件名，这时我们可以用md5 对文件名进行加密 产生一个唯一的字符串 (十六进制的数字+A-F表示)
    NSString *fileName = [url MD5Hash];//MD5
    //获取Documents
    NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)lastObject];
    //拼接路径
    NSString *filePath = [docPath stringByAppendingPathComponent:fileName];
    NSLog(@"path:%@",filePath);
    return filePath;
}

#pragma mark - NSURLConnectionDataDelegate
//接收服务器响应
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    //服务器会告知客户端 服务器将要发生的数据大小
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    NSLog(@"url:%@",httpResponse.URL.absoluteString);
    NSLog(@"type:%@",httpResponse.MIMEType);//类型
    //计算文件总大小 = 已经下载的+服务器将要发的
    self.totalFileSize = self.loadedFileSize+httpResponse.expectedContentLength;
}
//接收数据过程 一段一段接收
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    //下载一段 写一段数据
    //先把文件偏移量定位到文件尾
    [_fileHandle seekToEndOfFile];
    //写文件
    [_fileHandle writeData:data];
    //立即同步到磁盘
    [_fileHandle synchronizeFile];
    //记录已经下载数据大小
    self.loadedFileSize += data.length;
    
    //通知 界面
    //回调block ->下载过程中一直会回调
    if (self.myBlock) {
        self.myBlock (self);
    }
}
//下载完成
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self stopDownload];//停止下载
}
//下载失败
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self stopDownload];
}
- (void)stopDownload {
    if (_httpRequest) {
        [_httpRequest cancel];
        _httpRequest = nil;
    }
    [_fileHandle closeFile];//关闭文件
}

@end









