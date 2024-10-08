import 'dart:convert';

// Function to parse JSON and create a list of Freq objects
List<Freq> freqFromJson(String str) =>
    List<Freq>.from(json.decode(str).map((x) => Freq.fromJson(x)));

class Freq {
  int id;
  String headword;
  Map<String, dynamic> freqData;

  Freq({
    this.id = 0,
    this.headword = "",
    required this.freqData,
  });

  // Factory method to create a Freq object from a JSON map
  factory Freq.fromJson(Map<String, dynamic> json) {
    return Freq(
      id: json["id"] ?? 0,
      headword: json["headword"] ?? "",
      freqData: jsonDecode(
          json["freq_data"] ?? '{}'), // Assumes freq_data is a JSON string
    );
  }

  // Method to convert Freq object back to JSON
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "headword": headword,
      "freq_data": jsonEncode(freqData), // Converts Map back to a JSON string
    };
  }
}
