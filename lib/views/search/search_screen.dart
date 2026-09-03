import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:zoeira_car/controllers/search_controller.dart';
import 'package:zoeira_car/controllers/subscription_controller.dart';
import 'package:zoeira_car/routes/app_routes.dart';
import 'package:zoeira_car/theme/app_colors.dart';
import 'package:zoeira_car/utils/email_launcher.dart';
import 'package:zoeira_car/views/search/widgets/search_bar_widget.dart';
import 'package:zoeira_car/views/search/widgets/search_results_list.dart';
import 'package:zoeira_car/views/search/widgets/search_idle_state.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final VehicleSearchController _controller;
  late final TextEditingController _textController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = VehicleSearchController();
    _textController = TextEditingController();
    _focusNode = FocusNode();

    // Abre o teclado automaticamente ao entrar na tela
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded,
                color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
          title: SearchBarWidget(
            textController: _textController,
            focusNode: _focusNode,
            onChanged: _controller.onQueryChanged,
            onSubmitted: (_) => _controller.searchNow(),
            onClear: () {
              _textController.clear();
              _controller.clearSearch();
            },
          ),
          titleSpacing: 0,
        ),
        body: Consumer<VehicleSearchController>(
          builder: (context, ctrl, _) {
            // Estado idle — dicas e sugestões
            if (ctrl.isIdle) {
              return SearchIdleState(
                onSuggestionTap: (query) {
                  _textController.text = query;
                  _textController.selection = TextSelection.fromPosition(
                    TextPosition(offset: query.length),
                  );
                  _controller.onQueryChanged(query);
                  _focusNode.requestFocus();
                },
              );
            }

            // Carregando
            if (ctrl.isLoading) {
              return _buildLoadingState();
            }

            // Erro
            if (ctrl.hasError) {
              return _buildErrorState(ctrl.errorMessage);
            }

            // Sem resultados
            if (ctrl.isEmpty) {
              return _buildEmptyState(ctrl.query);
            }

            // Resultados com recomendação da Capivara completa
            return Column(
              children: [
                Consumer<SubscriptionController>(
                  builder: (context, sub, _) {
                    if (sub.isSubscriber) return const SizedBox.shrink();
                    return _CapivaraSuggestionBanner(
                      onTap: () => context.push(AppRoutes.subscription),
                    );
                  },
                ),
                Expanded(
                  child: SearchResultsList(
                    results: ctrl.results,
                    onVehicleTap: (id) => context.push('/veiculo/$id'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          height: 90,
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.shimmerBase,
                  borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(14)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 14, width: 160,
                        decoration: BoxDecoration(
                          color: AppColors.shimmerBase,
                          borderRadius: BorderRadius.circular(6),
                        )),
                    const SizedBox(height: 8),
                    Container(height: 12, width: 100,
                        decoration: BoxDecoration(
                          color: AppColors.shimmerBase,
                          borderRadius: BorderRadius.circular(6),
                        )),
                    const SizedBox(height: 6),
                    Container(height: 24, width: 120,
                        decoration: BoxDecoration(
                          color: AppColors.shimmerBase,
                          borderRadius: BorderRadius.circular(8),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String query) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          const Text('🔍', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            'Nave "$query" não encontrada',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Tenta outro modelo ou verifique a escrita. A gente ainda não catalogou todo mundo!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          // Botão de solicitar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text('✉️', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Quer que a gente catalogue essa nave?',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Manda o modelo pra gente e colocamos no raio-x!',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      launchRequestEmail(
                        subject: 'Solicitar inclusão de nave no Zoeira Car',
                        body:
                            'Olá, gostaria de solicitar a inclusão do seguinte veículo:\n\nMarca/Modelo buscado: $query\n\nObrigado!',
                      );
                    },
                    icon: const Icon(Icons.email_outlined, size: 18),
                    label: const Text('Solicitar inclusão'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('💥', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              'Deu BO na busca!',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              error ?? 'Erro desconhecido',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _controller.searchNow,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar de novo'),
            ),
          ],
        ),
      ),
    );
  }
}

// Banner que "recomenda puxar a Capivara" quando há resultados na busca.
class _CapivaraSuggestionBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _CapivaraSuggestionBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primaryDark, AppColors.primary],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            const Text('🎯', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Achou a nave? Puxe a Capivara dela!',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Saiba a Capivara completa de cada usada.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.black87,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.black),
          ],
        ),
      ),
    );
  }
}
