import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/adherent_viewmodel.dart';

class AdherentProvider extends ChangeNotifierProvider<AdherentViewModel> {
  AdherentProvider({super.key, required super.child}) 
      : super(create: (_) => AdherentViewModel());
}
