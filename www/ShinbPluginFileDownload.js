var exec = require('cordova/exec');

exports.coolMethod = function (arg0, success, error) {
    exec(success, error, 'ShinbPluginFileDownload', 'coolMethod', [arg0]);
};

exports.sbDownload = function (arg0, arg1, success, error) {
    exec(success, error, 'ShinbPluginFileDownload', 'sbDownload', [arg0, arg1]);
};

exports.sbDownloadInfo = function (arg0, success, error) {
    exec(success, error, 'ShinbPluginFileDownload', 'sbDownloadInfo', [arg0]);
};

exports.sbCancel = function (arg0, success, error) {
    exec(success, error, 'ShinbPluginFileDownload', 'sbCancel', [arg0]);
};

exports.sbCancelAll = function (arg0, success, error) {
    exec(success, error, 'ShinbPluginFileDownload', 'sbCancelAll', [arg0]);
};
