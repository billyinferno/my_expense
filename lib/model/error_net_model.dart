// To parse this JSON data, do
//
//     final netErrorModel = netErrorModelFromJson(jsonString);

import 'dart:convert';

NetErrorModel netErrorModelFromJson(String str) => NetErrorModel.fromJson(json.decode(str));

String netErrorModelToJson(NetErrorModel data) => json.encode(data.toJson());

class NetErrorModel {
    final int statusCode;
    final String error;
    final List<NetMessages> message;
    final List<NetMessages> data;

    NetErrorModel({
        required this.statusCode,
        required this.error,
        required this.message,
        required this.data,
    });

    factory NetErrorModel.fromJson(Map<String, dynamic> json) => NetErrorModel(
        statusCode: json["statusCode"],
        error: json["error"],
        message: List<NetMessages>.from(json["message"].map((x) => NetMessages.fromJson(x))),
        data: List<NetMessages>.from(json["data"].map((x) => NetMessages.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "statusCode": statusCode,
        "error": error,
        "message": List<dynamic>.from(message.map((x) => x.toJson())),
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
    };
}

class NetMessages {
    final List<Message> messages;

    NetMessages({
        required this.messages,
    });

    factory NetMessages.fromJson(Map<String, dynamic> json) => NetMessages(
        messages: List<Message>.from(json["messages"].map((x) => Message.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "messages": List<dynamic>.from(messages.map((x) => x.toJson())),
    };
}

class Message {
    final String id;
    final String message;

    Message({
        required this.id,
        required this.message,
    });

    factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json["id"],
        message: json["message"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "message": message,
    };
}
