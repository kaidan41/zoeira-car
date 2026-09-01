import 'package:flutter/material.dart';
import 'package:zoeira_car/theme/app_colors.dart';

class AvatarOption {
  final String id;
  final String label;
  final String emoji;
  final Color backgroundColor;

  const AvatarOption({
    required this.id,
    required this.label,
    required this.emoji,
    required this.backgroundColor,
  });
}

const List<AvatarOption> kAutomotiveAvatars = [
  AvatarOption(
    id: 'avatar_capivara',
    label: 'Capivara Piloto 🦫',
    emoji: '🦫',
    backgroundColor: Color(0xFF8D6E63),
  ),
  AvatarOption(
    id: 'avatar_ferrari',
    label: 'Supercarro Vermelho',
    emoji: '🏎️',
    backgroundColor: Color(0xFFD32F2F),
  ),
  AvatarOption(
    id: 'avatar_capacete',
    label: 'Piloto Pro 🏁',
    emoji: '🏁',
    backgroundColor: Color(0xFF1E88E5),
  ),
  AvatarOption(
    id: 'avatar_fusca',
    label: 'Clássico Raiz',
    emoji: '🚗',
    backgroundColor: Color(0xFFF57C00),
  ),
  AvatarOption(
    id: 'avatar_roda',
    label: 'Roda & Pneu 🛞',
    emoji: '🛞',
    backgroundColor: Color(0xFF455A64),
  ),
  AvatarOption(
    id: 'avatar_mecanico',
    label: 'Mecânico Preparador',
    emoji: '🔧',
    backgroundColor: Color(0xFF7B1FA2),
  ),
  AvatarOption(
    id: 'avatar_picape',
    label: '4x4 na Lama 🚙',
    emoji: '🚙',
    backgroundColor: Color(0xFF388E3C),
  ),
  AvatarOption(
    id: 'avatar_coroa',
    label: 'Rei da Pista 👑',
    emoji: '👑',
    backgroundColor: Color(0xFFFFB300),
  ),
  AvatarOption(
    id: 'avatar_foguete',
    label: 'Corte de Giro 🚀',
    emoji: '🚀',
    backgroundColor: Color(0xFFE91E63),
  ),
  AvatarOption(
    id: 'avatar_eletrico',
    label: 'Raio Turbo ⚡',
    emoji: '⚡',
    backgroundColor: Color(0xFF00ACC1),
  ),
  AvatarOption(
    id: 'avatar_gasolina',
    label: 'Cheiro de Gasolina ⛽',
    emoji: '⛽',
    backgroundColor: Color(0xFFC2185B),
  ),
  AvatarOption(
    id: 'avatar_policia',
    label: 'Fuga do Radar 🚓',
    emoji: '🚓',
    backgroundColor: Color(0xFF303F9F),
  ),
];

class AvatarPickerModal extends StatelessWidget {
  final String? currentPhotoUrl;
  final ValueChanged<String> onSelected;

  const AvatarPickerModal({
    super.key,
    required this.currentPhotoUrl,
    required this.onSelected,
  });

  static Future<void> show({
    required BuildContext context,
    required String? currentPhotoUrl,
    required ValueChanged<String> onSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AvatarPickerModal(
        currentPhotoUrl: currentPhotoUrl,
        onSelected: onSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Barra superior
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Escolha seu Avatar Automotivo',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Personalize sua garagem com um ícone de respeito!',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 20),

            // Grid de avatares
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: kAutomotiveAvatars.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.0,
                ),
                itemBuilder: (context, index) {
                  final avatar = kAutomotiveAvatars[index];
                  final isSelected = currentPhotoUrl == avatar.emoji;

                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      onSelected(avatar.emoji);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: avatar.backgroundColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : avatar.backgroundColor.withOpacity(0.5),
                          width: isSelected ? 2.5 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            avatar.emoji,
                            style: const TextStyle(fontSize: 34),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            avatar.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
