import "dart:core";
import "dart:io";
import "package:intl/intl.dart";
import "package:path_provider/path_provider.dart";
import "package:permission_handler/permission_handler.dart";

void _writeF(var fileName, var textToWrite) {
  final File file = File(fileName);
  file.writeAsString("${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())}: COURSE WALK COMPANION : $textToWrite\n", mode: FileMode.append);
  // file.writeAsString("${"${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())}: COURSE WALK COMPANION : {}\n", textToWrite, mode: FileMode.append);
  // file.readAsString().then((contents) {
  //   print(contents);
  // });
}

void writeFile(var fileName, var textToWrite) {
  Permission.location.request().then((PermissionStatus status) {
    if (status == PermissionStatus.granted) {
      if (Platform.isAndroid) {
        final Directory directory = Directory("/storage/emulated/0/Download");
        if (directory.existsSync()) {
          _writeF("${directory.path}/$fileName",textToWrite);
        } else {
          getExternalStorageDirectory().then((Directory? d) {
            _writeF("${d!.path}/$fileName",textToWrite);
          });
        }
      } else {
        getApplicationDocumentsDirectory().then((Directory d) {
          _writeF("${d.path}/$fileName",textToWrite);
        });
      }
    }
  });
}
