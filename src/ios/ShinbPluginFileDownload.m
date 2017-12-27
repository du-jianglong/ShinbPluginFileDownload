/********* ShinbPluginFileDownload.m Cordova Plugin Implementation *******/

#import "ShinbPluginFileDownload.h"

@implementation ShinbPluginFileDownload

#pragma mark 示例方法
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

#pragma mark 判空
-(BOOL)isEmpty:(NSString *)string{
    return string == nil || [string isEqualToString:@""] || [string length] <= 0;
}

#pragma mark 下载文件
- (void)sbDownload:(CDVInvokedUrlCommand*)command{
    CDVPluginResult* pluginResult = nil;
    
    NSString *url = [command.arguments objectAtIndex:0];
    NSString *directory = [command.arguments objectAtIndex:1];
    
    if([self isEmpty:url] || [self isEmpty:directory]){
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"The url or directory is null."];
    }else{
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@""];
        [self downloadFile:url path:[self handlerDirectory:directory]];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

#pragma mark 下载信息
-(void)sbDownloadInfo:(CDVInvokedUrlCommand*)command{
    CDVPluginResult* pluginResult = nil;
    NSString* url = [command.arguments objectAtIndex:0];
    
    if (![self isEmpty:url]) {
        NSMutableDictionary *dict = [NSMutableDictionary new];
        
        float progress = [self getDownloadProgress:[self md5:url]];
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
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"The url is null."];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

#pragma mark 暂停下载（保留已下载文件）
-(void)sbCancel:(CDVInvokedUrlCommand*)command{
    CDVPluginResult* pluginResult = nil;
    
    NSString* url = [command.arguments objectAtIndex:0];
    
    if (![self isEmpty:url]) {
        [self pause:url];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@""];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"The url is null."];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

#pragma mark 取消下载（删除已下载文件）
-(void)sbCancelAndDel:(CDVInvokedUrlCommand*)command{
    CDVPluginResult* pluginResult = nil;
    
    NSString* url = [command.arguments objectAtIndex:0];
    NSString* directory = [command.arguments objectAtIndex:1];
    
    if (![self isEmpty:url] && ![self isEmpty:directory]) {
        [self cancel:url];
        
        url = [self URLDecodedString:url];
        NSString *file = [self handlerDirectory:directory];
        file = [self filePath:file fileName:[self fileName:url]];
        [self deleteFile:file];
        
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@""];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"The url or directory is null."];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

#pragma mark 取消所有下载
-(void)sbCancelAll:(CDVInvokedUrlCommand*)command{
    [self pauseAll];
    
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@""];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

#pragma mark 清除全部缓存
-(void)sbClearCache:(CDVInvokedUrlCommand*)command{
    CDVPluginResult* pluginResult = nil;
    NSString* directory = [command.arguments objectAtIndex:0];
    
    if (![self isEmpty:directory]) {
        [self cancelAll];
        [self deleteFiles:[self handlerDirectory:directory]];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@""];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"The directory is null."];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

#pragma mark 获取缓存大小
-(void)sbCacheSize:(CDVInvokedUrlCommand*)command{
    CDVPluginResult* pluginResult = nil;
    NSString* directory = [command.arguments objectAtIndex:0];
    
    if (![self isEmpty:directory]) {
        NSString *cacheSize = [self getCacheFileSize:[self handlerDirectory:directory]];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:cacheSize];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"The directory is null."];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

#pragma mark 获取本地文件路径
-(void)sbCacheFilePath:(CDVInvokedUrlCommand*)command{
    CDVPluginResult* pluginResult = nil;
    
    NSString *url = [command.arguments objectAtIndex:0];
    NSString *directory = [command.arguments objectAtIndex:1];
    
    if(![self isEmpty:url] && ![self isEmpty:directory]){
        url = [self URLDecodedString:url];
        NSString *filePath = [self filePath:directory fileName:[self fileName:url]];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if([fileManager fileExistsAtPath:[self handlerDirectory:filePath]]){
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:filePath];
        }else{
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"The file is not exits."];
        }
    }else{
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"The url or directory is null."];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

#pragma mark 解码URL,存储的文件是中文名
-(NSString*)URLDecodedString:(NSString*)str{
    NSString *decodedString=(__bridge_transfer NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL, (__bridge CFStringRef)str, CFSTR(""), CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
    
    return decodedString;
}

#pragma mark 处理目录
-(NSString *)handlerDirectory:(NSString *)directory{
    if([directory hasPrefix:@"file://"]){
        directory = [directory substringFromIndex:8];
    }
    return directory;
}

#pragma mark 文件名
-(NSString *)fileName:(NSString *)url{
    NSString *file = url.lastPathComponent;
    return file;
    //NSInteger dotIndex = [file rangeOfString:@"."].location;

    //NSString *fileName = [file substringToIndex:dotIndex];
    //NSString *fileExtension = [fileName substringFromIndex:dotIndex];

    //return [NSString stringWithFormat:@"%@%@",[self md5:fileName],fileExtension];
}

#pragma mark 拼接文件路径
-(NSString *)filePath:(NSString *)directory fileName:(NSString *)fileName{
    NSString *path;
    if([directory hasSuffix:@"/"]){
        path = [NSString stringWithFormat:@"%@%@",directory,fileName];
    }else{
        path = [NSString stringWithFormat:@"%@/%@",directory,fileName];
    }
    return path;
}

#pragma mark 删除文件
-(void)deleteFile:(NSString *)path{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if([fileManager removeItemAtPath:path error:nil]){
        NSLog(@"The file is deleted.");
    }
}

#pragma 删除文件夹
-(void)deleteFiles:(NSString *)path{
    // 文件管理者
    NSFileManager *mgr = [NSFileManager defaultManager];
    // 是否为文件夹
    BOOL isDirectory = NO;
    // 路径是否存在
    BOOL exists = [mgr fileExistsAtPath:path isDirectory:&isDirectory];
    if (!exists) return;
    if (isDirectory) { // 文件夹
        // 获得文件夹的大小  == 获得文件夹中所有文件的总大小
        NSDirectoryEnumerator *enumerator = [mgr enumeratorAtPath:path];
        for (NSString *subpath in enumerator) {
            // 全路径
            NSString *fullSubpath = [path stringByAppendingPathComponent:subpath];
            [mgr removeItemAtPath:fullSubpath error:nil];
        }
    }
}

#pragma mark 获取缓存大小
-(NSString *)getCacheFileSize:(NSString *)directory{
    unsigned long long size = [self fileSize:directory];
    return [self formatFileSize:size];
}

#pragma 文件夹大小
- (unsigned long long)fileSize:(NSString *)path{
    // 总大小
    unsigned long long size = 0;
    // 文件管理者
    NSFileManager *mgr = [NSFileManager defaultManager];
    // 是否为文件夹
    BOOL isDirectory = NO;
    // 路径是否存在
    BOOL exists = [mgr fileExistsAtPath:path isDirectory:&isDirectory];
    if (!exists) return size;
    if (isDirectory) { // 文件夹
        // 获得文件夹的大小  == 获得文件夹中所有文件的总大小
        NSDirectoryEnumerator *enumerator = [mgr enumeratorAtPath:path];
        for (NSString *subpath in enumerator) {
            // 全路径
            NSString *fullSubpath = [path stringByAppendingPathComponent:subpath];
            // 累加文件大小
            size += [mgr attributesOfItemAtPath:fullSubpath error:nil].fileSize;
        }
    } else { // 文件
        size = [mgr attributesOfItemAtPath:path error:nil].fileSize;
    }
    
    return size;
}

-(NSString *)formatFileSize:(unsigned long long )size{
    if(size <= 0){
        return @"0 B";
    }
    
    NSString *unit = @"B";
    if(size < 1024){
        size = size;
        unit = @"B";
    }else if(size < 1048576){
        size = size / 1024;
        unit = @"KB";
    }else if(size < 1073741824){
        size = size / 1048576;
        unit = @"MB";
    }else {
        size = size /1073741824;
        unit = @"GB";
    }
    
    return [NSString stringWithFormat:@"%.2f%@",(float)size,unit];
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

#pragma mark 暂停所有下载(不删除文件)
-(void)pauseAll{
    for(TCBlobDownloader *downloader in [self getDownloaderDict].allValues){
        if(downloader){
            [downloader cancelDownloadAndRemoveFile:NO];
        }
    }
    [[self getDownloaderDict] removeAllObjects];
}

#pragma mark 暂停下载(不删除文件)
-(void)pause:(NSString *)url{
    TCBlobDownloader *downloader = [self getDownloader:url];
    if(downloader){
        [downloader cancelDownloadAndRemoveFile:NO];
    }
    [[self getDownloaderDict] removeObjectForKey:[self md5:url]];
}

#pragma mark 取消所有下载(删除文件)
-(void)cancelAll{
    for(TCBlobDownloader *downloader in [self getDownloaderDict].allValues){
        if(downloader){
            [downloader cancelDownloadAndRemoveFile:YES];
        }
    }
    [[self getDownloaderDict] removeAllObjects];
    [self clearDownloadProgress];
}

#pragma mark 取消下载(删除文件)
-(void)cancel:(NSString *)url{
    TCBlobDownloader *downloader = [self getDownloader:url];
    if(downloader){
        [downloader cancelDownloadAndRemoveFile:YES];
    }
    
    NSString *key = [self md5:url];
    [[self getDownloaderDict] removeObjectForKey:key];
    [self deleteDownloadProgress:key];
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
-(void)saveDownloadProgress:(NSString *)key progress:(float)progress{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setFloat:progress forKey:key];
}

-(float)getDownloadProgress:(NSString *)key{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults floatForKey:key];
}

-(void)deleteDownloadProgress:(NSString *)key{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:key];
    [defaults synchronize];
}

-(void)clearDownloadProgress{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSDictionary *dic = [defaults dictionaryRepresentation];
    for(id key in dic){
        [defaults removeObjectForKey:key];
    }
    [defaults synchronize];
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
    NSString *url = blobDownload.downloadURL.absoluteString;
    
    NSLog(@"url:%@",url);
    NSString *key = [self md5:url];
    [self pause:blobDownload.downloadURL.absoluteString];
    [self saveDownloadProgress:key progress:1.f];
}

- (void)download:(TCBlobDownloader *)blobDownload
  didReceiveData:(uint64_t)receivedLength
         onTotal:(uint64_t)totalLength
        progress:(float)progress{
    //下载进度回调
    //NSLog(@"url:%@,progress:%.2f",blobDownload.downloadURL.absoluteURL,progress);
    NSString *url = blobDownload.downloadURL.absoluteString;
    NSString *key = [self md5:url];
    [self saveDownloadProgress:key progress:progress];
}

- (void)download:(TCBlobDownloader *)blobDownload didReceiveFirstResponse:(NSURLResponse *)response{
    //首次收到数据
    //NSLog(@"url:%@,response:%@",blobDownload.downloadURL.absoluteURL,response);
}

- (void)download:(TCBlobDownloader *)blobDownload didStopWithError:(NSError *)error{
    //失败
    [self pause:blobDownload.downloadURL.absoluteString];
    NSLog(@"url:%@,error:%@",blobDownload.downloadURL.absoluteURL,error);
}

@end

