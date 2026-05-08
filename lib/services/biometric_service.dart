class BiometricService {
  Future<bool> isBiometricAvailable() async {
    final bool canCheck = await _auth.canCheckBiometrics; // Ada sensor?
    final bool isSupported = await _auth
        .isDeviceSupported(); // Device mendukung?
    return canCheck && isSupported;
  }
}
