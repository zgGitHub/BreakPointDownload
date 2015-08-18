//
//  BreakPointDownload.h
//  BreakPointDownload
//
//  Created by LZXuan on 15-7-16.
//  Copyright (c) 2015年 轩哥. All rights reserved.
//

#import <Foundation/Foundation.h>
/*
 有时候我们在下载数据的时候 需要暂停，过会时间之后继续下载(从已经下载数据之后开始)，这时我们需要实现 断点续传 
 要做断点续传 服务器和客户端都必须要支持 否则 不会成功的
 */

//定义block 回调 告知界面 下载进度

@class BreakPointDownload;

typedef void (^DownloadBlock)(BreakPointDownload * download);

@interface BreakPointDownload : NSObject <NSURLConnectionDataDelegate>
{
    NSURLConnection *_httpRequest;//请求连接
}
//记录文件总大小 字节大小
@property (nonatomic) unsigned long long  totalFileSize;
//已经下载的文件大小
@property (nonatomic) unsigned long long loadedFileSize;

//保存block
@property (nonatomic,copy) DownloadBlock myBlock;

//请求下载方法
//传入一个block  下载过程中要回调block 告知界面 下载信息
- (void)downloadDataWithUrl:(NSString *)url loadingBlock:(DownloadBlock)myblock;
//停止下载
- (void)stopDownload;
@end











