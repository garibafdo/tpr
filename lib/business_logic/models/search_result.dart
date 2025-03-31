import 'book.dart';

class SearchResult {
  // id will be used for sorting etc
  final int id;
  final Book book;
  final int pageNumber;
  final String description;
  final String suttaName;

  SearchResult(
      {required this.id,
      required this.book,
      required this.pageNumber,
      required this.description,
      required this.suttaName});
}
