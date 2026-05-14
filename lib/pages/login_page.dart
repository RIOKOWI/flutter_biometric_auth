import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../services/biometric_service.dart';
import '../services/biometric_exception.dart';


enum _AuthMethod { face, fingerprint, password }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final BiometricService _service = BiometricService();

  _AuthMethod? _activeMethod; 
  bool _isLoading = false;
  String? _errorMessage;
  BiometricErrorCode? _errorCode;
  List<_AuthMethod> _availableMethods = [];

  
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  
  Future<void> _init() async {
    final available = await _service.isBiometricAvailable();
    final List<_AuthMethod> methods = [];

    if (available) {
      final types = await _service.getAvailableBiometrics();

      
      
      final hasFace = types.contains(BiometricType.face) ||
          types.contains(BiometricType.weak);

      
      final hasFingerprint = types.contains(BiometricType.fingerprint) ||
          types.contains(BiometricType.strong);

      if (hasFace) methods.add(_AuthMethod.face);
      if (hasFingerprint) methods.add(_AuthMethod.fingerprint);
    }

    
    methods.add(_AuthMethod.password);

    setState(() => _availableMethods = methods);
  }

  
  Future<void> _selectMethod(_AuthMethod method) async {
    setState(() {
      _activeMethod = method;
      _isLoading = true;
      _errorMessage = null;
      _errorCode = null;
    });

    try {
      await _service.authenticate(
        reason: method == _AuthMethod.face
            ? 'Gunakan Face ID untuk login'
            : 'Gunakan sidik jari untuk login',
      );
      // Sukses → navigasi ke halaman home
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } on BiometricException catch (e) {
      _handleError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  
  void _handleError(BiometricException e) {
    setState(() {
      _errorMessage = e.userMessage;
      _errorCode = e.code;
      
      if (e.requiresFallback) _activeMethod = _AuthMethod.password;
    });
  }

  /// Login dengan password (dummy validation untuk demo).
  void _loginWithPassword() {
    if (_passwordController.text == '12345') {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      setState(() => _errorMessage = 'Password salah. Coba lagi.');
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Mode tampilan berdasarkan _activeMethod
    if (_activeMethod == null) return _buildSelectionScreen();
    if (_activeMethod == _AuthMethod.password) return _buildPasswordForm();
    return _buildBiometricScreen();
  }

  

  Widget _buildSelectionScreen() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Selamat Datang',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pilih metode login',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ..._availableMethods.map((method) => _buildMethodCard(method)),
        ],
      ),
    );
  }

  Widget _buildMethodCard(_AuthMethod method) {
    final data = _methodData(method);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(data['icon'] as IconData),
        title: Text(data['title'] as String),
        subtitle: Text(data['subtitle'] as String),
        onTap: () {
          if (method == _AuthMethod.password) {
            setState(() {
              _activeMethod = _AuthMethod.password;
              _errorMessage = null;
            });
          } else {
            _selectMethod(method);
          }
        },
      ),
    );
  }

  

  Widget _buildBiometricScreen() {
    final data = _methodData(_activeMethod!);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              const CircularProgressIndicator()
            else
              Icon(data['icon'] as IconData, size: 64),
            const SizedBox(height: 16),
            Text(
              _isLoading ? 'Menunggu verifikasi...' : (data['title'] as String),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(data['subtitle'] as String),
      
            
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ],
      
            const SizedBox(height: 24),
      
            
            if (_errorCode != null) ...[
              if (BiometricException(
                      code: _errorCode!,
                      message: '',
                      userMessage: '')
                  .isRetryable)
                ElevatedButton(
                  onPressed: () => _selectMethod(_activeMethod!),
                  child: const Text('Coba Lagi'),
                ),
              if (BiometricException(
                      code: _errorCode!,
                      message: '',
                      userMessage: '')
                  .requiresSettings)
                OutlinedButton(
                  onPressed: () {
                    // buka pengautran biometrik
                  },
                  child: const Text('Buka Pengaturan'),
                ),
            ],
      
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() {
                _activeMethod = null;
                _errorMessage = null;
                _errorCode = null;
              }),
              child: const Text('← Kembali'),
            ),
          ],
        ),
      ),
    );
  }

  

  Widget _buildPasswordForm() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Login dengan Password',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // Input password
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),

          // Error banner
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ],

          const SizedBox(height: 16),

          // Tombol login
          ElevatedButton(
            onPressed: _loginWithPassword,
            child: const Text('Login'),
          ),

          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() {
              _activeMethod = null;
              _errorMessage = null;
            }),
            child: const Text('← Kembali'),
          ),
        ],
      ),
    );
  }

  

  Map<String, dynamic> _methodData(_AuthMethod method) {
    switch (method) {
      case _AuthMethod.face:
        return {
          'icon': Icons.face,
          'title': 'Face ID',
          'subtitle': 'Arahkan wajah ke kamera',
        };
      case _AuthMethod.fingerprint:
        return {
          'icon': Icons.fingerprint,
          'title': 'Sidik Jari',
          'subtitle': 'Tempelkan jari ke sensor',
        };
      case _AuthMethod.password:
        return {
          'icon': Icons.key,
          'title': 'Password',
          'subtitle': 'Masukkan password akun',
        };
    }
  }
}