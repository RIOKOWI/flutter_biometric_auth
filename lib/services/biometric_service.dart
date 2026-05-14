import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'biometric_exception.dart';

/// Service layer untuk biometrik.
/// UI tidak pernah langsung memanggil LocalAuthentication — selalu lewat sini.
class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Cek apakah hardware biometrik tersedia dan perangkat mendukung.
  /// Dua kondisi HARUS terpenuhi: ada sensor + device mendukung.
  Future<bool> isBiometricAvailable() async {
    final bool canCheck = await _auth.canCheckBiometrics;
    final bool isSupported = await _auth.isDeviceSupported();
    return canCheck && isSupported;
  }

  /// Ambil daftar tipe biometrik yang tersedia di perangkat.
  /// Contoh return: [BiometricType.fingerprint, BiometricType.face]
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on LocalAuthException catch (e) {
      throw BiometricException.fromLocalAuthException(e);
    }
  }

  /// Tampilkan dialog biometrik OS dan tunggu hasil autentikasi.
  /// Throw [BiometricException] jika gagal atau dibatalkan.
  Future<bool> authenticate({
    String reason = 'Verifikasi identitas Anda untuk melanjutkan',
  }) async {
    // 1. Pre-check: apakah hardware tersedia?
    final bool available = await isBiometricAvailable();
    if (!available) {
      throw const BiometricException(
        code: BiometricErrorCode.noBiometricHardware,
        message: 'Device does not support biometrics.',
        userMessage: 'Perangkat tidak mendukung autentikasi biometrik.',
      );
    }

    // 2. Pre-check: apakah sudah ada biometrik terdaftar?
    final List<BiometricType> types = await getAvailableBiometrics();
    if (types.isEmpty) {
      throw const BiometricException(
        code: BiometricErrorCode.notEnrolled,
        message: 'No biometrics enrolled.',
        userMessage: 'Belum ada sidik jari tersimpan. Daftarkan di Pengaturan.',
      );
    }

    try {
      // 3. Tampilkan dialog biometrik OS
      final bool result = await _auth.authenticate(
        localizedReason: reason,
        authMessages: const [
          AndroidAuthMessages(
            signInTitle: 'Verifikasi Diperlukan',
            cancelButton: 'Batal',
            signInHint: 'Tempelkan jari atau arahkan wajah',
          ),
        ],
      );

      // 4. result=false tanpa exception = user tekan Batal
      if (!result) {
        throw const BiometricException(
          code: BiometricErrorCode.userCanceled,
          message: 'User canceled authentication.',
          userMessage: 'Autentikasi dibatalkan.',
        );
      }

      return true;
    } on LocalAuthException catch (e) {
      throw BiometricException.fromLocalAuthException(e);
    }
  }
}