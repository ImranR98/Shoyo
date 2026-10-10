import 'package:flutter/material.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart';
import 'package:path/path.dart' as p;
import 'package:shoyo/models/save_task.dart';

IconData fileIconFor(SaveTask task) {
  switch (task.mediaType) {
    case SharedMediaType.IMAGE:
      return Icons.image_outlined;
    case SharedMediaType.VIDEO:
      return Icons.movie_outlined;
    case SharedMediaType.FILE:
      return Icons.insert_drive_file_outlined;
    case SharedMediaType.TEXT:
    case SharedMediaType.URL:
    case SharedMediaType.WEB_SEARCH:
    case SharedMediaType.OTHER:
      break;
  }
  return switch (p.extension(task.name).toLowerCase()) {
    '.jpg' ||
    '.jpeg' ||
    '.png' ||
    '.gif' ||
    '.webp' ||
    '.heic' ||
    '.bmp' => Icons.image_outlined,
    '.mp4' ||
    '.mkv' ||
    '.mov' ||
    '.webm' ||
    '.avi' ||
    '.3gp' => Icons.movie_outlined,
    '.mp3' ||
    '.m4a' ||
    '.wav' ||
    '.ogg' ||
    '.flac' ||
    '.opus' => Icons.audiotrack_outlined,
    '.pdf' => Icons.picture_as_pdf_outlined,
    '.zip' || '.7z' || '.rar' || '.tar' || '.gz' => Icons.folder_zip_outlined,
    '.apk' => Icons.android_outlined,
    '.txt' || '.md' || '.log' => Icons.article_outlined,
    _ => Icons.insert_drive_file_outlined,
  };
}
