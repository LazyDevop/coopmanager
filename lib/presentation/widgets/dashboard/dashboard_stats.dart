import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/adherent_viewmodel.dart';
import '../../viewmodels/stock_viewmodel.dart';
import '../../viewmodels/vente_viewmodel.dart';
import '../../viewmodels/recette_viewmodel.dart';
import '../../../config/theme/app_theme.dart';
import '../common/stat_card.dart';
import '../common/loading_indicator.dart';

/// Widget pour afficher les statistiques du tableau de bord
class DashboardStats extends StatelessWidget {
  const DashboardStats({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadStats(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator(message: 'Chargement des statistiques...');
        }

        return Consumer4<AdherentViewModel, StockViewModel, VenteViewModel, RecetteViewModel>(
          builder: (context, adherentVM, stockVM, venteVM, recetteVM, _) {
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                StatCard(
                  title: 'Adhérents',
                  value: '${adherentVM.adherents.length}',
                  icon: Icons.people,
                  color: AppTheme.adherentColor,
                  subtitle: '${adherentVM.adherents.where((a) => a.isActive).length} actifs',
                  onTap: () {
                    // TODO: Naviguer vers adhérents
                  },
                ),
                StatCard(
                  title: 'Stock Total',
                  value: '${_formatStock(stockVM.totalStock)} kg',
                  icon: Icons.inventory,
                  color: AppTheme.stockColor,
                  subtitle: '${stockVM.stocksActuels.length} adhérents',
                  onTap: () {
                    // TODO: Naviguer vers stock
                  },
                ),
                StatCard(
                  title: 'Ventes',
                  value: '${venteVM.ventes.length}',
                  icon: Icons.shopping_cart,
                  color: AppTheme.venteColor,
                  subtitle: '${_formatCurrency(_getTotalVentes(venteVM))} FCFA',
                  onTap: () {
                    // TODO: Naviguer vers ventes
                  },
                ),
                StatCard(
                  title: 'Recettes',
                  value: '${recetteVM.recettes.length}',
                  icon: Icons.attach_money,
                  color: AppTheme.recetteColor,
                  subtitle: '${_formatCurrency(_getTotalRecettes(recetteVM))} FCFA',
                  onTap: () {
                    // TODO: Naviguer vers recettes
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _loadStats(BuildContext context) async {
    final adherentVM = context.read<AdherentViewModel>();
    final stockVM = context.read<StockViewModel>();
    final venteVM = context.read<VenteViewModel>();
    final recetteVM = context.read<RecetteViewModel>();

    await Future.wait([
      adherentVM.loadAdherents(),
      stockVM.loadStocksActuels(),
      venteVM.loadVentes(),
      recetteVM.loadRecettes(),
    ]);
  }

  String _formatStock(double stock) {
    if (stock >= 1000) {
      return '${(stock / 1000).toStringAsFixed(1)}T';
    }
    return stock.toStringAsFixed(0);
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }

  double _getTotalVentes(VenteViewModel venteVM) {
    return venteVM.ventes
        .where((v) => v.isValide)
        .fold(0.0, (sum, v) => sum + v.montantTotal);
  }

  double _getTotalRecettes(RecetteViewModel recetteVM) {
    return recetteVM.recettes.fold(0.0, (sum, r) => sum + r.montantNet);
  }
}
