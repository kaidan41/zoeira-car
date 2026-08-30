import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:zoeira_car/controllers/auth_controller.dart';
import 'package:zoeira_car/routes/app_routes.dart';
import 'package:zoeira_car/theme/app_colors.dart';
import 'package:zoeira_car/views/auth/widgets/auth_text_field.dart';
import 'package:zoeira_car/views/auth/widgets/auth_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthController>();
    final success = await auth.registerWithEmail(
      email: _emailController.text,
      password: _passwordController.text,
      displayName: _nameController.text,
    );

    if (success && mounted) {
      // Novato vai direto pra página de busca da nave
      context.go(AppRoutes.search);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Consumer<AuthController>(
            builder: (context, auth, _) {
              return Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ──
                    Text(
                      'Criar conta',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Entra na garagem e começa a consultar as naves!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),

                    const SizedBox(height: 32),

                    // ── Erro ──
                    if (auth.errorMessage != null) ...[
                      _ErrorBanner(message: auth.errorMessage!),
                      const SizedBox(height: 16),
                    ],

                    // ── Nome ──
                    AuthTextField(
                      controller: _nameController,
                      label: 'Seu nome',
                      hint: 'Ex: João das Naves',
                      prefixIcon: Icons.person_outline_rounded,
                      textCapitalization: TextCapitalization.words,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Coloca seu nome aí';
                        }
                        if (v.trim().length < 2) {
                          return 'Nome muito curto';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // ── E-mail ──
                    AuthTextField(
                      controller: _emailController,
                      label: 'E-mail',
                      hint: 'seu@email.com',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Coloca o e-mail';
                        }
                        if (!v.contains('@') || !v.contains('.')) {
                          return 'E-mail inválido';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // ── Senha ──
                    AuthTextField(
                      controller: _passwordController,
                      label: 'Senha',
                      hint: 'Mínimo 6 caracteres',
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
                        if (v == null || v.isEmpty) {
                          return 'Coloca a senha';
                        }
                        if (v.length < 6) {
                          return 'Mínimo 6 caracteres';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // ── Confirmar senha ──
                    AuthTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirmar senha',
                      hint: 'Repete a senha',
                      obscureText: _obscureConfirm,
                      prefixIcon: Icons.lock_outline_rounded,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Confirma a senha';
                        }
                        if (v != _passwordController.text) {
                          return 'As senhas não batem, irmão!';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _submit(),
                    ),

                    const SizedBox(height: 28),

                    // ── Botão criar conta ──
                    AuthButton(
                      label: 'Criar conta grátis 🚀',
                      isLoading: auth.isLoading,
                      onPressed: _submit,
                    ),

                    const SizedBox(height: 24),

                    // ── Já tem conta ──
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Já tem conta?',
                            style:
                                TextStyle(color: AppColors.textSecondary),
                          ),
                          TextButton(
                            onPressed: () => context.pop(),
                            child: Text(
                              'Entrar',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Termos ──
                    Center(
                      child: Text(
                        'Ao criar conta, você aceita nossos Termos de Uso\ne Política de Privacidade.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary.withOpacity(0.6),
                              height: 1.4,
                            ),
                        textAlign: TextAlign.center,
                      ),
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
