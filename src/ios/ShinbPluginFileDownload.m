/********* ShinbPluginFileDownload.m Cordova Plugin Implementation *******/

#import "ShinbPluginFileDownload.h"

@implementation ShinbPluginFileDownload

- (void)coolMethod:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
    NSString* echo = [command.arguments objectAtIndex:0];
    
    if (echo != nil && [echo length] > 0) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:echo];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

#pragma mark 获取下载信息
-(void)sbDownloadInfo:(CDVInvokedUrlCommand*)command{
    CDVPluginResult* pluginResult = nil;
    NSString* url = [command.arguments objectAtIndex:0];
    
    if (url != nil && [url length] > 0) {
        NSMutableDictionary *dict = [NSMutableDictionary new];
        
        float progress = [self getDownloadProgress:url];
        [dict setValue:[NSString stringWithFormat:@"%.4f",progress] forKey:@"progress"];
        if(progress >= 1.0f){
            [dict setValue:[NSNumber numberWithBool:YES] forKey:@"isComplete"];
            [dict setValue:[NSNumber numberWithBool:NO] forKey:@"isDownloading"];
        }else{
            [dict setValue:[NSNumber numberWithBool:NO] forKey:@"isComplete"];
            
            TCBlobDownloader *downloader = [self getDownloader:url];
            [dict setValue:[NSNumber numberWithBool:downloader ? YES:NO] forKey:@"isDownloading"];
        }
        
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dict];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

#pragma mark 下载文件
- (void)sbDownload:(CDVInvokedUrlCommand*)command{
    CDVPluginResult* pluginResult = nil;
    NSString* url = [command.arguments objectAtIndex:0];
    NSString* directory = [command.arguments objectAtIndex:1];
    
    if (url != nil && [url length] > 0 && directory != nil && [directory length] > 0) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@""];
        if([directory hasPrefix:@"file://"]){
            directory = [directory substringFromIndex:8];
        }
        [self downloadFile:url path:directory];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

#pragma mark 取消下载
-(void)sbCancel:(CDVInvokedUrlCommand*)command{
    CDVPluginResult* pluginResult = nil;
    NSString* url = [command.arguments objectAtIndex:0];
    
    if (url != nil && [url length] > 0) {
        [self cancel:url];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@""];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

#pragma mark 取消所有下载
-(void)sbCancelAll:(CDVInvokedUrlCommand*)command{
    CDVPluginResult* pluginResult = nil;
    [self cancelAll];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@""];
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

#pragma mark下载文件
-(void)downloadFile:(NSString *)url path:(NSString *)directory{
    TCBlobDownloader *downloader = [self getDownloader:url];
    if(downloader){
        //如果已经加入下载器则重新resume下
        return;
    }
    NSURL *nsURL = [NSURL URLWithString:url];
    downloader = [[TCBlobDownloader alloc] initWithURL:nsURL
                                          downloadPath:directory
                                              delegate:self];
    [self addDownloader:url downloader:downloader];
    [[TCBlobDownloadManager sharedInstance] startDownload:downloader];
}

#pragma mark 取消下载
-(void)cancelAll{
    for(TCBlobDownloader *downloader in [self getDownloaderDict].allValues){
        if(downloader){
            [downloader cancelDownloadAndRemoveFile:NO];
        }
    }
    [[self getDownloaderDict] removeAllObjects];
}

-(void)cancel:(NSString *)url{
    TCBlobDownloader *downloader = [self getDownloader:url];
    if(downloader){
        [downloader cancelDownloadAndRemoveFile:NO];
    }
    [[self getDownloaderDict] removeObjectForKey:[self md5:url]];
}

#pragma mark 初始化下载器字典,并存储下载字典，当前APP运行有效
-(NSMutableDictionary *)getDownloaderDict{
    if(!self.downloaderDict){
        self.downloaderDict = [NSMutableDictionary new];
    }
    return self.downloaderDict;
}

-(TCBlobDownloader *)getDownloader:(NSString *)url{
    return [[self getDownloaderDict] objectForKey:[self md5:url]];
}

-(void)addDownloader:(NSString *)url downloader:(TCBlobDownloader *)downloader{
    if([[self getDownloaderDict] objectForKey:[self md5:url]]){
        return;
    }
    [[self getDownloaderDict] setObject:downloader forKey:[self md5:url]];
}

#pragma mark 下载进度保存/读取处理
-(void)saveDownloadProgress:(NSString *)url progress:(float)progress{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setFloat:progress forKey:[self md5:url]];
}

-(float)getDownloadProgress:(NSString *)url{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults floatForKey:[self md5:url]];
}

#pragma md5加密
-(NSString*)md5:(NSString *)message {
    const char *cStr = [message UTF8String];
    unsigned char result[16];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), result);
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

#pragma mark - TCBlobDownloader Delegate
- (void)download:(TCBlobDownloader *)blobDownload didFinishWithSuccess:(BOOL)downloadFinished atPath:(NSString *)pathToFile{
    //下载完成
    [self cancel:blobDownload.downloadURL.absoluteString];
    [self saveDownloadProgress:blobDownload.downloadURL.absoluteString progress:1.f];
    NSLog(@"url:%@",blobDownload.downloadURL.absoluteURL);
}

- (void)download:(TCBlobDownloader *)blobDownload
  didReceiveData:(uint64_t)receivedLength
         onTotal:(uint64_t)totalLength
        progress:(float)progress{
    //下载进度回调
    [self saveDownloadProgress:blobDownload.downloadURL.absoluteString progress:progress];
    //NSLog(@"url:%@,progress:%.2f",blobDownload.downloadURL.absoluteURL,progress);
}

- (void)download:(TCBlobDownloader *)blobDownload didReceiveFirstResponse:(NSURLResponse *)response{
    //首次收到数据
    //NSLog(@"url:%@,response:%@",blobDownload.downloadURL.absoluteURL,response);
}

- (void)download:(TCBlobDownloader *)blobDownload didStopWithError:(NSError *)error{
    //失败
    [self cancel:blobDownload.downloadURL.absoluteString];
    NSLog(@"url:%@,error:%@",blobDownload.downloadURL.absoluteURL,error);
}

@end

