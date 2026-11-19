// To parse this JSON data, do
//
//     final productDetailsResModel = productDetailsResModelFromJson(jsonString);

import 'dart:convert';

ProductDetailsResModel productDetailsResModelFromJson(String str) => ProductDetailsResModel.fromJson(json.decode(str));

String productDetailsResModelToJson(ProductDetailsResModel data) => json.encode(data.toJson());

class ProductDetailsResModel {
    String? message;
    int? code;
    bool? error;
    Data? data;

    ProductDetailsResModel({
        this.message,
        this.code,
        this.error,
        this.data,
    });

    factory ProductDetailsResModel.fromJson(Map<String, dynamic> json) => ProductDetailsResModel(
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
    String? id;
    String? brand;
    String? brandImage;
    String? productImage;
    double? index;
    String? base;
    String? coating;
    String? lensType;
    int? diameter;
    String? productCode;
    bool? nAFlag;
    String? valueTier;
    Exclusivity? exclusivity;
    int? minSph;
    int? maxSph;
    double? minCyl;
    int? maxCyl;
    String? rangeLabel;
    String? productName;
    String? powerKind;
    double? stepSph;
    double? stepCyl;
    int? minAdd;
    int? maxAdd;
    double? stepAdd;
    int? axis;
    String? axisRule;
    dynamic axisStep;
    bool? sphereSmallerThanCylinder;
    dynamic gradeQuantity;
    dynamic gradeRate;
    String? lensNature;
    String? purchaseStatus;
    String? returnStatus;
    String? partNumber;
    int? lowStockThreshold;
    bool? isActive;
    bool? isDisable;
    bool? isDeleted;
    int? date;
    int? month;
    int? year;
    int? createdAt;
    int? updatedAt;
    int? v;
    String? brandName;
    int? customerPrice;
    bool? isNegotiated;
    String? pricingTier;
    bool? available;
    List<dynamic>? powers;

    Data({
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
        this.brandName,
        this.customerPrice,
        this.isNegotiated,
        this.pricingTier,
        this.available,
        this.powers,
    });

    factory Data.fromJson(Map<String, dynamic> json) => Data(
        id: json["_id"],
        brand: json["brand"],
        brandImage: json["brand_image"],
        productImage: json["product_image"],
        index: json["index"]?.toDouble(),
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
        minCyl: json["min_cyl"]?.toDouble(),
        maxCyl: json["max_cyl"],
        rangeLabel: json["range_label"],
        productName: json["product_name"],
        powerKind: json["power_kind"],
        stepSph: json["step_sph"]?.toDouble(),
        stepCyl: json["step_cyl"]?.toDouble(),
        minAdd: json["min_add"],
        maxAdd: json["max_add"],
        stepAdd: json["step_add"]?.toDouble(),
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
        brandName: json["brand_name"],
        customerPrice: json["customer_price"],
        isNegotiated: json["is_negotiated"],
        pricingTier: json["pricing_tier"],
        available: json["available"],
        powers: json["powers"] == null ? [] : List<dynamic>.from(json["powers"]!.map((x) => x)),
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
        "brand_name": brandName,
        "customer_price": customerPrice,
        "is_negotiated": isNegotiated,
        "pricing_tier": pricingTier,
        "available": available,
        "powers": powers == null ? [] : List<dynamic>.from(powers!.map((x) => x)),
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

typedef ProductDetailsData = Data;
typedef ProductDetailsExclusivity = Exclusivity;

