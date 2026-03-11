import 'dart:async';
import 'package:flutter/material.dart';
import '../../../services/api_service.dart';

class LocationFilterSection extends StatelessWidget {
  final ApiService apiService;

  final List<int> selectedAreaComIds;
  final List<String> selectedAreaComNames;

  final List<int> selectedAreaDepIds;
  final List<String> selectedAreaDepNames;

  const LocationFilterSection({
    super.key,
    required this.apiService,
    required this.selectedAreaComIds,
    required this.selectedAreaComNames,
    required this.selectedAreaDepIds,
    required this.selectedAreaDepNames,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.location_on, size: 20, color: Colors.green),
                SizedBox(width: 5),
                Text(
                  "Où ?",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // COMMUNE
            _AreaSearchField(
              title: "Commune",
              hint: "Rechercher une commune (min. 3 lettres)",
              apiCall: apiService.searchCommunes,
              selectedIds: selectedAreaComIds,
              selectedNames: selectedAreaComNames,
            ),

            const SizedBox(height: 15),

            // DÉPARTEMENT
            _AreaSearchField(
              title: "Département",
              hint: "Rechercher un département (min. 3 lettres)",
              apiCall: apiService.searchDepartements,
              selectedIds: selectedAreaDepIds,
              selectedNames: selectedAreaDepNames,
            ),
          ],
        ),
      ),
    );
  }
}

class _AreaSearchField extends StatefulWidget {
  final String title;
  final String hint;
  final Future<List<dynamic>> Function(String) apiCall;

  final List<int> selectedIds;
  final List<String> selectedNames;

  const _AreaSearchField({
    required this.title,
    required this.hint,
    required this.apiCall,
    required this.selectedIds,
    required this.selectedNames,
  });

  @override
  State<_AreaSearchField> createState() => _AreaSearchFieldState();
}

class _AreaSearchFieldState extends State<_AreaSearchField> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> suggestions = [];
  Timer? _debounce;

  void _onChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (value.length < 3) {
        setState(() => suggestions = []);
        return;
      }

      try {
        final results = await widget.apiCall(value);
        if (!mounted) return;
        setState(() => suggestions = results);
      } catch (_) {
        if (!mounted) return;
        setState(() => suggestions = []);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),

        TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: widget.hint,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: _onChanged,
        ),

        const SizedBox(height: 10),

        ...suggestions.map((area) {
          final name = area['area_name'] ?? "Inconnu";
          final id = area['id_area'];
          final code = area['area_code']?.toString() ?? "";

          return ListTile(
            dense: true,
            title: Text("$name - $code"),
            onTap: () {
              if (!widget.selectedIds.contains(id)) {
                setState(() {
                  widget.selectedIds.add(id);
                  widget.selectedNames.add(name);
                  suggestions = [];
                });
              }
              _controller.clear();
            },
          );
        }),

        Wrap(
          spacing: 6,
          children: widget.selectedNames.map((name) {
            final index = widget.selectedNames.indexOf(name);

            return Chip(
              label: Text(name),
              onDeleted: () {
                setState(() {
                  widget.selectedNames.removeAt(index);
                  widget.selectedIds.removeAt(index);
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
