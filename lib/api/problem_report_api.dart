import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'api_client.dart';
import 'api_paths.dart';

/// Sends a visitor's problem report ("Problem melden") to the backend, which
/// mails it to the OK. Mirrors backend `POST /api/v1/problem-report`: a
/// multipart request with `ProblemReportDTO` (name, description, optional
/// phone / latitude / longitude) as JSON part `report` and an optional image
/// part `photo`.
class ProblemReportApi {
  ProblemReportApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<void> send({
    required String name,
    required String description,
    String? phone,
    double? latitude,
    double? longitude,
    Uint8List? photo,
    String photoName = 'foto.jpg',
  }) => _client.postMultipart(
    ApiPaths.problemReport,
    json: {
      'report': {'name': name, 'description': description, 'phone': ?phone, 'latitude': ?latitude, 'longitude': ?longitude},
    },
    files: [
      if (photo != null)
        http.MultipartFile.fromBytes(
          'photo',
          photo,
          filename: photoName,
          contentType: MediaType('image', photoName.toLowerCase().endsWith('.png') ? 'png' : 'jpeg'),
        ),
    ],
  );
}
