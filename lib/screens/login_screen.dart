import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hidovpn/flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      _usernameCtrl.text.trim(),
      _passwordCtrl.text,
    );
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              auth.error ?? AppLocalizations.of(context)!.loginError),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // FIX: Scaffold arka planı tam ekranı kaplar, sistem temasından bağımsız
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      // FIX: Klavye açıldığında içerik kaymasını önle
      resizeToAvoidBottomInset: true,
      body: Container(
        // FIX: Tüm cihazlarda tam ekran gradient - height: double.infinity
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0E1A),
              Color(0xFF0D1B3E),
              Color(0xFF0A0E1A),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                // FIX: Klavye açıldığında scroll yapılabilir
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                  // FIX: İçerik kısa olsa bile ekranı tam doldur
                  constraints:
                      BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 48),
                          _buildLogo(),
                          const SizedBox(height: 52),
                          _buildForm(),
                          const Spacer(),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.5),
                blurRadius: 40,
                spreadRadius: 8,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(
                    Icons.shield_rounded,
                    color: Colors.white,
                    size: 50,
                  ),
                );
              },
            ),
          ),
        )
            .animate()
            .fadeIn(duration: 600.ms)
            .scale(begin: const Offset(0.5, 0.5)),
        const SizedBox(height: 20),
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'Hido',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
              TextSpan(
                text: 'VPN',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(begin: 0.3),
        const SizedBox(height: 8),
        const Text(
          'Güvenli ve Hızlı İnternet',
          style: TextStyle(
            fontSize: 15,
            color: Color(0xFF9CA3AF),
          ),
        ).animate().fadeIn(delay: 350.ms, duration: 500.ms),
      ],
    );
  }

  /// FIX: Tema bağımsız, hardcoded renklerle form alanı.
  /// Samsung, Xiaomi, Huawei ve diğer tüm cihazlarda görünürlük garantili.
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputAction textInputAction = TextInputAction.next,
    void Function(String)? onFieldSubmitted,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A2235),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A3550), width: 1),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        textInputAction: textInputAction,
        onFieldSubmitted: onFieldSubmitted,
        validator: validator,
        // FIX: Yazı rengi her zaman beyaz - tema override'ından bağımsız
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
        cursorColor: AppColors.primary,
        // FIX: Tüm border'lar InputBorder.none ile sıfırlandı
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            prefixIcon,
            color: const Color(0xFF9CA3AF),
            size: 20,
          ),
          suffixIcon: suffixIcon,
          // FIX: filled: false + border: none → tema fillColor geçersiz kılınamaz
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AppColors.error, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AppColors.error, width: 2),
          ),
          errorStyle:
              const TextStyle(color: AppColors.error, fontSize: 12),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInputField(
            controller: _usernameCtrl,
            label: AppLocalizations.of(context)!.username,
            prefixIcon: Icons.person_outline_rounded,
            textInputAction: TextInputAction.next,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? AppLocalizations.of(context)!.username
                : null,
          )
              .animate()
              .fadeIn(delay: 450.ms, duration: 500.ms)
              .slideX(begin: -0.2),
          const SizedBox(height: 16),
          _buildInputField(
            controller: _passwordCtrl,
            label: AppLocalizations.of(context)!.password,
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: const Color(0xFF9CA3AF),
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _login(),
            validator: (v) => (v == null || v.isEmpty)
                ? AppLocalizations.of(context)!.password
                : null,
          )
              .animate()
              .fadeIn(delay: 550.ms, duration: 500.ms)
              .slideX(begin: 0.2),
          const SizedBox(height: 32),
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: auth.isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor:
                        AppColors.primary.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: auth.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          AppLocalizations.of(context)!.login,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              );
            },
          )
              .animate()
              .fadeIn(delay: 650.ms, duration: 500.ms)
              .slideY(begin: 0.3),
        ],
      ),
    );
  }
}
