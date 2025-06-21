import 'package:flutter/material.dart';
import 'package:tipitaka_pali/business_logic/models/folder.dart';

class FolderPathNavigator extends StatelessWidget {
  final List<Folder> path;
  final Function(Folder) onFolderTap;

  const FolderPathNavigator({
    super.key,
    required this.path,
    required this.onFolderTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: path.map((folder) {
          return InkWell(
            onTap: () => onFolderTap(folder),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(folder.name,
                  style: const TextStyle(fontSize: 16, color: Colors.blue)),
            ),
          );
        }).toList(),
      ),
    );
  }
}
