// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_room.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChatRoomAdapter extends TypeAdapter<ChatRoom> {
  @override
  final int typeId = 13;

  @override
  ChatRoom read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatRoom(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      participants: (fields[3] as List).cast<String>(),
      type: fields[4] as ChatRoomType,
      createdBy: fields[5] as String,
      createdAt: fields[6] as DateTime,
      lastMessageTime: fields[7] as DateTime,
      lastMessage: fields[8] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ChatRoom obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.participants)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.createdBy)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.lastMessageTime)
      ..writeByte(8)
      ..write(obj.lastMessage);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatRoomAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ChatRoomTypeAdapter extends TypeAdapter<ChatRoomType> {
  @override
  final int typeId = 12;

  @override
  ChatRoomType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ChatRoomType.direct;
      case 1:
        return ChatRoomType.group;
      default:
        return ChatRoomType.direct;
    }
  }

  @override
  void write(BinaryWriter writer, ChatRoomType obj) {
    switch (obj) {
      case ChatRoomType.direct:
        writer.writeByte(0);
        break;
      case ChatRoomType.group:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatRoomTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
