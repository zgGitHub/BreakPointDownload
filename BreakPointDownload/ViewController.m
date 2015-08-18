//
//  ViewController.m
//  BreakPointDownload
//
//  Created by LZXuan on 15-7-16.
//  Copyright (c) 2015年 轩哥. All rights reserved.
//

#import "ViewController.h"
#import "NSString+Hashing.h"

#import "BreakPointDownload.h"
#define kUrl @"http://dlsw.baidu.com/sw-search-sp/soft/2a/25677/QQ_V4.0.0.1419920162.dmg"

@interface ViewController ()
{
    BreakPointDownload *_breakDownload;
    //定时器
    NSTimer *_timer;
}
- (IBAction)startClick:(UIButton *)sender;
- (IBAction)stopClick:(UIButton *)sender;
@property (weak, nonatomic) IBOutlet UIProgressView *downloadProgressView;

@property (weak, nonatomic) IBOutlet UILabel *label;



//保存当前已经下载
@property (nonatomic) unsigned long long loadedFileSize;
//前1s的已经下载
@property (nonatomic) unsigned long long preLoadedFileSize;
//下载速度
@property (nonatomic) double speed;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _breakDownload = [[BreakPointDownload alloc] init];
    //先获取之前保存的进度
    double s = [[NSUserDefaults standardUserDefaults] doubleForKey:[kUrl MD5Hash]];
    self.downloadProgressView.progress = s;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
// 启动一个定时器 专门计算 速度 时间间隔1s
- (IBAction)startClick:(UIButton *)sender {
    if (!_timer) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(getDownloadSpeed) userInfo:nil repeats:YES];
    }
    __weak typeof(self)weakSelf = self;
    
    [_breakDownload downloadDataWithUrl:kUrl loadingBlock:^(BreakPointDownload *download) {
        //每下载一段数据就会回调这个block
        //文件总大小
        double fileSize = download.totalFileSize/1024.0/1024.0;//转化为M
        //已经下载
        weakSelf.loadedFileSize = download.loadedFileSize;
        //百分比
        double scale = (double)download.loadedFileSize/download.totalFileSize;
        //进度条
        weakSelf.downloadProgressView.progress = scale;
        weakSelf.label.text = [NSString stringWithFormat:@"百分比:%.2f%% 文件总大小:%.2fM 当前速度:%.2fK/S",scale*100,fileSize,self.speed];
        //每次 把进度 保存到本地
        //把url 加密之后作为key
        [[NSUserDefaults standardUserDefaults] setDouble:scale forKey:[kUrl MD5Hash]];
        [[NSUserDefaults standardUserDefaults] synchronize];
        if (weakSelf.downloadProgressView.progress >= 1.0) {
            if (_timer) {
                [_timer invalidate];
                _timer = nil;//下载结束要终止定时器
            }
        }
    }];
    
}
//当前 - 前1s
// 1024字节 = 1K
//1024K = 1M
- (void)getDownloadSpeed{
    self.speed = (self.loadedFileSize-self.preLoadedFileSize)/1024.0;//得到小数
    
    //记录已经下载
    self.preLoadedFileSize = self.loadedFileSize;
}

- (IBAction)stopClick:(UIButton *)sender {
    [_breakDownload stopDownload];
    if (_timer) {
        [_timer invalidate];//销毁终止定时器
        _timer = nil;
    }
}
@end







