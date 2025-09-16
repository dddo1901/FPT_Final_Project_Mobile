import 'package:flutter/material.dart';
import '../../styles/app_theme.dart';

class AuthScaffold extends StatelessWidget {
  final Widget child;
  final String? title;
  final bool showLogo;
  final VoidCallback? onBackPressed;

  const AuthScaffold({
    Key? key,
    required this.child,
    this.title,
    this.showLogo = true,
    this.onBackPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header với back button (nếu có)
              if (onBackPressed != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: onBackPressed,
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),

              // Logo section
              if (showLogo)
                Expanded(
                  flex: 2, // Tăng từ 1 lên 2 để có thể tăng kích thước logo
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo container với shadow (lớn hơn)
                        Container(
                          width: 100, // Tăng từ 80 lên 100
                          height: 100, // Tăng từ 80 lên 100
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              25,
                            ), // Tăng từ 20 lên 25
                            boxShadow: AppTheme.mediumShadow,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: Image.asset(
                              'assets/images/Logo.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    Icons.local_pizza,
                                    size: 50, // Tăng từ 40 lên 50
                                    color: AppTheme.primary,
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16), // Tăng từ 12 lên 16
                        // App name (lớn hơn)
                        const Text(
                          'Pizza Dolce',
                          style: TextStyle(
                            fontSize: 28, // Tăng từ 24 lên 28
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),

                        if (title != null) ...[
                          const SizedBox(height: 4), // Giữ nguyên 4
                          Text(
                            title!,
                            style: const TextStyle(
                              fontSize: 14, // Giữ nguyên 14
                              color: Colors.white70,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

              // Content section
              Expanded(
                flex:
                    3, // Giữ nguyên 3 nhưng giảm margin để tiết kiệm không gian
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 12), // Giảm từ 16 xuống 12
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24), // Giữ nguyên 24
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(
                      16.0,
                    ), // Giảm từ 20 xuống 16 để tiết kiệm không gian
                    child: child,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Auth input field component
class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final bool showPassword;
  final VoidCallback? onTogglePassword;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const AuthTextField({
    Key? key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.showPassword = false,
    this.onTogglePassword,
    this.keyboardType,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword && !showPassword,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppTheme.primary),
            suffixIcon: isPassword
                ? IconButton(
                    onPressed: onTogglePassword,
                    icon: Icon(
                      showPassword ? Icons.visibility : Icons.visibility_off,
                      color: AppTheme.textMedium,
                    ),
                  )
                : null,
            filled: true,
            fillColor: AppTheme.ultraLightBlue.withOpacity(0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.divider, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.danger, width: 1),
            ),
          ),
        ),
      ],
    );
  }
}

// Auth button component
class AuthButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSecondary;
  final double? height;

  const AuthButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height ?? 52, // Giảm từ 56 xuống 52, có thể custom
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSecondary ? Colors.white : AppTheme.primary,
          foregroundColor: isSecondary ? AppTheme.primary : Colors.white,
          elevation: isSecondary ? 0 : 4,
          side: isSecondary
              ? const BorderSide(color: AppTheme.primary, width: 2)
              : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14), // Giảm từ 16 xuống 14
          ),
          shadowColor: AppTheme.primary.withOpacity(0.3),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20, // Giảm từ 24 xuống 20
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
