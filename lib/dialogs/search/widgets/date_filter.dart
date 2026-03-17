import 'package:flutter/material.dart';

enum DateFilterMode { betweenDates, period }

class DateFilterSection extends StatelessWidget {
  final DateFilterMode dateMode;
  final DateTime? dateMin;
  final DateTime? dateMax;

  final Function(DateFilterMode) onModeChanged;
  final Function(DateTime?) onDateMinChanged;
  final Function(DateTime?) onDateMaxChanged;

  const DateFilterSection({
    super.key,
    required this.dateMode,
    required this.dateMin,
    required this.dateMax,
    required this.onModeChanged,
    required this.onDateMinChanged,
    required this.onDateMaxChanged,
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
                Icon(Icons.date_range, size: 20, color: Color(0xFF28A745)),
                SizedBox(width: 5),
                Text(
                  "Quand ?",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Sélection du mode de période
            RadioGroup<DateFilterMode>(
              groupValue: dateMode,
              onChanged: (DateFilterMode? value) {
                if (value != null) onModeChanged(value);
              },
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => onModeChanged(DateFilterMode.betweenDates),
                      child: Row(
                        children: const [
                          Radio<DateFilterMode>(
                            value: DateFilterMode.betweenDates,
                          ),
                          SizedBox(width: 4),
                          Text("Entre dates"),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => onModeChanged(DateFilterMode.period),
                      child: Row(
                        children: const [
                          Radio<DateFilterMode>(value: DateFilterMode.period),
                          SizedBox(width: 4),
                          Text("Période"),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 5),

            // Champs date
            if (dateMode == DateFilterMode.betweenDates)
              Row(
                children: [
                  Expanded(
                    child: _buildDatePicker(
                      context,
                      dateMin,
                      "Date de début",
                      onDateMinChanged,
                      fullDate: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildDatePicker(
                      context,
                      dateMax,
                      "Date de fin",
                      onDateMaxChanged,
                      fullDate: true,
                    ),
                  ),
                ],
              ),

            if (dateMode == DateFilterMode.period)
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildDatePicker(
                          context,
                          dateMin,
                          "Du ...",
                          onDateMinChanged,
                          fullDate: false,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildDatePicker(
                          context,
                          dateMax,
                          "Au ...",
                          onDateMaxChanged,
                          fullDate: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Ex : du 01/03 au 30/03 chaque année",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),

            // Bouton "Effacer les dates"
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  onDateMinChanged(null);
                  onDateMaxChanged(null);
                },
                icon: const Icon(Icons.clear, color: Colors.red),
                label: const Text(
                  "Effacer les dates",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker(
    BuildContext context,
    DateTime? date,
    String label,
    Function(DateTime?) onSelected, {
    required bool fullDate,
  }) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );

        if (picked != null) {
          if (fullDate) {
            onSelected(picked);
          } else {
            onSelected(DateTime(2024, picked.month, picked.day));
          }
        }
      },
      child: AbsorbPointer(
        child: TextField(
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: const Icon(Icons.calendar_today),
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          controller: TextEditingController(
            text: date != null
                ? fullDate
                      ? "${date.day.toString().padLeft(2, '0')}/"
                            "${date.month.toString().padLeft(2, '0')}/"
                            "${date.year}"
                      : "${date.day.toString().padLeft(2, '0')}/"
                            "${date.month.toString().padLeft(2, '0')}"
                : "",
          ),
        ),
      ),
    );
  }
}
