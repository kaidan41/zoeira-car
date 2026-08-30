import 'package:flutter/material.dart';
import 'package:zoeira_car/models/subscription_model.dart';
import 'package:zoeira_car/theme/app_colors.dart';

/// Card de paywall zoeiro exibido para quem ainda não pode ver o raio-x completo.
/// Oferece 3 caminhos: consulta grátis do dia, consulta avulsa (R$ 5) e assinatura.
class PaywallCard extends StatelessWidget {
  final bool hasFreeConsultToday;
  final bool isFreeUnlocking;
  final bool isCreditUnlocking;
  final bool isConsultaPurchasing;
  final int credits;
  final VoidCallback? onUseFree;
  final VoidCallback? onUnlockSingle;
  final VoidCallback onSubscribe;

  const PaywallCard({
    super.key,
    required this.hasFreeConsultToday,
    required this.isFreeUnlocking,
    required this.isCreditUnlocking,
    required this.isConsultaPurchasing,
    required this.credits,
    required this.onUseFree,
    required this.onUnlockSingle,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Conteúdo bloqueado (blur fake) ──
            const _LockedPreview(),

            // ── CTAs ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                children: [
                  const Text('🦫', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),

                  Text(
                    'Puxe agora a Capivara\nda sua nave!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          height: 1.2,
                        ),
                  ),

                  const SizedBox(height: 20),

                  // ── 1) Consulta grátis de hoje ──
                  _FreeActionButton(
                    usedToday: hasFreeConsultToday,
                    loading: isFreeUnlocking,
                    onTap: onUseFree,
                  ),

                  const SizedBox(height: 10),

                  // ── 2) Consulta avulsa R$ 5 ──
                  _SingleActionButton(
                    credits: credits,
                    loading: isCreditUnlocking || isConsultaPurchasing,
                    onTap: onUnlockSingle,
                  ),

                  const SizedBox(height: 22),

                  // ── 3) Assinatura (destaque) ──
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onSubscribe,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Puxar a Capivara por ${SubscriptionPlan.price} — acesso a TUDO',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(
                              color: Colors.black,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ── Detalhe de créditos ──
                  if (credits > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        'Você tem $credits ${credits == 1 ? 'consulta avulsa' : 'consultas avulsas'} disponíveis',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                    ),

                  Text(
                    'Cancele quando quiser • Sem fidelidade',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white38,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Botão: consulta grátis diária
// ─────────────────────────────────────────────

class _FreeActionButton extends StatelessWidget {
  final bool usedToday;
  final bool loading;
  final VoidCallback? onTap;

  const _FreeActionButton({
    required this.usedToday,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: (usedToday || loading) ? null : onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(
            color: usedToday
                ? Colors.white24
                : AppColors.verdictGreen.withOpacity(0.6),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledForegroundColor: Colors.white38,
        ),
        icon: loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.verdictGreen,
                ),
              )
            : const Icon(Icons.card_giftcard_rounded,
                color: AppColors.verdictGreen, size: 18),
        label: Text(
          usedToday
              ? 'Consulta grátis já usada hoje'
              : 'Usar minha consulta grátis de hoje',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Botão: consulta avulsa R$ 5
// ─────────────────────────────────────────────

class _SingleActionButton extends StatelessWidget {
  final int credits;
  final bool loading;
  final VoidCallback? onTap;

  const _SingleActionButton({
    required this.credits,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = credits > 0
        ? 'Desbloquear este carro por 1 consulta'
        : 'Desbloquear este carro por ${ConsultationPlan.price}';

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: loading ? null : onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: AppColors.primary.withOpacity(0.6)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledForegroundColor: Colors.white38,
        ),
        icon: loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            : const Icon(Icons.key_rounded,
                color: AppColors.primary, size: 18),
        label: Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Preview bloqueado (conteúdo "fantasma")
// ─────────────────────────────────────────────

class _LockedPreview extends StatelessWidget {
  const _LockedPreview();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Conteúdo fake desfocado
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fakeLine(0.9),
              const SizedBox(height: 8),
              _fakeLine(0.7),
              const SizedBox(height: 8),
              _fakeLine(0.85),
              const SizedBox(height: 8),
              _fakeLine(0.6),
            ],
          ),
        ),

        // Overlay com lock
        Positioned.fill(
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_rounded, color: AppColors.primary, size: 36),
                    SizedBox(height: 6),
                    Text(
                      'Conteúdo exclusivo para quem desbloqueou',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _fakeLine(double widthFactor) {
    return LayoutBuilder(builder: (context, constraints) {
      return Container(
        width: constraints.maxWidth * widthFactor,
        height: 14,
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(6),
        ),
      );
    });
  }
}