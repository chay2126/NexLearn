import 'package:flutter_test/flutter_test.dart';
import 'package:nexlearn_frontend/services/api_service.dart';

void main() {
  group('ApiService.resolveBaseUrl', () {
    test('uses the explicit base URL when provided', () {
      expect(
        ApiService.resolveBaseUrl(baseUrl: 'http://example.com/api/'),
        'http://example.com/api',
      );
    });

    test('uses the local backend for localhost', () {
      expect(
        ApiService.resolveBaseUrl(
          currentUri: Uri.parse('http://localhost:3000/#/'),
        ),
        'http://localhost:8000',
      );
    });

    test('uses the same LAN host for private IPv4 addresses', () {
      expect(
        ApiService.resolveBaseUrl(
          currentUri: Uri.parse('http://192.168.1.23:5500/#/'),
        ),
        'http://192.168.1.23:8000',
      );
    });

    test('uses the local backend for file-served builds', () {
      expect(
        ApiService.resolveBaseUrl(
          currentUri: Uri.parse(
            'file:///C:/dev/NexLearn/frontend/build/web/index.html',
          ),
        ),
        'http://127.0.0.1:8000',
      );
    });

    test('uses the current host on port 8000 for hosted frontends', () {
      expect(
        ApiService.resolveBaseUrl(
          currentUri: Uri.parse('https://nexlearn.example.com/#/'),
        ),
        'https://nexlearn.example.com:8000',
      );
    });
  });
}
