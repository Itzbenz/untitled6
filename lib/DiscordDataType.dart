//Discord Data Stucture
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class Guild {
  String id;
  String name;
  List<Channel> channels = [];

  Guild(this.id, this.name);

  String getShortName() {
    if (name.length > 2) {
      return name.substring(0, 2);
    }
    return name;
  }

  Widget createWidget() {
    return CircleAvatar(
      child: Text(getShortName()),
    );
  }

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Guild) return false;
    return id == other.id;
  }
}

class Channel {
  String id;
  String name;
  String csvPath;

  Channel(this.id, this.name, this.csvPath);

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Channel) {
      return false;
    }
    return id == other.id;
  }

  Future<List<DiscordMessage>> getMessages() async {
    final file = File(csvPath);
    final lines = await file.readAsLines();
    List<DiscordMessage> messages = [];
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i];
      final parts = line.split(',');
      if (parts.length != 4) continue;
      String id = parts[0];
      DateTime timestamp = DateTime.fromMillisecondsSinceEpoch(0);
      try {
        timestamp = DateTime.parse(parts[1]);
      } catch (e) {
        print(e);
        continue;
      }
      String content = parts[2];
      List<Uri> attachments = [];
      for (int j = 3; j < parts.length; j++) {
        Uri? attachment = Uri.tryParse(parts[j]);
        if (attachment != null && attachment.toString().isNotEmpty) {
          attachments.add(attachment);
        } else {}
      }
      messages.add(DiscordMessage(id, timestamp, content, attachments));
    }
    return messages;
  }
}

class DiscordMessage {
  String id;
  String? content;
  DateTime timestamp;
  List<Uri> attachments = [];

  DiscordMessage(this.id, this.timestamp, this.content, this.attachments);

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! DiscordMessage) {
      return false;
    }
    return id == other.id;
  }

  List<types.Message> createMessage(types.User author) {
    List<types.Message> messages = [];
    if (attachments.isNotEmpty) {
      for (Uri attachment in attachments) {
        messages.add(types.ImageMessage.fromPartial(
          author: author,
          id: id,
          partialImage: types.PartialImage(
            name: attachment.pathSegments.last,
            uri: attachment.toString(),
            size: 0,
          ),
        ));
      }
    } else if (content != null) {
      String text = content!;
      messages.add(types.TextMessage.fromPartial(
        author: author,
        id: id,
        partialText: types.PartialText(
          text: text,
        ),
      ));
    }
    return messages;
  }
}
