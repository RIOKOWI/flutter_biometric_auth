import 'package:local_auth/local_auth.dart';

enum BiometricErrorCode {
  noBiometricHardware,
  notEnrolled,
  temporaryLockout,
  biometricLockout,
  userCanceled,
  systemCanceled,
  unknown,
}

class BiometricException implements Exception {
  final BiometricErrorCode code;
  final String message;
  final String userMessage;

  const BiometricException({
    required this.code,
    required this.message,
    required this.userMessage,
  });

  factory BiometricException.fromLocalAuthException(LocalAuthException e) {
    switch (e.code) {
      case LocalAuthExceptionCode.noBiometricHardware:
        return const BiometricException(
          code: BiometricErrorCode.noBiometricHardware,
          message: 'No biometric hardware found.',
          userMessage: 'Perangkat tidak memiliki sensor biometrik.',
        );

      case LocalAuthExceptionCode.noBiometricsEnrolled:
        return const BiometricException(
          code: BiometricErrorCode.notEnrolled,
          message: 'No biometrics enrolled.',
          userMessage: 'Belum ada sidik jari tersimpan. Daftarkan di Pengaturan.',
        );

      default:
        // Deteksi lockout dari e.code string karena tidak ada getter message
        final codeStr = e.code.toString().toLowerCase();
        if (codeStr.contains('lockout_permanent')) {
          return BiometricException(
            code: BiometricErrorCode.biometricLockout,
            message: 'Permanent lockout: ${e.code}',
            userMessage:
                'Terlalu banyak percobaan gagal. Buka kunci perangkat dengan PIN terlebih dahulu.',
          );
        }
        if (codeStr.contains('lockout')) {
          return BiometricException(
            code: BiometricErrorCode.temporaryLockout,
            message: 'Temporary lockout: ${e.code}',
            userMessage: 'Terlalu banyak percobaan gagal. Tunggu beberapa saat.',
          );
        }
        return BiometricException(
          code: BiometricErrorCode.unknown,
          message: 'Unknown error: ${e.code}',
          userMessage: 'Terjadi kesalahan. Silakan coba lagi.',
        );
    }
  }

  bool get isRetryable =>
      code == BiometricErrorCode.userCanceled ||
      code == BiometricErrorCode.systemCanceled ||
      code == BiometricErrorCode.unknown;

  bool get requiresSettings => code == BiometricErrorCode.notEnrolled;

  bool get requiresFallback =>
      code == BiometricErrorCode.noBiometricHardware ||
      code == BiometricErrorCode.biometricLockout;

  @override
  String toString() => 'BiometricException($code): $message';
}