// Response of GET /customer/brands
import 'dart:convert';

BrandsResModel brandsResModelFromJson(String str) => BrandsResModel.fromJson(json.decode(str));

class BrandsResModel {
  String? message;
  int? code;
  bool? error;
  List<BrandItem>? data;

  BrandsResModel({this.message, this.code, this.error, this.data});

  factory BrandsResModel.fromJson(Map<String, dynamic> json) => BrandsResModel(
        message: json['message'],
        code: json['code'],
        error: json['error'],
        data: json['data'] == null ? [] : List<BrandItem>.from((json['data'] as List).map((x) => BrandItem.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        'message': message,
        'code': code,
        'error': error,
        'data': data == null ? [] : List<dynamic>.from(data!.map((x) => x.toJson())),
      };
}

class BrandItem {
  String? id;
  String? name;
  String? image;
  String? imageUrl;
  String? brandImage;
  String? description;
  int? productCount;

  BrandItem({this.id, this.name, this.image, this.imageUrl, this.brandImage, this.description, this.productCount});

  factory BrandItem.fromJson(Map<String, dynamic> json) => BrandItem(
        id: json['id'],
        name: json['name'],
        image: json['image'],
        imageUrl: json['image_url'],
        brandImage: json['brand_image'],
        description: json['description'],
        productCount: json['product_count'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'image': image,
        'image_url': imageUrl,
        'brand_image': brandImage,
        'description': description,
        'product_count': productCount,
      };

  /// First non-empty image url the API gave.
  String? get picture {
    for (final u in [imageUrl, image, brandImage]) {
      if (u != null && u.trim().isNotEmpty) return u;
    }
    return null;
  }

  /// The key the rest of the app uses for this brand (catalog brands are upper-case).
  String get key => (name ?? id ?? '').trim().toUpperCase();
}
