import 'package:frontend/services/download_storage.dart';
import 'package:frontend/services/sqlite_download_storage.dart';

DownloadStorage createDownloadStorage() => SqliteDownloadStorage();