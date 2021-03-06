
#import <Cordova/CDV.h>
#import "TCBlobDownloader.h"
#import "TCBlobDownloadManager.h"
#import <CommonCrypto/CommonDigest.h>

@interface ShinbPluginFileDownload : CDVPlugin<TCBlobDownloaderDelegate> {
  // Member variables go here.
}

@property (nonatomic,retain) NSMutableDictionary *downloaderDict;

- (void)coolMethod:(CDVInvokedUrlCommand *)command;

- (void)sbDownload:(CDVInvokedUrlCommand *)command;
- (void)sbDownloadInfo:(CDVInvokedUrlCommand *)command;

- (void)sbCancel:(CDVInvokedUrlCommand *)command;
- (void)sbCancelAndDel:(CDVInvokedUrlCommand*)command;
- (void)sbCancelAll:(CDVInvokedUrlCommand *)command;

- (void)sbClearCache:(CDVInvokedUrlCommand*)command;
- (void)sbCacheSize:(CDVInvokedUrlCommand*)command;
- (void)sbCacheFilePath:(CDVInvokedUrlCommand*)command;

@end
