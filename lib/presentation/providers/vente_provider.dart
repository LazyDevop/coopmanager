import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/vente_viewmodel.dart';

class VenteProvider extends ChangeNotifierProvider<VenteViewModel> {
  VenteProvider({
    super.key,
    required super.child,
    VenteViewModel Function(BuildContext)? create,
  }) : super(create: create ?? ((_) => VenteViewModel()));
}
r