import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/services/auth_service.dart';

@GenerateMocks([http.Client, FlutterSecureStorage])
import 'auth_service_test.mocks.dart';

void main() {
  late MockClient mockHttpClient;
  late MockFlutterSecureStorage mockSecureStorage;
  late AuthService authService;

  setUpAll(() {
    mockHttpClient = MockClient();
    mockSecureStorage = MockFlutterSecureStorage();
    authService = AuthService(
      httpClient: mockHttpClient,
      secureStorage: mockSecureStorage,
    );
  });

  tearDownAll(() {
    reset(mockHttpClient);
    reset(mockSecureStorage);
  });

  group('login', () {
    test('should save tokens on successful login', () async {
      when(mockHttpClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
            '{"accessToken":"atoken","refreshToken":"rtoken"}',
            200,
          ));

      await authService.login('user', 'pass');

      verify(mockSecureStorage.write(key: 'access_token', value: 'atoken')).called(1);
      verify(mockSecureStorage.write(key: 'refresh_token', value: 'rtoken')).called(1);
    });

    test('should throw exception on failed login', () async {
      when(mockHttpClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('Invalid', 401));

      expect(() => authService.login('user', 'wrong'), throwsException);
    });
  });

  group('refreshToken', () {
    test('should refresh and save new tokens', () async {
      when(mockSecureStorage.read(key: 'refresh_token'))
          .thenAnswer((_) async => 'old_refresh');
      when(mockHttpClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
            '{"accessToken":"new_atoken","refreshToken":"new_rtoken"}',
            200,
          ));

      final result = await authService.refreshToken();
      expect(result, true);
      verify(mockSecureStorage.write(key: 'access_token', value: 'new_atoken')).called(1);
      verify(mockSecureStorage.write(key: 'refresh_token', value: 'new_rtoken')).called(1);
    });
  });
}