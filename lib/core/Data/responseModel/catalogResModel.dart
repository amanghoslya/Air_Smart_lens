// To parse this JSON data, do
//
//     final catalogResModel = catalogResModelFromJson(jsonString);

import 'dart:convert';

CatalogResModel catalogResModelFromJson(String str) => CatalogResModel.fromJson(json.decode(str));

String catalogResModelToJson(CatalogResModel data) => json.encode(data.toJson());

class CatalogResModel {
  String? message;
  int? code;
  bool? error;
  Data? data;

  CatalogResModel({
    this.message,
    this.code,
    this.error,
    this.data,
  });

  factory CatalogResModel.fromJson(Map<String, dynamic> json) => CatalogResModel(
        message: json["message"],
        code: json["code"],
        error: json["error"],
        data: json["data"] == null ? null : Data.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "message": message,
        "code": code,
        "error": error,
        "data": data?.toJson(),
      };
}

class Data {
  int? total;
  int? totalPages;
  int? pageNo;
  int? limit;
  bool? hasNextPage;
  bool? hasPrevPage;
  TabCounts? tabCounts;
  Facets? facets;
  List<ListElement>? list;

  Data({
    this.total,
    this.totalPages,
    this.pageNo,
    this.limit,
    this.hasNextPage,
    this.hasPrevPage,
    this.tabCounts,
    this.facets,
    this.list,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        total: json["total"],
        totalPages: json["totalPages"],
        pageNo: json["pageNo"],
        limit: json["limit"],
        hasNextPage: json["hasNextPage"],
        hasPrevPage: json["hasPrevPage"],
        tabCounts: json["tabCounts"] == null ? null : TabCounts.fromJson(json["tabCounts"]),
        facets: json["facets"] == null ? null : Facets.fromJson(json["facets"]),
        list: json["list"] == null ? [] : List<ListElement>.from(json["list"]!.map((x) => ListElement.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "total": total,
        "totalPages": totalPages,
        "pageNo": pageNo,
        "limit": limit,
        "hasNextPage": hasNextPage,
        "hasPrevPage": hasPrevPage,
        "tabCounts": tabCounts?.toJson(),
        "facets": facets?.toJson(),
        "list": list == null ? [] : List<dynamic>.from(list!.map((x) => x.toJson())),
      };
}

class Facets {
  List<BrandElement>? brands;
  List<BrandElement>? lensTypes;
  List<Index>? indices;
  List<CoatingElement>? coatings;

  Facets({
    this.brands,
    this.lensTypes,
    this.indices,
    this.coatings,
  });

  factory Facets.fromJson(Map<String, dynamic> json) => Facets(
        brands: json["brands"] == null ? [] : List<BrandElement>.from(json["brands"]!.map((x) => BrandElement.fromJson(x))),
        lensTypes: json["lens_types"] == null ? [] : List<BrandElement>.from(json["lens_types"]!.map((x) => BrandElement.fromJson(x))),
        indices: json["indices"] == null ? [] : List<Index>.from(json["indices"]!.map((x) => Index.fromJson(x))),
        coatings: json["coatings"] == null ? [] : List<CoatingElement>.from(json["coatings"]!.map((x) => CoatingElement.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "brands": brands == null ? [] : List<dynamic>.from(brands!.map((x) => x.toJson())),
        "lens_types": lensTypes == null ? [] : List<dynamic>.from(lensTypes!.map((x) => x.toJson())),
        "indices": indices == null ? [] : List<dynamic>.from(indices!.map((x) => x.toJson())),
        "coatings": coatings == null ? [] : List<dynamic>.from(coatings!.map((x) => x.toJson())),
      };
}

class BrandElement {
  String? name;
  int? count;

  BrandElement({
    this.name,
    this.count,
  });

  factory BrandElement.fromJson(Map<String, dynamic> json) => BrandElement(
        name: json["name"],
        count: json["count"],
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "count": count,
      };
}

class CoatingElement {
  String? name;
  String? code;
  String? color;
  int? count;

  CoatingElement({
    this.name,
    this.code,
    this.color,
    this.count,
  });

  factory CoatingElement.fromJson(Map<String, dynamic> json) => CoatingElement(
        name: json["name"],
        code: json["code"],
        color: json["color"],
        count: json["count"],
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "code": code,
        "color": color,
        "count": count,
      };
}

class Index {
  num? index;
  String? label;
  int? count;

  Index({
    this.index,
    this.label,
    this.count,
  });

  factory Index.fromJson(Map<String, dynamic> json) => Index(
        index: json["index"],
        label: json["label"],
        count: json["count"],
      );

  Map<String, dynamic> toJson() => {
        "index": index,
        "label": label,
        "count": count,
      };
}

class ListElement {
  String? id;
  String? brand;
  String? brandImage;
  String? productImage;
  num? index;
  String? base;
  String? coating;
  String? lensType;
  num? diameter;
  String? productCode;
  bool? nAFlag;
  String? valueTier;
  Exclusivity? exclusivity;
  num? minSph;
  num? maxSph;
  num? minCyl;
  num? maxCyl;
  String? rangeLabel;
  String? productName;
  String? powerKind;
  num? stepSph;
  num? stepCyl;
  num? minAdd;
  num? maxAdd;
  num? stepAdd;
  num? axis;
  String? axisRule;
  dynamic axisStep;
  bool? sphereSmallerThanCylinder;
  dynamic gradeQuantity;
  dynamic gradeRate;
  String? lensNature;
  String? purchaseStatus;
  String? returnStatus;
  String? partNumber;
  num? lowStockThreshold;
  bool? isActive;
  bool? isDisable;
  bool? isDeleted;
  num? date;
  num? month;
  num? year;
  num? createdAt;
  num? updatedAt;
  num? v;
  num? customerPrice;
  bool? isNegotiated;
  String? pricingTier;
  bool? available;

  ListElement({
    this.id,
    this.brand,
    this.brandImage,
    this.productImage,
    this.index,
    this.base,
    this.coating,
    this.lensType,
    this.diameter,
    this.productCode,
    this.nAFlag,
    this.valueTier,
    this.exclusivity,
    this.minSph,
    this.maxSph,
    this.minCyl,
    this.maxCyl,
    this.rangeLabel,
    this.productName,
    this.powerKind,
    this.stepSph,
    this.stepCyl,
    this.minAdd,
    this.maxAdd,
    this.stepAdd,
    this.axis,
    this.axisRule,
    this.axisStep,
    this.sphereSmallerThanCylinder,
    this.gradeQuantity,
    this.gradeRate,
    this.lensNature,
    this.purchaseStatus,
    this.returnStatus,
    this.partNumber,
    this.lowStockThreshold,
    this.isActive,
    this.isDisable,
    this.isDeleted,
    this.date,
    this.month,
    this.year,
    this.createdAt,
    this.updatedAt,
    this.v,
    this.customerPrice,
    this.isNegotiated,
    this.pricingTier,
    this.available,
  });

  factory ListElement.fromJson(Map<String, dynamic> json) => ListElement(
        id: json["_id"],
        brand: json["brand"],
        brandImage: json["brand_image"],
        productImage: json["product_image"],
        index: json["index"],
        base: json["base"],
        coating: json["coating"],
        lensType: json["lens_type"],
        diameter: json["diameter"],
        productCode: json["product_code"],
        nAFlag: json["n_a_flag"],
        valueTier: json["value_tier"],
        exclusivity: json["exclusivity"] == null ? null : Exclusivity.fromJson(json["exclusivity"]),
        minSph: json["min_sph"],
        maxSph: json["max_sph"],
        minCyl: json["min_cyl"],
        maxCyl: json["max_cyl"],
        rangeLabel: json["range_label"],
        productName: json["product_name"],
        powerKind: json["power_kind"],
        stepSph: json["step_sph"],
        stepCyl: json["step_cyl"],
        minAdd: json["min_add"],
        maxAdd: json["max_add"],
        stepAdd: json["step_add"],
        axis: json["axis"],
        axisRule: json["axis_rule"],
        axisStep: json["axis_step"],
        sphereSmallerThanCylinder: json["sphere_smaller_than_cylinder"],
        gradeQuantity: json["grade_quantity"],
        gradeRate: json["grade_rate"],
        lensNature: json["lens_nature"],
        purchaseStatus: json["purchase_status"],
        returnStatus: json["return_status"],
        partNumber: json["part_number"],
        lowStockThreshold: json["low_stock_threshold"],
        isActive: json["is_active"],
        isDisable: json["isDisable"],
        isDeleted: json["isDeleted"],
        date: json["date"],
        month: json["month"],
        year: json["year"],
        createdAt: json["createdAt"],
        updatedAt: json["updatedAt"],
        v: json["__v"],
        customerPrice: json["customer_price"],
        isNegotiated: json["is_negotiated"],
        pricingTier: json["pricing_tier"],
        available: json["available"],
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "brand": brand,
        "brand_image": brandImage,
        "product_image": productImage,
        "index": index,
        "base": base,
        "coating": coating,
        "lens_type": lensType,
        "diameter": diameter,
        "product_code": productCode,
        "n_a_flag": nAFlag,
        "value_tier": valueTier,
        "exclusivity": exclusivity?.toJson(),
        "min_sph": minSph,
        "max_sph": maxSph,
        "min_cyl": minCyl,
        "max_cyl": maxCyl,
        "range_label": rangeLabel,
        "product_name": productName,
        "power_kind": powerKind,
        "step_sph": stepSph,
        "step_cyl": stepCyl,
        "min_add": minAdd,
        "max_add": maxAdd,
        "step_add": stepAdd,
        "axis": axis,
        "axis_rule": axisRule,
        "axis_step": axisStep,
        "sphere_smaller_than_cylinder": sphereSmallerThanCylinder,
        "grade_quantity": gradeQuantity,
        "grade_rate": gradeRate,
        "lens_nature": lensNature,
        "purchase_status": purchaseStatus,
        "return_status": returnStatus,
        "part_number": partNumber,
        "low_stock_threshold": lowStockThreshold,
        "is_active": isActive,
        "isDisable": isDisable,
        "isDeleted": isDeleted,
        "date": date,
        "month": month,
        "year": year,
        "createdAt": createdAt,
        "updatedAt": updatedAt,
        "__v": v,
        "customer_price": customerPrice,
        "is_negotiated": isNegotiated,
        "pricing_tier": pricingTier,
        "available": available,
      };
}

class Exclusivity {
  dynamic city;
  dynamic customerId;

  Exclusivity({
    this.city,
    this.customerId,
  });

  factory Exclusivity.fromJson(Map<String, dynamic> json) => Exclusivity(
        city: json["city"],
        customerId: json["customer_id"],
      );

  Map<String, dynamic> toJson() => {
        "city": city,
        "customer_id": customerId,
      };
}

class TabCounts {
  int? all;
  int? sv;
  int? prog;

  TabCounts({
    this.all,
    this.sv,
    this.prog,
  });

  factory TabCounts.fromJson(Map<String, dynamic> json) => TabCounts(
        all: json["all"],
        sv: json["sv"],
        prog: json["prog"],
      );

  Map<String, dynamic> toJson() => {
        "all": all,
        "sv": sv,
        "prog": prog,
      };
}
