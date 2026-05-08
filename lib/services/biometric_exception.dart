enum BiometricErrorCode {
  noBiometricHardware,  // Tidak ada sensor biometrik di perangkat
  notEnrolled,          // Sensor ada, tapi belum ada data sidik jari/wajah terdaftar
  temporaryLockout,     // Terkunci sementara (terlalu banyak percobaan gagal)
  biometricLockout,     // Terkunci permanen (butuh buka kunci perangkat dengan PIN dulu)
  userCanceled,         // User menekan tombol Batal
  systemCanceled,       // Sistem membatalkan (mis. ada telepon masuk)
  unknown,
}

class BiometricException implements Exception {
  final BiometricErrorCode code;    // kategori error
  final String message;             // pesan teknis (untuk debugging/log)
  final String userMessage;         // pesan untuk ditampilkan ke user

  // Constructor dari LocalAuthException (konversi error OS → custom model)
  factory BiometricException.fromLocalAuthException(LocalAuthException e) {
    switch (e.code) {
      case LocalAuthExceptionCode.noBiometricHardware:
        return BiometricException(
          code: BiometricErrorCode.noBiometricHardware,
          userMessage: 'Perangkat tidak memiliki sensor biometrik.',
          ...
        );
      case LocalAuthExceptionCode.noBiometricsEnrolled:
        return BiometricException(
          code: BiometricErrorCode.notEnrolled,
          userMessage: 'Belum ada sidik jari tersimpan. Daftarkan di Pengaturan.',
          ...
        );
      // ... kasus lainnya
    }
  }
// Tampilkan tombol "Coba Lagi"?
  bool get isRetryable => code == BiometricErrorCode.userCanceled ||
      code == BiometricErrorCode.systemCanceled ||
      code == BiometricErrorCode.unknown;

  // Tampilkan tombol "Buka Pengaturan"?
  bool get requiresSettings => code == BiometricErrorCode.notEnrolled;

  // Otomatis pindah ke form password?
  bool get requiresFallback => code == BiometricErrorCode.noBiometricHardware ||
      code == BiometricErrorCode.biometricLockout;
}
