import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tipitaka_pali/business_logic/models/freq.dart';
import 'package:tipitaka_pali/ui/screens/dictionary/controller/dictionary_controller.dart';
import 'package:tipitaka_pali/utils/platform_info.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tipitaka_pali/utils/super_scripter_uni.dart';
import '../../../../services/prefs.dart';

// **1. Define `expectedFrequencies` at the global level**
const List<Map<String, String>> expectedFrequencies = [
  {'section': 'Pārājika'},
  {'section': 'Pācittiya'},
  {'section': 'Mahāvagga'},
  {'section': 'Cūḷavagga'},
  {'section': 'Parivāra'},
  {'section': 'Dīgha Nikāya'},
  {'section': 'Majjhima Nikāya'},
  {'section': 'Saṃyutta Nikāya'},
  {'section': 'Aṅguttara Nikāya'},
  {'section': 'Khuddaka Nikāya 1'},
  {'section': 'Khuddaka Nikāya 2'},
  {'section': 'Khuddaka Nikāya 3'},
  {'section': 'Dhammasaṅgaṇī'},
  {'section': 'Vibhaṅga'},
  {'section': 'Dhātukathā'},
  {'section': 'Puggalapaññatti'},
  {'section': 'Kathāvatthu'},
  {'section': 'Yamaka'},
  {'section': 'Paṭṭhāna'},
  {'section': 'Visuddhimagga'},
  {'section': 'Leḍī Sayāḍo'},
  {'section': 'Buddhavandanā'},
  {'section': 'Vaṃsa'},
  {'section': 'Byākaraṇa'},
  {'section': 'Pucchavissajjanā'},
  {'section': 'Nīti'},
  {'section': 'Pakiṇṇaka'},
  {'section': 'Sihaḷa'},
];

void showFreqDialog(BuildContext context, int wordId) async {
  var dictionaryController = context.read<DictionaryController>();
  Freq? freq = await dictionaryController.getDpdFreq(wordId);

  // Prevent using context across async gaps
  if (!context.mounted) return;

  // Handle case where no frequency data is found
  if (freq == null) {
    // Optionally, you can add a dialog to handle cases where frequency data is not found
    return;
  }

  debugPrint('Frequency data: $freq');

  // Parse freq_data to extract the CST frequency and grade
  List<dynamic> cstFreq = freq.freqData['CstFreq'];
  List<dynamic> cstGrad = freq.freqData['CstGrad'];

  // Adjust the data arrays using your `addDataPoints` and `makeMatRows` functions
  List<dynamic> adjustedFreq = addDataPoints(cstFreq);
  List<dynamic> adjustedGrad = addDataPoints(cstGrad);

  // Convert adjusted data to matrix rows
  List<List<dynamic>> freqMatrix = makeMatRows(adjustedFreq);
  List<List<dynamic>> gradMatrix = makeMatRows(adjustedGrad);

  final isMobile = Mobile.isPhone(context);
  const insetPadding = 10.0;

  // Prepare the content widget with scrollbars
  final content = SizedBox(
    width:
        isMobile ? MediaQuery.of(context).size.width - 2 * insetPadding : 400,
    height: isMobile ? null : 400,
    child: _getFreqWidget(context, freqMatrix, gradMatrix),
  );
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text("CST Data For ${superscripterUni(freq.headword)}"),
      contentPadding: isMobile ? EdgeInsets.zero : null,
      insetPadding: isMobile ? const EdgeInsets.all(insetPadding) : null,
      content: content,
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.ok)),
      ],
    ),
  );
}

// **4. Your `addDataPoints` function**
List<dynamic> addDataPoints(List<dynamic> data) {
  List<dynamic> result = [];
  int dataCounter = 0;

  // First loop for Mūla (first 19 rows)
  for (int i = 1; i <= 19; i++) {
    result.add(dataCounter < data.length ? data[dataCounter++] : 'i');
  }
  // Insert 9 "i" placeholders for Mūla after the first 19 elements
  for (int i = 1; i <= 9; i++) {
    result.add('i');
  }

  // Second loop for Aṭṭhakathā (12 rows)
  for (int i = 1; i <= 12; i++) {
    result.add(dataCounter < data.length ? data[dataCounter++] : 'i');
  }
  // Add 3 "i" placeholders before 113
  for (int i = 1; i <= 3; i++) {
    result.add('i');
  }

  // Add 113
  result.add(dataCounter < data.length ? data[dataCounter++] : 'i');
  // Add 3 "i" placeholders after 113
  for (int i = 1; i <= 3; i++) {
    result.add('i');
  }

  // Add 28 and then 8 "i" placeholders after it
  result
      .add(dataCounter < data.length ? data[dataCounter++] : 'i'); // Adding 28
  for (int i = 1; i <= 8; i++) {
    result.add('i');
  }

  // Now start Ṭīkā section
  result.add('i');
  result.add('i'); // Add two "i" placeholders
  result.add(dataCounter < data.length ? data[dataCounter++] : 'i'); // Add 184
  result.add('i');
  result.add('i'); // Add two "i" placeholders

  result.add(dataCounter < data.length ? data[dataCounter++] : 'i'); // Add 66
  result.add(dataCounter < data.length ? data[dataCounter++] : 'i'); // Add 37
  result.add(dataCounter < data.length ? data[dataCounter++] : 'i'); // Add 20
  result.add(dataCounter < data.length ? data[dataCounter++] : 'i'); // Add 41

  result.add('i');
  result.add('i'); // Add two "i" placeholders
  result.add(dataCounter < data.length ? data[dataCounter++] : 'i'); // Add 35

  result.add('i');
  result.add('i');
  result.add('i'); // Add three "i"s

  result.add(dataCounter < data.length ? data[dataCounter++] : 'i'); // Add 160

  result.add('i');
  result.add('i');
  result.add('i'); // Add three "i"s

  // Add the rest of the data
  while (dataCounter < data.length) {
    result.add(data[dataCounter++]);
  }

  return result;
}

// **5. Your `makeMatRows` function**
List<List<dynamic>> makeMatRows(List<dynamic> adjustedData) {
  List<List<dynamic>> matrix = [];

  for (int i = 0; i < 28; i++) {
    matrix.add([
      adjustedData[i] == 'i' ? null : adjustedData[i], // M
      adjustedData[i + 28] == 'i' ? null : adjustedData[i + 28], // A
      adjustedData[i + 56] == 'i' ? null : adjustedData[i + 56], // Ṭ
    ]);
  }

  return matrix;
}

// **6. Function to build the frequency widget**
Scrollbar _getFreqWidget(BuildContext context, List<List<dynamic>> freqMatrix,
    List<List<dynamic>> gradMatrix) {
  final horizontal = ScrollController();
  final vertical = ScrollController();

  return Scrollbar(
    controller: vertical,
    thumbVisibility: true,
    trackVisibility: true,
    child: Scrollbar(
      controller: horizontal,
      thumbVisibility: true,
      trackVisibility: true,
      notificationPredicate: (notification) => notification.depth == 1,
      child: SingleChildScrollView(
        controller: vertical,
        child: SingleChildScrollView(
          controller: horizontal,
          scrollDirection: Axis.horizontal,
          child: _getFreqTable(context, freqMatrix, gradMatrix),
        ),
      ),
    ),
  );
}

// **7. Function to build the frequency table**
Table _getFreqTable(BuildContext context, List<List<dynamic>> freqMatrix,
    List<List<dynamic>> gradMatrix) {
  List<TableRow> rows = [];

  // Add the header row
  rows.add(
    const TableRow(
      children: [
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Text("Section", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Text("M", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Text("A", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Text("Ṭ", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );

  for (int i = 0; i < freqMatrix.length; i++) {
    var freqRow = freqMatrix[i];
    var gradRow = gradMatrix[i];

    String section = expectedFrequencies[i]['section']!;

    // Build the table row
    rows.add(
      TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(section,
                style: TextStyle(
                    fontSize: Prefs.dictionaryFontSize.toDouble(),
                    fontWeight: FontWeight.bold)),
          ),
          _buildFrequencyCell(context, freqRow[0], gradRow[0]),
          _buildFrequencyCell(context, freqRow[1], gradRow[1]),
          _buildFrequencyCell(context, freqRow[2], gradRow[2]),
        ],
      ),
    );
  }

  return Table(
    border: TableBorder.all(),
    defaultColumnWidth: const IntrinsicColumnWidth(),
    children: rows,
  );
}

// **8. Helper function to build frequency cell with grade color**
Widget _buildFrequencyCell(
    BuildContext context, dynamic frequency, dynamic grade) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Container(
      color: _getGradeColor(context, grade),
      child: Text(
        frequency != null ? frequency.toString() : '-',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
      ),
    ),
  );
}

// **9. Helper function to map grade to color**
Color _getGradeColor(BuildContext context, dynamic grade) {
  bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

  if (grade == null || grade == 0) {
    return isDarkMode ? Colors.grey[850]! : Colors.white;
  }

  if (isDarkMode) {
    // Define colors suitable for dark mode
    switch (grade) {
      case 1:
        return Colors.blueGrey[800]!;
      case 2:
        return Colors.blueGrey[700]!;
      case 3:
        return Colors.blueGrey[600]!;
      case 4:
        return Colors.blueGrey[500]!;
      case 5:
        return Colors.blueGrey[400]!;
      case 9:
        return Colors.blueGrey[300]!;
      case 10:
        return Colors.blueGrey[200]!;
      default:
        return Colors.blueGrey[500]!;
    }
  } else {
    // Colors for light mode
    switch (grade) {
      case 1:
        return Colors.lightBlue[50]!;
      case 2:
        return Colors.lightBlue[100]!;
      case 3:
        return Colors.lightBlue[200]!;
      case 4:
        return Colors.lightBlue[300]!;
      case 5:
        return Colors.lightBlue[400]!;
      case 9:
        return Colors.lightBlue[700]!;
      case 10:
        return Colors.lightBlue[800]!;
      default:
        return Colors.lightBlue[500]!;
    }
  }
}
