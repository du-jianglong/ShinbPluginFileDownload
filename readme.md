ShinbPluginFileDownload是一个Cordova Native插件，主要功能是实现断点下载文件功能。

##原理：
> 1.启动下载后，将md5(url)作为key值实时保存单个文件的下载进度；

> 2.同时在显示下载进度的页面启动计时器，500ms一次查询，去查询当前文件的下载进度，同时查询当前文件是否在下载；

`注意：未做进度回调功能，需要实时主动去查询；断点下载需要服务器支持;使用插件请移除SampleCode`

##用法：
>1.将本插件拷贝到任意目录
>2.安装
  打开终端定位到项目的根目录，执行命令：
  ```
  cordova plugin add <插件路径>
  ```
>3.卸载
  打开终端定位到项目的根目录，执行命令:
  ```
  cordova plugin remove cn.shinb.plugins.filedownload
  ```
>4.使用插件
  ```
  //声明
  declare let cordova: any;
  //调用方法
  cordova.plugins.ShinbPluginFileDownload.sbDownload(url,fileDirectory, (result) => {
      console.log(result);
  }, (error) => {
      console.log(error);
  });
  ```

`
提示：
  1.查看当前项目安装的插件列表
  cordova plugin list
  2.修改插件时，需要先卸载再安装才能生效；`
