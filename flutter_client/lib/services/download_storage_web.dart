import 'package:frontend/services/download_storage.dart';
import 'package:frontend/services/memory_download_storage.dart';

DownloadStorage createDownloadStorage() => MemoryDownloadStorage();