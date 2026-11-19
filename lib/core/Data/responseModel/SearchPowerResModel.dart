// To parse this JSON data, do
//
//     final searchPowerResModel = searchPowerResModelFromJson(jsonString);

import 'dart:convert';

SearchPowerResModel searchPowerResModelFromJson(String str) => SearchPowerResModel.fromJson(json.decode(str));

String searchPowerResModelToJson(SearchPowerResModel data) => json.encode(data.toJson());

class SearchPowerResModel {
    String? message;
    int? code;
    bool? error;
    Data? data;

    SearchPowerResModel({
        this.message,
        this.code,
        this.error,
        this.data,
    });

    factory SearchPowerResModel.fromJson(Map<String, dynamic> json) => SearchPowerResModel(
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
    String? dataRangeCode;
    String? rangeCode;
    int? totalMatches;
    Facets? facets;
    List<ListElement>? list;
    List<Match>? matches;

    Data({
        this.dataRangeCode,
        this.rangeCode,
        this.totalMatches,
        this.facets,
        this.list,
        this.matches,
    });

    factory Data.fromJson(Map<String, dynamic> json) => Data(
        dataRangeCode: json["range_code"],
        rangeCode: json["rangeCode"],
        totalMatches: json["total_matches"],
        facets: json["facets"] == null ? null : Facets.fromJson(json["facets"]),
        list: json["list"] == null ? [] : List<ListElement>.from(json["list"]!.map((x) => ListElement.fromJson(x))),
        matches: json["matches"] == null ? [] : List<Match>.from(json["matches"]!.map((x) => Match.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "range_code": dataRangeCode,
        "rangeCode": rangeCode,
        "total_matches": totalMatches,
        "facets": facets?.toJson(),
        "list": list == null ? [] : List<dynamic>.from(list!.map((x) => x.toJson())),
        "matches": matches == null ? [] : List<dynamic>.from(matches!.map((x) => x.toJson())),
    };
}

class Facets {
    List<Index>? indices;
    List<CoatingElement>? coatings;
    List<BrandElement>? brands;

    Facets({
        this.indices,
        this.coatings,
        this.brands,
    });

    factory Facets.fromJson(Map<String, dynamic> json) => Facets(
        indices: json["indices"] == null ? [] : List<Index>.from(json["indices"]!.map((x) => Index.fromJson(x))),
        coatings: json["coatings"] == null ? [] : List<CoatingElement>.from(json["coatings"]!.map((x) => CoatingElement.fromJson(x))),
        brands: json["brands"] == null ? [] : List<BrandElement>.from(json["brands"]!.map((x) => BrandElement.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "indices": indices == null ? [] : List<dynamic>.from(indices!.map((x) => x.toJson())),
        "coatings": coatings == null ? [] : List<dynamic>.from(coatings!.map((x) => x.toJson())),
        "brands": brands == null ? [] : List<dynamic>.from(brands!.map((x) => x.toJson())),
    };
}

class BrandElement {
    BrandEnum? name;
    int? count;

    BrandElement({
        this.name,
        this.count,
    });

    factory BrandElement.fromJson(Map<String, dynamic> json) => BrandElement(
        name: brandEnumValues.map[json["name"]],
        count: json["count"],
    );

    Map<String, dynamic> toJson() => {
        "name": brandEnumValues.reverse[name],
        "count": count,
    };
}

enum BrandEnum {
    AIR_SMART,
    OPAL,
    PHOTO_FAST,
    RAPID,
    VISHAL
}

final brandEnumValues = EnumValues({
    "Air Smart": BrandEnum.AIR_SMART,
    "Opal": BrandEnum.OPAL,
    "Photo Fast": BrandEnum.PHOTO_FAST,
    "Rapid": BrandEnum.RAPID,
    "Vishal": BrandEnum.VISHAL
});

class CoatingElement {
    CoatingEnum? name;
    Code? code;
    Color? color;
    int? count;

    CoatingElement({
        this.name,
        this.code,
        this.color,
        this.count,
    });

    factory CoatingElement.fromJson(Map<String, dynamic> json) => CoatingElement(
        name: coatingEnumValues.map[json["name"]],
        code: codeValues.map[json["code"]],
        color: colorValues.map[json["color"]],
        count: json["count"],
    );

    Map<String, dynamic> toJson() => {
        "name": coatingEnumValues.reverse[name],
        "code": codeValues.reverse[code],
        "color": colorValues.reverse[color],
        "count": count,
    };
}

enum Code {
    GREEN,
    HC,
    OPAL
}

final codeValues = EnumValues({
    "GREEN": Code.GREEN,
    "HC": Code.HC,
    "OPAL": Code.OPAL
});

enum Color {
    C9_CFCC,
    THE_4_C7_DB8,
    THE_4_C8_A3_F
}

final colorValues = EnumValues({
    "#C9CFCC": Color.C9_CFCC,
    "#4C7DB8": Color.THE_4_C7_DB8,
    "#4C8A3F": Color.THE_4_C8_A3_F
});

enum CoatingEnum {
    GREEN,
    HC,
    OPAL_LOW_REFLECTION_BLUE
}

final coatingEnumValues = EnumValues({
    "GREEN": CoatingEnum.GREEN,
    "HC": CoatingEnum.HC,
    "OPAL (LOW REFLECTION BLUE)": CoatingEnum.OPAL_LOW_REFLECTION_BLUE
});

class Index {
    double? index;
    Label? label;
    int? count;

    Index({
        this.index,
        this.label,
        this.count,
    });

    factory Index.fromJson(Map<String, dynamic> json) => Index(
        index: json["index"]?.toDouble(),
        label: labelValues.map[json["label"]],
        count: json["count"],
    );

    Map<String, dynamic> toJson() => {
        "index": index,
        "label": labelValues.reverse[label],
        "count": count,
    };
}

enum Label {
    STANDARD
}

final labelValues = EnumValues({
    "Standard": Label.STANDARD
});

class ListElement {
    String? id;
    String? listId;
    String? pid;
    Name? name;
    Name? productName;
    BrandEnum? brand;
    String? brandImage;
    String? productImage;
    String? image;
    double? index;
    Label? indexLabel;
    CoatingEnum? coating;
    Code? coatingCode;
    Color? coatingColor;
    LensType? lensType;
    Base? base;
    int? diameter;
    String? rangeLabel;
    String? productCode;
    int? customerPrice;
    int? price;
    bool? isNegotiated;
    PricingTier? pricingTier;
    int? stockQuantity;
    Status? stockStatus;
    bool? isMto;
    List<Line>? lines;

    ListElement({
        this.id,
        this.listId,
        this.pid,
        this.name,
        this.productName,
        this.brand,
        this.brandImage,
        this.productImage,
        this.image,
        this.index,
        this.indexLabel,
        this.coating,
        this.coatingCode,
        this.coatingColor,
        this.lensType,
        this.base,
        this.diameter,
        this.rangeLabel,
        this.productCode,
        this.customerPrice,
        this.price,
        this.isNegotiated,
        this.pricingTier,
        this.stockQuantity,
        this.stockStatus,
        this.isMto,
        this.lines,
    });

    factory ListElement.fromJson(Map<String, dynamic> json) => ListElement(
        id: json["_id"],
        listId: json["id"],
        pid: json["pid"],
        name: nameValues.map[json["name"]],
        productName: nameValues.map[json["product_name"]],
        brand: brandEnumValues.map[json["brand"]],
        brandImage: json["brand_image"],
        productImage: json["product_image"],
        image: json["image"],
        index: json["index"]?.toDouble(),
        indexLabel: labelValues.map[json["index_label"]],
        coating: coatingEnumValues.map[json["coating"]],
        coatingCode: codeValues.map[json["coating_code"]],
        coatingColor: colorValues.map[json["coating_color"]],
        lensType: lensTypeValues.map[json["lens_type"]],
        base: baseValues.map[json["base"]],
        diameter: json["diameter"],
        rangeLabel: json["range_label"],
        productCode: json["product_code"],
        customerPrice: json["customer_price"],
        price: json["price"],
        isNegotiated: json["is_negotiated"],
        pricingTier: pricingTierValues.map[json["pricing_tier"]],
        stockQuantity: json["stock_quantity"],
        stockStatus: statusValues.map[json["stock_status"]],
        isMto: json["is_mto"],
        lines: json["lines"] == null ? [] : List<Line>.from(json["lines"]!.map((x) => Line.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "_id": id,
        "id": listId,
        "pid": pid,
        "name": nameValues.reverse[name],
        "product_name": nameValues.reverse[productName],
        "brand": brandEnumValues.reverse[brand],
        "brand_image": brandImage,
        "product_image": productImage,
        "image": image,
        "index": index,
        "index_label": labelValues.reverse[indexLabel],
        "coating": coatingEnumValues.reverse[coating],
        "coating_code": codeValues.reverse[coatingCode],
        "coating_color": colorValues.reverse[coatingColor],
        "lens_type": lensTypeValues.reverse[lensType],
        "base": baseValues.reverse[base],
        "diameter": diameter,
        "range_label": rangeLabel,
        "product_code": productCode,
        "customer_price": customerPrice,
        "price": price,
        "is_negotiated": isNegotiated,
        "pricing_tier": pricingTierValues.reverse[pricingTier],
        "stock_quantity": stockQuantity,
        "stock_status": statusValues.reverse[stockStatus],
        "is_mto": isMto,
        "lines": lines == null ? [] : List<dynamic>.from(lines!.map((x) => x.toJson())),
    };
}

enum Base {
    BLUE_CUT,
    HARD_COAT,
    PHOTO_GREY_BLUE_CUT
}

final baseValues = EnumValues({
    "Blue Cut": Base.BLUE_CUT,
    "Hard Coat": Base.HARD_COAT,
    "Photo Grey Blue Cut": Base.PHOTO_GREY_BLUE_CUT
});

enum LensType {
    KT
}

final lensTypeValues = EnumValues({
    "KT": LensType.KT
});

class Line {
    String? range;
    int? dia;
    int? listPrice;

    Line({
        this.range,
        this.dia,
        this.listPrice,
    });

    factory Line.fromJson(Map<String, dynamic> json) => Line(
        range: json["range"],
        dia: json["dia"],
        listPrice: json["listPrice"],
    );

    Map<String, dynamic> toJson() => {
        "range": range,
        "dia": dia,
        "listPrice": listPrice,
    };
}

enum Name {
    AIR_SMART_BLUE_CUT_GREEN_COMP_KT_156,
    CLEAR_HC_COMP_KT_156,
    OPAL_BLUE_CUT_LRB_BLUE_COMP_KT_156,
    PHOTO_FAST_PG_BLUE_CUT_GREEN_COMP_KT_156,
    RAPID_PG_HC_COMP_KT_156
}

final nameValues = EnumValues({
    "AIR SMART BLUE CUT GREEN COMP KT 1.56": Name.AIR_SMART_BLUE_CUT_GREEN_COMP_KT_156,
    "CLEAR HC COMP KT 1.56": Name.CLEAR_HC_COMP_KT_156,
    "OPAL BLUE CUT LRB BLUE COMP KT 1.56": Name.OPAL_BLUE_CUT_LRB_BLUE_COMP_KT_156,
    "PHOTO FAST PG BLUE CUT GREEN COMP KT 1.56": Name.PHOTO_FAST_PG_BLUE_CUT_GREEN_COMP_KT_156,
    "RAPID PG HC COMP KT 1.56": Name.RAPID_PG_HC_COMP_KT_156
});

enum PricingTier {
    STOCK_PLATINUM
}

final pricingTierValues = EnumValues({
    "stock_platinum": PricingTier.STOCK_PLATINUM
});

enum Status {
    AVAILABLE
}

final statusValues = EnumValues({
    "available": Status.AVAILABLE
});

class Match {
    String? pid;
    String? productId;
    ListElement? product;
    int? li;
    int? liL;
    UR? uR;
    dynamic uL;
    bool? dR;
    bool? dL;
    bool? diff;
    bool? mto;
    int? price;
    Stock? stock;

    Match({
        this.pid,
        this.productId,
        this.product,
        this.li,
        this.liL,
        this.uR,
        this.uL,
        this.dR,
        this.dL,
        this.diff,
        this.mto,
        this.price,
        this.stock,
    });

    factory Match.fromJson(Map<String, dynamic> json) => Match(
        pid: json["pid"],
        productId: json["product_id"],
        product: json["product"] == null ? null : ListElement.fromJson(json["product"]),
        li: json["li"],
        liL: json["liL"],
        uR: json["uR"] == null ? null : UR.fromJson(json["uR"]),
        uL: json["uL"],
        dR: json["dR"],
        dL: json["dL"],
        diff: json["diff"],
        mto: json["mto"],
        price: json["price"],
        stock: json["stock"] == null ? null : Stock.fromJson(json["stock"]),
    );

    Map<String, dynamic> toJson() => {
        "pid": pid,
        "product_id": productId,
        "product": product?.toJson(),
        "li": li,
        "liL": liL,
        "uR": uR?.toJson(),
        "uL": uL,
        "dR": dR,
        "dL": dL,
        "diff": diff,
        "mto": mto,
        "price": price,
        "stock": stock?.toJson(),
    };
}

class Stock {
    Status? status;
    int? totalQuantity;

    Stock({
        this.status,
        this.totalQuantity,
    });

    factory Stock.fromJson(Map<String, dynamic> json) => Stock(
        status: statusValues.map[json["status"]],
        totalQuantity: json["total_quantity"],
    );

    Map<String, dynamic> toJson() => {
        "status": statusValues.reverse[status],
        "total_quantity": totalQuantity,
    };
}

class UR {
    int? sph;
    double? cyl;
    int? axis;
    int? add;

    UR({
        this.sph,
        this.cyl,
        this.axis,
        this.add,
    });

    factory UR.fromJson(Map<String, dynamic> json) => UR(
        sph: json["sph"],
        cyl: json["cyl"]?.toDouble(),
        axis: json["axis"],
        add: json["add"],
    );

    Map<String, dynamic> toJson() => {
        "sph": sph,
        "cyl": cyl,
        "axis": axis,
        "add": add,
    };
}

class EnumValues<T> {
    Map<String, T> map;
    late Map<T, String> reverseMap;

    EnumValues(this.map);

    Map<T, String> get reverse {
            reverseMap = map.map((k, v) => MapEntry(v, k));
            return reverseMap;
    }
}
