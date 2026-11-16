// To parse this JSON data, do
//
//     final verifyOtpResModel = verifyOtpResModelFromJson(jsonString);

import 'dart:convert';

VerifyOtpResModel verifyOtpResModelFromJson(String str) => VerifyOtpResModel.fromJson(json.decode(str));

String verifyOtpResModelToJson(VerifyOtpResModel data) => json.encode(data.toJson());

class VerifyOtpResModel {
    String? message;
    int? code;
    bool? error;
    Data? data;

    VerifyOtpResModel({
        this.message,
        this.code,
        this.error,
        this.data,
    });

    factory VerifyOtpResModel.fromJson(Map<String, dynamic> json) => VerifyOtpResModel(
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
    Customer? customer;
    String? token;
    bool? isSubCustomer;
    Permissions? permissions;

    Data({
        this.customer,
        this.token,
        this.isSubCustomer,
        this.permissions,
    });

    factory Data.fromJson(Map<String, dynamic> json) => Data(
        customer: json["customer"] == null ? null : Customer.fromJson(json["customer"]),
        token: json["token"],
        isSubCustomer: json["isSubCustomer"],
        permissions: json["permissions"] == null ? null : Permissions.fromJson(json["permissions"]),
    );

    Map<String, dynamic> toJson() => {
        "customer": customer?.toJson(),
        "token": token,
        "isSubCustomer": isSubCustomer,
        "permissions": permissions?.toJson(),
    };
}

class Customer {
    Permissions? subcustomerPermissions;
    Approval? accountsApproval;
    Approval? ownerApproval;
    dynamic rejectedBy;
    dynamic rejectedAt;
    String? id;
    String? name;
    String? phone;
    String? companyName;
    String? whatsappNumber;
    int? landlineNumber;
    String? email;
    String? state;
    String? city;
    String? address;
    String? pincode;
    String? country;
    String? gstNo;
    String? gstImage;
    String? panNumber;
    String? adharNumber;
    String? adharImage;
    String? panImage;
    String? profilePic;
    String? visitingCard;
    String? entity;
    String? assignedSalesperson;
    dynamic parentCustomerId;
    String? pricingTier;
    String? stockGrade;
    String? accountStatus;
    int? creditLimit;
    String? paymentTerm;
    String? approvalStatus;
    String? deviceId;
    String? deviceName;
    String? webDeviceId;
    String? preferredCourier;
    String? webDeviceName;
    bool? isActive;
    bool? isDisable;
    bool? isDeleted;
    int? date;
    int? month;
    int? year;
    int? createdAt;
    int? updatedAt;
    int? currentBalance;
    String? rejectionReason;
    int? usedBalance;
    String? paymentGrade;
    bool? allowMultiDevice;
    List<LoggedInDevice>? loggedInDevices;

    Customer({
        this.subcustomerPermissions,
        this.accountsApproval,
        this.ownerApproval,
        this.rejectedBy,
        this.rejectedAt,
        this.id,
        this.name,
        this.phone,
        this.companyName,
        this.whatsappNumber,
        this.landlineNumber,
        this.email,
        this.state,
        this.city,
        this.address,
        this.pincode,
        this.country,
        this.gstNo,
        this.gstImage,
        this.panNumber,
        this.adharNumber,
        this.adharImage,
        this.panImage,
        this.profilePic,
        this.visitingCard,
        this.entity,
        this.assignedSalesperson,
        this.parentCustomerId,
        this.pricingTier,
        this.stockGrade,
        this.accountStatus,
        this.creditLimit,
        this.paymentTerm,
        this.approvalStatus,
        this.deviceId,
        this.deviceName,
        this.webDeviceId,
        this.preferredCourier,
        this.webDeviceName,
        this.isActive,
        this.isDisable,
        this.isDeleted,
        this.date,
        this.month,
        this.year,
        this.createdAt,
        this.updatedAt,
        this.currentBalance,
        this.rejectionReason,
        this.usedBalance,
        this.paymentGrade,
        this.allowMultiDevice,
        this.loggedInDevices,
    });

    factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        subcustomerPermissions: json["subcustomer_permissions"] == null ? null : Permissions.fromJson(json["subcustomer_permissions"]),
        accountsApproval: json["accounts_approval"] == null ? null : Approval.fromJson(json["accounts_approval"]),
        ownerApproval: json["owner_approval"] == null ? null : Approval.fromJson(json["owner_approval"]),
        rejectedBy: json["rejected_by"],
        rejectedAt: json["rejected_at"],
        id: json["_id"],
        name: json["name"],
        phone: json["phone"],
        companyName: json["company_name"],
        whatsappNumber: json["whatsapp_number"],
        landlineNumber: json["landline_number"],
        email: json["email"],
        state: json["state"],
        city: json["city"],
        address: json["address"],
        pincode: json["pincode"],
        country: json["country"],
        gstNo: json["gst_no"],
        gstImage: json["gst_image"],
        panNumber: json["pan_number"],
        adharNumber: json["adhar_number"],
        adharImage: json["adhar_image"],
        panImage: json["pan_image"],
        profilePic: json["profilePic"],
        visitingCard: json["visiting_card"],
        entity: json["entity"],
        assignedSalesperson: json["assigned_salesperson"],
        parentCustomerId: json["parent_customer_id"],
        pricingTier: json["pricing_tier"],
        stockGrade: json["stock_grade"],
        accountStatus: json["account_status"],
        creditLimit: json["credit_limit"],
        paymentTerm: json["payment_term"],
        approvalStatus: json["approval_status"],
        deviceId: json["device_id"],
        deviceName: json["device_name"],
        webDeviceId: json["web_device_id"],
        preferredCourier: json["preferred_courier"],
        webDeviceName: json["web_device_name"],
        isActive: json["is_active"],
        isDisable: json["isDisable"],
        isDeleted: json["isDeleted"],
        date: json["date"],
        month: json["month"],
        year: json["year"],
        createdAt: json["createdAt"],
        updatedAt: json["updatedAt"],
        currentBalance: json["current_balance"],
        rejectionReason: json["rejection_reason"],
        usedBalance: json["used_balance"],
        paymentGrade: json["payment_grade"],
        allowMultiDevice: json["allow_multi_device"],
        loggedInDevices: json["logged_in_devices"] == null ? [] : List<LoggedInDevice>.from(json["logged_in_devices"]!.map((x) => LoggedInDevice.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "subcustomer_permissions": subcustomerPermissions?.toJson(),
        "accounts_approval": accountsApproval?.toJson(),
        "owner_approval": ownerApproval?.toJson(),
        "rejected_by": rejectedBy,
        "rejected_at": rejectedAt,
        "_id": id,
        "name": name,
        "phone": phone,
        "company_name": companyName,
        "whatsapp_number": whatsappNumber,
        "landline_number": landlineNumber,
        "email": email,
        "state": state,
        "city": city,
        "address": address,
        "pincode": pincode,
        "country": country,
        "gst_no": gstNo,
        "gst_image": gstImage,
        "pan_number": panNumber,
        "adhar_number": adharNumber,
        "adhar_image": adharImage,
        "pan_image": panImage,
        "profilePic": profilePic,
        "visiting_card": visitingCard,
        "entity": entity,
        "assigned_salesperson": assignedSalesperson,
        "parent_customer_id": parentCustomerId,
        "pricing_tier": pricingTier,
        "stock_grade": stockGrade,
        "account_status": accountStatus,
        "credit_limit": creditLimit,
        "payment_term": paymentTerm,
        "approval_status": approvalStatus,
        "device_id": deviceId,
        "device_name": deviceName,
        "web_device_id": webDeviceId,
        "preferred_courier": preferredCourier,
        "web_device_name": webDeviceName,
        "is_active": isActive,
        "isDisable": isDisable,
        "isDeleted": isDeleted,
        "date": date,
        "month": month,
        "year": year,
        "createdAt": createdAt,
        "updatedAt": updatedAt,
        "current_balance": currentBalance,
        "rejection_reason": rejectionReason,
        "used_balance": usedBalance,
        "payment_grade": paymentGrade,
        "allow_multi_device": allowMultiDevice,
        "logged_in_devices": loggedInDevices == null ? [] : List<dynamic>.from(loggedInDevices!.map((x) => x.toJson())),
    };
}

class Approval {
    bool? status;
    String? approvedBy;
    DateTime? approvedAt;

    Approval({
        this.status,
        this.approvedBy,
        this.approvedAt,
    });

    factory Approval.fromJson(Map<String, dynamic> json) => Approval(
        status: json["status"],
        approvedBy: json["approved_by"],
        approvedAt: json["approved_at"] == null ? null : DateTime.parse(json["approved_at"]),
    );

    Map<String, dynamic> toJson() => {
        "status": status,
        "approved_by": approvedBy,
        "approved_at": approvedAt?.toIso8601String(),
    };
}

class LoggedInDevice {
    String? deviceId;
    String? deviceName;
    String? platform;
    DateTime? loggedInAt;
    DateTime? lastActive;
    String? id;

    LoggedInDevice({
        this.deviceId,
        this.deviceName,
        this.platform,
        this.loggedInAt,
        this.lastActive,
        this.id,
    });

    factory LoggedInDevice.fromJson(Map<String, dynamic> json) => LoggedInDevice(
        deviceId: json["device_id"],
        deviceName: json["device_name"],
        platform: json["platform"],
        loggedInAt: json["logged_in_at"] == null ? null : DateTime.parse(json["logged_in_at"]),
        lastActive: json["last_active"] == null ? null : DateTime.parse(json["last_active"]),
        id: json["_id"],
    );

    Map<String, dynamic> toJson() => {
        "device_id": deviceId,
        "device_name": deviceName,
        "platform": platform,
        "logged_in_at": loggedInAt?.toIso8601String(),
        "last_active": lastActive?.toIso8601String(),
        "_id": id,
    };
}

class Permissions {
    bool? allowOrder;
    bool? showQuantity;
    bool? allowCart;
    bool? hidePrice;
    bool? allowMultiDevice;

    Permissions({
        this.allowOrder,
        this.showQuantity,
        this.allowCart,
        this.hidePrice,
        this.allowMultiDevice,
    });

    factory Permissions.fromJson(Map<String, dynamic> json) => Permissions(
        allowOrder: json["allow_order"],
        showQuantity: json["show_quantity"],
        allowCart: json["allow_cart"],
        hidePrice: json["hide_price"],
        allowMultiDevice: json["allow_multi_device"],
    );

    Map<String, dynamic> toJson() => {
        "allow_order": allowOrder,
        "show_quantity": showQuantity,
        "allow_cart": allowCart,
        "hide_price": hidePrice,
        "allow_multi_device": allowMultiDevice,
    };
}
