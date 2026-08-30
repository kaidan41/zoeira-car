import 'package:flutter/material.dart';
import 'package:zoeira_car/theme/app_colors.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController textController;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  const SearchBarWidget({
    super.key,
    required this.textController,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: textController,
      focusNode: focusNode,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        hintText: 'Procurar Nave... ex: Gol, Civic, Marea',
        hintStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 15,
        ),
        border: InputBorder.none,
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: textController,
          builder: (_, value, __) {
            if (value.text.isEmpty) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.close_rounded,
                  color: AppColors.textSecondary, size: 20),
              onPressed: onClear,
              tooltip: 'Limpar busca',
            );
          },
        ),
      ),
    );
  }
}
