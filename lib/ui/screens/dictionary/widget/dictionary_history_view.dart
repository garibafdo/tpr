import 'package:flutter/material.dart';
import 'package:tipitaka_pali/l10n/app_localizations.dart';
import 'package:tipitaka_pali/business_logic/models/dictionary_history.dart';
import 'package:tipitaka_pali/services/database/database_helper.dart';
import 'package:tipitaka_pali/services/repositories/dictionary_repo.dart';
import 'package:tipitaka_pali/ui/widgets/pali_text_view.dart';
import 'package:tipitaka_pali/utils/pali_word.dart';

enum DictionaryHistoryOrder { time, alphabetically }

class DictionaryHistoryView extends StatefulWidget {
  final List<DictionaryHistory> histories;
  final ValueChanged<String>? onClick;
  final ValueChanged<String>? onDelete;
  final ScrollController? scrollController;

  const DictionaryHistoryView({
    super.key,
    required this.histories,
    this.onClick,
    this.onDelete,
    this.scrollController,
  });

  @override
  State<DictionaryHistoryView> createState() => _DictionaryHistoryViewState();
}

class _DictionaryHistoryViewState extends State<DictionaryHistoryView> {
  DictionaryHistoryOrder order = DictionaryHistoryOrder.time;
  late List<DictionaryHistory> histories;

  @override
  void initState() {
    super.initState();
    // clone list
    histories = [...widget.histories];
  }

  @override
  void didUpdateWidget(covariant DictionaryHistoryView oldWidget) {
    super.didUpdateWidget(oldWidget);
    histories = [...widget.histories];
  }

  @override
  Widget build(BuildContext context) {
    if (histories.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context)!.noHistory));
    }
    if (order == DictionaryHistoryOrder.alphabetically) {
      histories.sort((a, b) => PaliWord.compare(a.word, b.word));
    } else {
      histories.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    }
    return Column(
      children: [
        _buildOrderSelector(),
        TextButton.icon(
            onPressed: () async {
              await DictionaryDatabaseRepository(DatabaseHelper())
                ..deleteAll();
              setState(() {
                histories.clear();
              });
            },
            icon: const Icon(Icons.auto_delete),
            label: const Text("Delete All")),
        Expanded(
          child: ListView.separated(
            controller: widget.scrollController,
            itemCount: histories.length,
            itemBuilder: (context, index) {
              return ListTile(
                dense: true,
                title: PaliTextView(histories[index].word),
                onTap: () => widget.onClick?.call(histories[index].word),
                trailing: IconButton(
                  onPressed: () => widget.onDelete?.call(histories[index].word),
                  icon: const Icon(Icons.delete),
                ),
              );
            },
            separatorBuilder: (context, index) => const Divider(height: 1),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderSelector() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Text(AppLocalizations.of(context)!.sortBy),
          const Spacer(),
          SegmentedButton<DictionaryHistoryOrder>(
            segments: [
              ButtonSegment<DictionaryHistoryOrder>(
                  value: DictionaryHistoryOrder.time,
                  label: Text(
                    AppLocalizations.of(context)!.time,
                  )),
              ButtonSegment<DictionaryHistoryOrder>(
                  value: DictionaryHistoryOrder.alphabetically,
                  label: Text(
                    AppLocalizations.of(context)!.alphabetically,
                  )),
            ],
            showSelectedIcon: false,
            selected: <DictionaryHistoryOrder>{order},
            onSelectionChanged: (value) {
              setState(() {
                order = value.first;
              });
            },
          ),
        ],
      ),
    );
  }
}
