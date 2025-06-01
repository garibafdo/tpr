import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controller/search_filter_provider.dart';
import 'package:tipitaka_pali/l10n/app_localizations.dart';

class SearchFilterView extends StatelessWidget {
  const SearchFilterView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<SearchFilterController>();
    final closeButton = Positioned(
        top: -20,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: ClipOval(
            child: Container(
              width: 56,
              height: 56,
              color: Theme.of(context).colorScheme.secondary,
              child: Icon(
                Icons.close,
                color: Theme.of(context).colorScheme.onSecondary,
              ),
            ),
          ),
        ));

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 45),
      child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            ListView(
              shrinkWrap: true,
              children: [
                Container(height: 42),
                _buildMainCategoryFilter(notifier),
                _buildSubCategoryFilters(notifier),
                ButtonBar(
                  alignment: MainAxisAlignment.center,
                  children: [
                    FilledButton(
                      onPressed: notifier.onSelectAll,
                      child: Text(AppLocalizations.of(context)!.selectAll),
                    ),
                    FilledButton(
                      onPressed: notifier.onSelectNone,
                      child: Text(AppLocalizations.of(context)!.selectNone),
                    ),
                  ],
                ),
              ],
            ),
            closeButton,
          ]),
    );
  }

  Widget _buildMainCategoryFilter(SearchFilterController notifier) {
    //print('building main filter');
    final mainCategoryFilters = notifier.mainCategoryFilters;
    final selectedMainCategoryFilters = notifier.selectedMainCategoryFilters;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        child: Wrap(
            children: mainCategoryFilters.entries
                .map((e) => Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: FilterChip(
                          label: Text(e.value),
                          selected: selectedMainCategoryFilters.contains(e.key),
                          onSelected: (isSelected) {
                            notifier.onMainFilterChange(e.key, isSelected);
                          }),
                    ))
                .toList()),
      ),
    );
  }

  Widget _buildSubCategoryFilters(SearchFilterController notifier) {
    final subCategoryFilters = notifier.subCategoryFilters;
    final selectedSubCategoryFilters = notifier.selectedSubCategoryFilters;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        child: Wrap(
            children: subCategoryFilters.entries
                .map((e) => Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: FilterChip(
                          label: Text(e.value),
                          selected: selectedSubCategoryFilters.contains(e.key),
                          onSelected: (isSelected) {
                            notifier.onSubFilterChange(e.key, isSelected);
                          }),
                    ))
                .toList()),
      ),
    );
  }
}
