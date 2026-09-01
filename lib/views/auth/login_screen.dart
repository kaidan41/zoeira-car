import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:zoeira_car/controllers/auth_controller.dart';
import 'package:zoeira_car/routes/app_routes.dart';
import 'package:zoeira_car/theme/app_colors.dart';
import 'package:zoeira_car/views/auth/widgets/auth_text_field.dart';
import 'package:zoeira_car/views/auth/widgets/auth_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // Limpa mensagens de erro de telas anteriores
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AuthController>().clearError();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthController>();
    final success = await auth.signInWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bem-vindo de volta, ${auth.displayName ?? 'Piloto'}! 🚗'),
          backgroundColor: AppColors.verdictGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go(AppRoutes.home);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digita o e-mail primeiro pra resetar a senha!'),
          backgroundColor: AppColors.verdictYellow,
        ),
      );
      return;
    }

    final auth = context.read<AuthController>();
    final success = await auth.sendPasswordResetEmail(email);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'E-mail de recuperação enviado! Confere a caixa de entrada 📧'
              : auth.errorMessage ?? 'Erro ao enviar e-mail.',
        ),
        backgroundColor:
            success ? AppColors.verdictGreen : AppColors.verdictRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Consumer<AuthController>(
            builder: (context, auth, _) {
              return Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ── Logo / Header ──
                    _buildHeader(context),

                    const SizedBox(height: 40),

                    // ── Erro do Firebase ──
                    if (auth.errorMessage != null)
                      _ErrorBanner(message: auth.errorMessage!),

                    if (auth.errorMessage != null) const SizedBox(height: 16),

                    // ── Campo e-mail ──
                    AuthTextField(
                      controller: _emailController,
                      label: 'E-mail',
                      hint: 'seu@email.com',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Coloca o e-mail aí';
                        }
                        if (!v.contains('@')) return 'E-mail inválido';
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // ── Campo senha ──
                    AuthTextField(
                      controller: _passwordController,
                      label: 'Senha',
                      hint: '••••••••',
                      obscureText: _obscurePassword,
                      prefixIcon: Icons.lock_outline_rounded,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Coloca a senha';
                        if (v.length < 6) return 'Mínimo 6 caracteres';
                        return null;
                      },
                      onFieldSubmitted: (_) => _submit(),
                    ),

                    // ── Esqueceu a senha ──
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _forgotPassword,
                        child: Text(
                          'Esqueceu a senha?',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ── Botão entrar ──
                    AuthButton(
                      label: 'Entrar na Garagem 🚗',
                      isLoading: auth.isLoading,
                      onPressed: _submit,
                    ),

                    const SizedBox(height: 16),

                    // ── Continuar sem login ──
                    OutlinedButton(
                      onPressed: () => context.go(AppRoutes.home),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side:
                            const BorderSide(color: AppColors.cardBorder),
                        minimumSize:
                            const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Continuar sem login'),
                    ),

                    const SizedBox(height: 32),

                    // ── Cadastro ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Não tem conta?',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        TextButton(
                          onPressed: () => context.push(AppRoutes.register),
                          child: Text(
                            'Criar conta grátis',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        // Logo texto
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'ZOEIRA',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
            ),
            Text(
              ' CAR',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'O raio-x da sua nave!',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.verdictRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.verdictRed.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.verdictRed, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.verdictRed,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
