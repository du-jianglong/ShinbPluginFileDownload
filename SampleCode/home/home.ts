import {Component} from '@angular/core';
import {NavController} from 'ionic-angular';
import {File} from "@ionic-native/file";

declare let cordova: any;

@Component({
  selector: 'page-home',
  templateUrl: 'home.html',
  providers: [File]
})


/**
 * 1.安装file-transfer-plugin
 *  ionic cordova plugin add cordova-plugin-file
 *  npm install --save @ionic-native/file
 *
 * 2.
 *
 */
export class HomePage {

  isStartingDownload: boolean = false;

  downloadFiles: any;

  //计时器相关
  timeHandler: any;

  constructor(public navCtrl: NavController, public file: File) {

    this.downloadFiles = [{
      downloadUrl: "https://portal.zhucheng360.com/xxxxx.mp4",
      downloadProgress: 0,
      isDownloadComplete: false,
      isStartDownload: false,
      downloadPath: ""
    }, {
      downloadUrl: "http://pic.ibaotu.com/00/35/06/xxxxx2.mp4",
      downloadProgress: 0,
      isDownloadComplete: false,
      isStartDownload: false,
      downloadPath: ""
    }, {
      downloadUrl: "http://61.134.39.90:8066/allimages/generic/web/xxxsx3.pdf",
      downloadProgress: 0,
      isDownloadComplete: false,
      isStartDownload: false,
      downloadPath: ""
    }];
  }

  toSecondPage() {
    this.navCtrl.push("SecondPage");
  }

  /**
   * 开始/暂停下载
   */
  allDownloadClick() {
    if (!this.isStartingDownload) {
      //全部下载
      console.log("全部下载");
      let count = this.downloadFiles.length;
      for (let i = 0; i < count; i++) {
        let download = this.downloadFiles[i];
        this.download(download);
      }
    } else {
      //全部暂停
      console.log("全部暂停");
      cordova.plugins.ShinbPluginFileDownload.sbCancelAll("", (result) => {
        console.log(result);
      }, (error) => {
        console.log(error);
      });
    }

    this.isStartingDownload = !this.isStartingDownload;
  }


  /**
   * 下载按钮文件
   * @param fileUrl
   */
  downloadClick(downloadFile) {
    console.log(downloadFile);
    if (downloadFile.isDownloadComplete) {
      //已下载
      alert(this.getFileName(downloadFile) + " 已下载完成，请处理打开流程。");
      return;
    }

    if (downloadFile.isStartingDownload) {
      //取消下载
      console.log("取消下载");
      cordova.plugins.ShinbPluginFileDownload.sbCancel(encodeURI(downloadFile.downloadUrl), (result) => {
        console.log(result);
      }, (error) => {
        console.log(error);
      });
    } else {
      //开始下载
      console.log("开始下载");
      this.download(downloadFile);
    }
  }

  /**
   * 下载文件
   * @param downloadFile
   */
  download(downloadFile) {
    if (downloadFile.isDownloadComplete) {
      return;
    }

    cordova.plugins.ShinbPluginFileDownload.sbDownload(encodeURI(downloadFile.downloadUrl), this.file.dataDirectory, (result) => {
      console.log(result);
    }, (error) => {
      console.log(error);
    });
  }


  /**
   * 获取文件名
   * @param downloadFile
   * @returns {any}
   */
  getFileName(downloadFile) {
    if (null == downloadFile.downloadUrl) {
      return "";
    }

    return downloadFile.downloadUrl.substr(downloadFile.downloadUrl.lastIndexOf("/") + 1);
  }


  /**
   * 获取文件保存地址
   * @param fileUrl
   * @returns {string}
   */
  checkFilePath(downloadFile) {
    if (null == downloadFile.downloadUrl) {
      return "";
    }

    let fileName = downloadFile.downloadUrl.substr(downloadFile.downloadUrl.lastIndexOf("/") + 1);
    return this.file.dataDirectory + fileName;
  }

  /**
   * 通过定时器来不断刷新进度
   */
  startTimer() {
    if (this.timeHandler) {
      return;
    }
    this.timeHandler = setInterval(() => {
      this.countDown();
    }, 500);
  }

  /**
   * 停止定时器
   */
  stopTimer() {
    if (this.timeHandler) {
      clearInterval(this.timeHandler);
    }
    this.timeHandler = null;
  }

  countDown() {
    console.log("countDown");
    let count = this.downloadFiles.length;
    for (let i = 0; i < count; i++) {
      let download = this.downloadFiles[i];
      cordova.plugins.ShinbPluginFileDownload.sbDownloadInfo(encodeURI(download.downloadUrl), (result) => {
        download.isDownloadComplete = result.isComplete;
        download.isStartingDownload = result.isDownloading;
        download.downloadProgress = result.progress;
        if (result.isComplete) {
          download.downloadPath = this.checkFilePath(download);
        }
      }, (error) => {
        console.log(error);
      });
    }
  }

  /**
   * 当进入页面时触发
   */
  ionViewDidEnter() {
    console.log("ionViewDidEnter");
    this.startTimer();
  }

  /**
   * 当将要从页面离开时触发
   */
  ionViewDidLeave() {
    console.log("ionViewDidLeave");
    this.stopTimer();
  }
}
