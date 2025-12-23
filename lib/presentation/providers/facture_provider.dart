import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/facture_viewmodel.dart';

class FactureProvider extends ChangeNotifierProvider<FactureViewModel> {
  FactureProvider({super.key, required super.child}) 
      : super(create: (_) => FactureViewModel());
}
