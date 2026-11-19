// To parse this JSON data, do
//
//     final catalogeBodyModel = catalogeBodyModelFromJson(jsonString);

import 'dart:convert';

CatalogeBodyModel catalogeBodyModelFromJson(String str) => CatalogeBodyModel.fromJson(json.decode(str));

String catalogeBodyModelToJson(CatalogeBodyModel data) => json.encode(data.toJson());

class CatalogeBodyModel {
    int? pageNo;
    int? limit;
    String? brand;
    dynamic index;
    String? lensType;
    String? base;
    String? coating;
    String? search;
    String? sortBy;

    CatalogeBodyModel({
        this.pageNo,
        this.limit,
        this.brand,
        this.index,
        this.lensType,
        this.base,
        this.coating,
        this.search,
        this.sortBy,
    });

    factory CatalogeBodyModel.fromJson(Map<String, dynamic> json) => CatalogeBodyModel(
        pageNo: json["pageNo"],
        limit: json["limit"],
        brand: json["brand"],
        index: json["index"],
        lensType: json["lens_type"],
        base: json["base"],
        coating: json["coating"],
        search: json["search"],
        sortBy: json["sortBy"],
    );

    Map<String, dynamic> toJson() => {
        "pageNo": pageNo,
        "limit": limit,
        "brand": brand,
        "index": index,
        "lens_type": lensType,
        "base": base,
        "coating": coating,
        "search": search,
        "sortBy": sortBy,
    };
}
