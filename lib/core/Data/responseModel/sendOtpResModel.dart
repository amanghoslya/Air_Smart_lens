// To parse this JSON data, do
//
//     final sendOtpResModel = sendOtpResModelFromJson(jsonString);

import 'dart:convert';

SendOtpResModel sendOtpResModelFromJson(String str) =>
    SendOtpResModel.fromJson(json.decode(str));

String sendOtpResModelToJson(SendOtpResModel data) =>
    json.encode(data.toJson());

class SendOtpResModel {
  String? message;
  int? code;
  bool? error;
  dynamic data;

  SendOtpResModel({this.message, this.code, this.error, this.data});

  factory SendOtpResModel.fromJson(Map<String, dynamic> json) =>
      SendOtpResModel(
        message: json["message"],
        code: json["code"],
        error: json["error"],
        data: json["data"],
      );

  Map<String, dynamic> toJson() => {
    "message": message,
    "code": code,
    "error": error,
    "data": data,
  };
}
