import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tipitaka_pali/business_logic/models/download_list_item.dart';
import 'download_service.dart';
import 'download_notifier.dart';
import 'package:provider/provider.dart';
import 'package:tipitaka_pali/l10n/app_localizations.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:tipitaka_pali/services/prefs.dart';

class DownloadView extends StatelessWidget {
  const DownloadView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DownloadNotifier>(
      create: (context) => DownloadNotifier(),
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.downloadTitle),
          ),
          body: Consumer<DownloadNotifier>(
            builder: (context, downloadModel, child) {
              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      height: 50,
                      alignment: Alignment.center,
                      child: Center(
                        child: Text(
                          downloadModel.message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (downloadModel.downloading ||
                        downloadModel.connectionChecking)
                      const CircularProgressIndicator(),
                    const SizedBox(height: 20),
                    FutureBuilder<bool>(
                      future: checkInternetConnection(downloadModel),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox.shrink();
                        }
                        if (snapshot.hasData && snapshot.data!) {
                          return getFutureBuilder(context, downloadModel);
                        } else {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.signal_wifi_off,
                                    size: 80,
                                    color: (!Prefs.darkThemeOn)
                                        ? Theme.of(context)
                                            .appBarTheme
                                            .backgroundColor
                                        : null),
                                const SizedBox(height: 20),
                                Text(AppLocalizations.of(context)!
                                    .turnOnInternet),
                              ],
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<bool> checkInternetConnection(DownloadNotifier downloadModel) async {
    if (downloadModel.downloading) {
      return true;
    }
    downloadModel.connectionChecking = true;
    bool hasInternet = await InternetConnection().hasInternetAccess;
    downloadModel.connectionChecking = false;
    return hasInternet;
  }

  Future<void> getDownload(BuildContext context, DownloadNotifier dn,
      DownloadListItem downloadListItem) async {
    dn.message = AppLocalizations.of(context)!.checkingInternet;

    if (await checkInternetConnection(dn)) {
      DownloadService downloadService = DownloadService(
          downloadNotifier: dn, downloadListItem: downloadListItem);

      dn.downloading = true;
      await downloadService.installSqlZip();
    } else {
      dn.message = "No Internet";
    }
  }

  Widget getFutureBuilder(
      BuildContext context, DownloadNotifier downloadModel) {
    if (downloadModel.downloading) {
      return const SizedBox.shrink();
    } else {
      return Expanded(
        child: FutureBuilder<http.Response>(
          future: http.get(Uri.parse(
              'https://github.com/bksubhuti/tpr_downloads/raw/master/download_source_files/download_list.json')),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.hasError) {
              return const Center(
                child: Text('Error fetching data'),
              );
            }

            // Parse the JSON data
            List<DownloadListItem> dlList =
                downloadListItemFromJson(snapshot.data!.body);

            // Group the items by category
            Map<String, List<DownloadListItem>> categorizedItems = {};
            var inserted = false;
            for (var item in dlList) {
              String category = item.category ?? 'Uncategorized';
              if (!categorizedItems.containsKey(category)) {
                categorizedItems[category] = [];
              }
              // if (!inserted && category == "Other Beta") {
              //   inserted = true;
              //   categorizedItems[category]!.insert(0, DownloadListItem.fromJson(
              //     json.decode(
              //         """{
              //           "name": "DPD Root family",
              //           "release_date": "29.9.2024",
              //           "type": "dictionary",
              //           "url": "https://pali.tools/dpd__family_root.zip",
              //           "filename": "dpd__family_root.sql",
              //           "size": "674 KB"
              //         }
              //         """
              //     ),
              //   ));
              // }
              // if (category == "Other Beta") {
              //   item.url = 'https://pali.tools/dpd__extras.zip';
              // }
              categorizedItems[category]!.add(item);
            }

            // Convert the map entries to a list for indexed access
            final categories = categorizedItems.entries.toList();

            // Use a ScrollController if needed
            final ScrollController scrollController = ScrollController();

            return ListView.builder(
              controller: scrollController,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final GlobalKey expansionTileKey = GlobalKey();
                final entry = categories[index];
                String category = entry.key;
                List<DownloadListItem> items = entry.value;

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 0,
                    vertical: 6,
                  ),
                  child: ExpansionTile(
                    key: expansionTileKey,
                    onExpansionChanged: (isExpanding) {
                      if (isExpanding) {
                        // Delay scrolling a bit to allow for the expansion animation to start.
                        Future.delayed(const Duration(milliseconds: 200))
                            .then((value) {
                          RenderObject? renderObject = expansionTileKey
                              .currentContext
                              ?.findRenderObject();
                          renderObject?.showOnScreen(
                            rect: renderObject.semanticBounds,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.ease,
                          );
                        });
                      }
                    },
                    initiallyExpanded: Prefs.expandedBookList,
                    title: Text(
                      category,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    tilePadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    childrenPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    children: items.map<Widget>((item) {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        elevation: 2.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: ListTile(
                          title: Text("${item.name} (${item.size})"),
                          subtitle: Text(item.releaseDate),
                          onTap: () async {
                            await getDownload(context, downloadModel, item);
                          },
                          minVerticalPadding: 4,
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            );
          },
        ),
      );
    }
  }
}
