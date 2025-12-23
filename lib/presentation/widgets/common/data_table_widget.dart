import 'package:flutter/material.dart';
import '../../../config/theme/app_theme.dart';

/// Tableau de données amélioré avec filtres et tri
class DataTableWidget<T> extends StatefulWidget {
  final List<T> data;
  final List<DataColumn> columns;
  final List<DataRow> Function(T item, int index) buildRow;
  final String? searchHint;
  final String Function(T item)? searchFilter;
  final List<Widget>? actions;
  final bool isLoading;
  final String? emptyMessage;
  final bool sortable;

  const DataTableWidget({
    super.key,
    required this.data,
    required this.columns,
    required this.buildRow,
    this.searchHint,
    this.searchFilter,
    this.actions,
    this.isLoading = false,
    this.emptyMessage,
    this.sortable = true,
  });

  @override
  State<DataTableWidget<T>> createState() => _DataTableWidgetState<T>();
}

class _DataTableWidgetState<T> extends State<DataTableWidget<T>> {
  String _searchQuery = '';
  int? _sortColumnIndex;
  bool _sortAscending = true;

  List<T> get _filteredData {
    var filtered = widget.data;

    // Recherche
    if (_searchQuery.isNotEmpty && widget.searchFilter != null) {
      filtered = filtered.where((item) {
        final searchable = widget.searchFilter!(item).toLowerCase();
        return searchable.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Barre d'outils
          if (widget.searchHint != null || widget.actions != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  if (widget.searchHint != null) ...[
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: widget.searchHint,
                            prefixIcon: const Icon(Icons.search, size: 20),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 20),
                                    onPressed: () {
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (widget.actions != null) ...widget.actions!,
                ],
              ),
            ),
          // Tableau
          Expanded(
            child: widget.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredData.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 64,
                                color: AppTheme.textLight,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                widget.emptyMessage ?? 'Aucune donnée disponible',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: DataTable(
                            columns: widget.columns,
                            rows: _filteredData.asMap().entries.map((entry) {
                              return widget.buildRow(entry.value, entry.key);
                            }).toList(),
                            sortColumnIndex: widget.sortable ? _sortColumnIndex : null,
                            sortAscending: _sortAscending,
                            onSelectAll: (selected) {
                              // TODO: Implémenter la sélection multiple
                            },
                            headingRowColor: MaterialStateProperty.all(
                              Colors.grey.shade50,
                            ),
                            dataRowMinHeight: 48,
                            dataRowMaxHeight: 72,
                          ),
                        ),
                      ),
          ),
          // Pagination info
          if (_filteredData.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_filteredData.length} élément${_filteredData.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text('Effacer la recherche'),
                      style: TextButton.styleFrom(
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
