import 'dart:ui' show SystemMouseCursors;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../data/models/adherent_expert/champ_parcelle_model.dart';
import '../../../services/adherent/champ_parcelle_service.dart';
import '../../../services/adherent/adherent_service.dart';
import '../../../data/models/adherent_model.dart';

class ChampsMapScreen extends StatefulWidget {
  final int? adherentId; // Optionnel : filtrer par adhérent

  const ChampsMapScreen({super.key, this.adherentId});

  @override
  State<ChampsMapScreen> createState() => _ChampsMapScreenState();
}

class _ChampsMapScreenState extends State<ChampsMapScreen> {
  final ChampParcelleService _champService = ChampParcelleService();
  final AdherentService _adherentService = AdherentService();
  
  List<ChampParcelleModel> _champs = [];
  Map<int, AdherentModel> _adherentsMap = {};
  bool _isLoading = true;
  String? _errorMessage;
  
  final MapController _mapController = MapController();
  LatLng _center = LatLng(4.0, 11.0); // Centre par défaut (Cameroun approximatif)
  double _zoom = 10.0;

  @override
  void initState() {
    super.initState();
    _loadChamps();
  }

  Future<void> _loadChamps() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      List<ChampParcelleModel> champs;
      
      if (widget.adherentId != null) {
        champs = await _champService.getChampsByAdherent(widget.adherentId!);
        print('🔍 Champs récupérés pour adhérent ${widget.adherentId}: ${champs.length}');
        // Debug: afficher les coordonnées de chaque champ
        for (final champ in champs) {
          print('  - Champ ${champ.codeChamp}: lat=${champ.latitude}, lng=${champ.longitude}');
        }
        // Filtrer pour ne garder que ceux avec coordonnées GPS valides
        champs = champs.where((c) => 
          c.latitude != null && 
          c.longitude != null &&
          c.latitude != 0.0 &&
          c.longitude != 0.0 &&
          c.latitude! >= -90 && c.latitude! <= 90 &&
          c.longitude! >= -180 && c.longitude! <= 180
        ).toList();
        print('✅ Champs avec coordonnées GPS valides: ${champs.length}');
      } else {
        champs = await _champService.getAllChampsWithCoordinates();
        print('🔍 Tous les champs avec coordonnées GPS: ${champs.length}');
      }

      // Charger les informations des adhérents
      final adherentIds = champs.map((c) => c.adherentId).toSet();
      for (final id in adherentIds) {
        try {
          final adherent = await _adherentService.getAdherentById(id);
          if (adherent != null) {
            _adherentsMap[id] = adherent;
          }
        } catch (e) {
          print('Erreur lors du chargement de l\'adhérent $id: $e');
        }
      }

      // Calculer le centre de la carte basé sur les coordonnées des champs
      if (champs.isNotEmpty) {
        double totalLat = 0;
        double totalLng = 0;
        int count = 0;
        
        for (final champ in champs) {
          if (champ.latitude != null && 
              champ.longitude != null &&
              champ.latitude != 0.0 &&
              champ.longitude != 0.0) {
            totalLat += champ.latitude!;
            totalLng += champ.longitude!;
            count++;
          }
        }
        
        if (count > 0) {
          _center = LatLng(totalLat / count, totalLng / count);
        }
      }

      setState(() {
        _champs = champs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des champs: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.adherentId != null 
            ? 'Carte des champs' 
            : 'Carte des champs'),
        backgroundColor: Colors.brown.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadChamps,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadChamps,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _champs.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.map_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              widget.adherentId != null
                                  ? 'Aucun champ avec coordonnées GPS trouvé pour cet adhérent'
                                  : 'Aucun champ avec coordonnées GPS trouvé',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Pour afficher un champ sur la carte, ajoutez ses coordonnées GPS\n(latitude et longitude) lors de la création ou modification du champ.',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _loadChamps,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Actualiser'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.brown.shade700,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _center,
                            initialZoom: _zoom,
                            minZoom: 5.0,
                            maxZoom: 18.0,
                            onTap: (tapPosition, point) {
                              // Optionnel : gérer les clics sur la carte
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.coopmanager.app',
                              maxZoom: 19,
                            ),
                            MarkerLayer(
                              markers: _champs.map((champ) {
                                if (champ.latitude == null || 
                                    champ.longitude == null ||
                                    champ.latitude == 0.0 ||
                                    champ.longitude == 0.0) {
                                  return null;
                                }
                                
                                final adherent = _adherentsMap[champ.adherentId];
                                final adherentName = adherent != null
                                    ? '${adherent.prenom} ${adherent.nom}'
                                    : 'Adhérent ${champ.adherentId}';
                                
                                // Construire le texte de l'infobulle
                                final tooltipText = _buildTooltipText(champ, adherentName);
                                
                                return Marker(
                                  point: LatLng(champ.latitude!, champ.longitude!),
                                  width: 40,
                                  height: 40,
                                  child: Tooltip(
                                    message: tooltipText,
                                    preferBelow: false,
                                    waitDuration: const Duration(milliseconds: 500),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade900.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    textStyle: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    child: GestureDetector(
                                      onTap: () {
                                        _showChampInfo(champ, adherentName);
                                      },
                                      child: MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade700,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.3),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.agriculture,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).whereType<Marker>().toList(),
                            ),
                          ],
                        ),
                        // Légende
                        Positioned(
                          bottom: 16,
                          left: 16,
                          child: Card(
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade700,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.agriculture,
                                          color: Colors.white,
                                          size: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Champ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${_champs.length} champ${_champs.length > 1 ? 's' : ''}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }

  void _showChampInfo(ChampParcelleModel champ, String adherentName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(champ.nomChamp ?? champ.codeChamp),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('Code', champ.codeChamp),
              _buildInfoRow('Adhérent', adherentName),
              if (champ.localisation != null)
                _buildInfoRow('Localisation', champ.localisation!),
              _buildInfoRow('Superficie', '${champ.superficie} ha'),
              if (champ.varieteCacao != null)
                _buildInfoRow('Variété', champ.varieteCacao!),
              if (champ.nombreArbres != null)
                _buildInfoRow('Nombre d\'arbres', champ.nombreArbres.toString()),
              if (champ.rendementEstime > 0)
                _buildInfoRow('Rendement estimé', '${champ.rendementEstime} t/ha'),
              const SizedBox(height: 8),
              Text(
                'Coordonnées GPS',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${champ.latitude!.toStringAsFixed(6)}, ${champ.longitude!.toStringAsFixed(6)}',
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// Construire le texte de l'infobulle avec les informations principales du champ
  String _buildTooltipText(ChampParcelleModel champ, String adherentName) {
    final buffer = StringBuffer();
    
    buffer.writeln('${champ.nomChamp ?? champ.codeChamp}');
    buffer.writeln('Code: ${champ.codeChamp}');
    buffer.writeln('Adhérent: $adherentName');
    
    if (champ.localisation != null && champ.localisation!.isNotEmpty) {
      buffer.writeln('Localisation: ${champ.localisation}');
    }
    
    buffer.writeln('Superficie: ${champ.superficie.toStringAsFixed(2)} ha');
    
    if (champ.varieteCacao != null && champ.varieteCacao!.isNotEmpty) {
      buffer.writeln('Variété: ${champ.varieteCacao}');
    }
    
    if (champ.nombreArbres != null) {
      buffer.writeln('Arbres: ${champ.nombreArbres}');
    }
    
    if (champ.rendementEstime > 0) {
      buffer.writeln('Rendement: ${champ.rendementEstime.toStringAsFixed(2)} t/ha');
    }
    
    buffer.writeln('GPS: ${champ.latitude!.toStringAsFixed(6)}, ${champ.longitude!.toStringAsFixed(6)}');
    
    return buffer.toString().trim();
  }
}

