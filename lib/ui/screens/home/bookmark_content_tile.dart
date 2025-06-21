import 'package:flutter/material.dart';
import 'package:tipitaka_pali/business_logic/models/folder.dart';

class BookmarkContentTile extends StatelessWidget {
  final dynamic content; // Can be either Bookmark or Folder
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const BookmarkContentTile({
    super.key,
    required this.content,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    bool isFolder = content is Folder;
    IconData icon = isFolder ? Icons.folder : Icons.bookmark;
    String title = isFolder ? content.name : content.note;
    String subtitle = isFolder ? "Folder" : "Page ${content.pageNumber}";

    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
      trailing: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.drive_file_move), // Example icon
            onPressed: () {
              // Your logic to handle the move to folder action
            },
            tooltip:
                'Move to Folder', // Providing a tooltip can help clarify the action
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
