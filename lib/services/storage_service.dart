import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final _client = Supabase.instance.client;
  final String _bucketName = 'images';

  Future<String> uploadImage(
    String folder, 
    File file, {
    Function(double)? onProgress,
  }) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = '$folder/$fileName';

    final String supabaseUrl = 'https://pgfdqvtlpiiwvwvqzfgs.supabase.co';
    final String anonKey = 'sb_publishable_4DyMdv2Uev08ejpJ6josCA_AUvsRNm_';
    final Uri uploadUri = Uri.parse('$supabaseUrl/storage/v1/object/$_bucketName/$path');

    try {
      final request = _ProgressRequest(
        'POST',
        uploadUri,
        onProgress: (bytes, total) {
          if (onProgress != null && total > 0) {
            onProgress(bytes / total);
          }
        },
      );

      // Add Supabase auth and API key headers
      request.headers['Authorization'] = 'Bearer $anonKey';
      request.headers['apikey'] = anonKey;
      request.headers['Content-Type'] = 'image/jpeg';

      // Add the file
      final fileStream = http.ByteStream(file.openRead());
      final totalLength = await file.length();
      final multipartFile = http.MultipartFile(
        'file',
        fileStream,
        totalLength,
        filename: fileName,
      );
      
      request.files.add(multipartFile);

      final response = await request.send();
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Success! Get the public URL
        if (onProgress != null) onProgress(1.0);
        return _client.storage.from(_bucketName).getPublicUrl(path);
      } else {
        final errorBody = await response.stream.bytesToString();
        throw Exception('Supabase Upload Error (${response.statusCode}): $errorBody');
      }
    } catch (e) {
      print('SUPABASE_MANUAL_UPLOAD_ERROR: $e');
      rethrow;
    }
  }

  Future<String> uploadProfileImage(
    String userId, 
    File file, {
    Function(double)? onProgress,
  }) async {
    return uploadImage('profiles/$userId', file, onProgress: onProgress);
  }

  Future<String> uploadPostImage(
    String userId, 
    File file, {
    Function(double)? onProgress,
  }) async {
    return uploadImage('posts/$userId', file, onProgress: onProgress);
  }

  Future<void> deleteImage(String path) async {
    try {
      await _client.storage.from(_bucketName).remove([path]);
    } catch (e) {
      print('SUPABASE_DELETE_ERROR: $e');
    }
  }

  Future<void> deleteImageFromUrl(String url) async {
    if (url.isEmpty || !url.contains('supabase')) return;
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      
      // Supabase Storage URLs follow: .../storage/v1/object/[public|authenticated]/[bucket]/[path]
      // Or sometimes directly: .../storage/v1/object/[bucket]/[path]
      
      int bucketIndex = -1;
      if (pathSegments.contains('public')) {
        bucketIndex = pathSegments.indexOf('public') + 1;
      } else if (pathSegments.contains('authenticated')) {
        bucketIndex = pathSegments.indexOf('authenticated') + 1;
      } else {
        final objectIndex = pathSegments.indexOf('object');
        if (objectIndex != -1 && objectIndex < pathSegments.length - 1) {
          // If the next segment is not public/authenticated, it's the bucket
          bucketIndex = objectIndex + 1;
        }
      }

      if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
        // The segments after the bucket are the actual file path
        final path = pathSegments.sublist(bucketIndex + 1).join('/');
        // Also ensure the bucket name matches or we log it
        final extractedBucket = pathSegments[bucketIndex];
        
        await _client.storage.from(extractedBucket).remove([Uri.decodeFull(path)]);
      }
    } catch (e) {
      print('SUPABASE_URL_DELETE_ERROR: $e');
    }
  }
}

/// A custom MultipartRequest that tracks progress
class _ProgressRequest extends http.MultipartRequest {
  final Function(int bytes, int total) onProgress;

  _ProgressRequest(String method, Uri url, {required this.onProgress}) : super(method, url);

  @override
  http.ByteStream finalize() {
    final byteStream = super.finalize();
    final totalLength = contentLength;
    int bytesSent = 0;

    final transformer = StreamTransformer.fromHandlers(
      handleData: (List<int> data, EventSink<List<int>> sink) {
        bytesSent += data.length;
        onProgress(bytesSent, totalLength);
        sink.add(data);
      },
    );

    return http.ByteStream(byteStream.transform(transformer));
  }
}
