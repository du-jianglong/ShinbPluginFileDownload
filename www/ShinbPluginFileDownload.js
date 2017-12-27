var exec = require('cordova/exec');

exports.coolMethod = function (arg0, success, error) {
    exec(success, error, 'ShinbPluginFileDownload', 'coolMethod', [arg0]);
};

/**
 * 下载
 * @param arg0 保存目录
 * @param arg1 下载地址
 * @param success
 * @param error
 */
exports.sbDownload = function (arg0, arg1, success, error) {
    exec(success, error, 'ShinbPluginFileDownload', 'sbDownload', [arg0, arg1]);
};

/**
 * 下载信息
 * @param arg0 下载地址
 * @param success
 * @param error
 */
exports.sbDownloadInfo = function (arg0, success, error) {
    exec(success, error, 'ShinbPluginFileDownload', 'sbDownloadInfo', [arg0]);
};

/**
 * 暂停下载
 * @param arg0 暂停下载
 * @param success
 * @param error
 */
exports.sbCancel = function (arg0, success, error) {
    exec(success, error, 'ShinbPluginFileDownload', 'sbCancel', [arg0]);
};

/**
 * 取消下载
 * @param arg0 保存目录
 * @param arg1 下载地址
 * @param success
 * @param error
 */
exports.sbCancelAndDel = function (arg0, arg1, success, error) {
    exec(success, error, 'ShinbPluginFileDownload', 'sbCancelAndDel', [arg0, arg1]);
}

/**
 * 取消所有下载
 * @param arg0 保存目录
 * @param success
 * @param error
 */
exports.sbCancelAll = function (arg0, success, error) {
    exec(success, error, 'ShinbPluginFileDownload', 'sbCancelAll', [arg0]);
};

/**
 * 清除缓存
 * @param arg0 保存目录
 * @param success
 * @param error
 */
exports.sbClearCache = function (arg0, success, error) {
    exec(success, error, 'ShinbPluginFileDownload', 'sbClearCache', [arg0]);
}

/**
 * 缓存大小
 * @param arg0 保存目录
 * @param success
 * @param error
 */
exports.sbCacheSize = function (arg0, success, error) {
    exec(success, error, 'ShinbPluginFileDownload', 'sbCacheSize', [arg0]);
}

/**
 * 缓存文件地址
 * @param arg0 缓存目录
 * @param arg1 下载地址
 * @param success
 * @param error
 */
exports.sbCacheFilePath = function (arg0, arg1, success, error) {
    exec(success, error, 'ShinbPluginFileDownload', 'sbCacheFilePath', [arg0, arg1]);
}
