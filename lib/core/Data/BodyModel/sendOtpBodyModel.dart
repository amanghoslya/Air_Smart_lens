// To parse this JSON data, do
//
//     final sendOtpBodyModel = sendOtpBodyModelFromJson(jsonString);

import 'dart:convert';

SendOtpBodyModel sendOtpBodyModelFromJson(String str) =>
    SendOtpBodyModel.fromJson(json.decode(str));

String sendOtpBodyModelToJson(SendOtpBodyModel data) =>
    json.encode(data.toJson());

class SendOtpBodyModel {
  String? phone;
  String? deviceId;
  String? platform;

  SendOtpBodyModel({this.phone, this.deviceId, this.platform});

  factory SendOtpBodyModel.fromJson(Map<String, dynamic> json) =>
      SendOtpBodyModel(
        phone: json["phone"],
        deviceId: json["deviceId"],
        platform: json["platform"],
      );

  Map<String, dynamic> toJson() => {
    "phone": phone,
    "deviceId": deviceId,
    "platform": platform,
  };
}
