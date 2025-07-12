// To parse this JSON data, do
//
//     final searchRequestModel = searchRequestModelFromJson(jsonString);
import 'dart:convert';

SearchRequestModel searchRequestModelFromJson(String str) => SearchRequestModel.fromJson(json.decode(str));

String searchRequestModelToJson(SearchRequestModel data) => json.encode(data.toJson());

class SearchRequestModel {
    final List<int> category;
    final String text;

    SearchRequestModel({
        required this.category,
        required this.text,
    });

    factory SearchRequestModel.fromJson(Map<String, dynamic> json) => SearchRequestModel(
        category: List<int>.from(json["category"].map((x) => x)),
        text: json["text"],
    );

    Map<String, dynamic> toJson() => {
        "category": List<dynamic>.from(category.map((x) => x)),
        "text": text,
    };
}
