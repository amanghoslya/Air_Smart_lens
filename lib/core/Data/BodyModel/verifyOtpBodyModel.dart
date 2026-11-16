// To parse this JSON data, do
//
//     final verifyOtpBodyModel = verifyOtpBodyModelFromJson(jsonString);

import 'dart:convert';

VerifyOtpBodyModel verifyOtpBodyModelFromJson(String str) =>
    VerifyOtpBodyModel.fromJson(json.decode(str));

String verifyOtpBodyModelToJson(VerifyOtpBodyModel data) =>
    json.encode(data.toJson());

class VerifyOtpBodyModel {
  String? phone;
  String? otp;
  String? deviceId;
  String? deviceName;
  String? platform;

  VerifyOtpBodyModel({
    this.phone,
    this.otp,
    this.deviceId,
    this.deviceName,
    this.platform,
  });

  factory VerifyOtpBodyModel.fromJson(Map<String, dynamic> json) =>
      VerifyOtpBodyModel(
        phone: json["phone"],
        otp: json["otp"],
        deviceId: json["deviceId"],
        deviceName: json["deviceName"],
        platform: json["platform"],
      );

  Map<String, dynamic> toJson() => {
    "phone": phone,
    "otp": otp,
    "deviceId": deviceId,
    "deviceName": deviceName,
    "platform": platform,
  };
}
