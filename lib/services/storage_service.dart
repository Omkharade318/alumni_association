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
