// To parse this JSON data, do
//
//     final searchPowerBodyModel = searchPowerBodyModelFromJson(jsonString);

import 'dart:convert';

SearchPowerBodyModel searchPowerBodyModelFromJson(String str) => SearchPowerBodyModel.fromJson(json.decode(str));

String searchPowerBodyModelToJson(SearchPowerBodyModel data) => json.encode(data.toJson());

class SearchPowerBodyModel {
    String? lensType;
    int? sph;
    double? cyl;
    String? brand;
    int? axis;
    int? add;
    String? index;
    String? coating;
    bool? availableOnly;

    SearchPowerBodyModel({
        this.lensType,
        this.sph,
        this.cyl,
        this.brand,
        this.axis,
        this.add,
        this.index,
        this.coating,
        this.availableOnly,
    });

    factory SearchPowerBodyModel.fromJson(Map<String, dynamic> json) => SearchPowerBodyModel(
        lensType: json["lens_type"],
        sph: json["sph"],
        cyl: json["cyl"]?.toDouble(),
        brand: json["brand"],
        axis: json["axis"],
        add: json["add"],
        index: json["index"],
        coating: json["coating"],
        availableOnly: json["available_only"],
    );

    Map<String, dynamic> toJson() => {
        "lens_type": lensType,
        "sph": sph,
        "cyl": cyl,
        "brand": brand,
        "axis": axis,
        "add": add,
        "index": index,
        "coating": coating,
        "available_only": availableOnly,
    };
}
