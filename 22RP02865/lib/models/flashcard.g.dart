// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flashcard.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FlashcardAdapter extends TypeAdapter<Flashcard> {
  @override
  final int typeId = 5;

  @override
  Flashcard read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Flashcard(
      id: fields[0] as String,
      question: fields[1] as String,
      answer: fields[2] as String,
      subject: fields[3] as String,
      hint: fields[4] as String?,
      createdAt: fields[5] as DateTime?,
      lastReviewed: fields[6] as DateTime?,
      reviewCount: fields[7] as int,
      confidenceLevel: fields[8] as double,
      tags: (fields[9] as List).cast<String>(),
      isFavorite: fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Flashcard obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.question)
      ..writeByte(2)
      ..write(obj.answer)
      ..writeByte(3)
      ..write(obj.subject)
      ..writeByte(4)
      ..write(obj.hint)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.lastReviewed)
      ..writeByte(7)
      ..write(obj.reviewCount)
      ..writeByte(8)
      ..write(obj.confidenceLevel)
      ..writeByte(9)
      ..write(obj.tags)
      ..writeByte(10)
      ..write(obj.isFavorite);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlashcardAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FlashcardDeckAdapter extends TypeAdapter<FlashcardDeck> {
  @override
  final int typeId = 6;

  @override
  FlashcardDeck read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FlashcardDeck(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      subject: fields[3] as String,
      flashcardIds: (fields[4] as List).cast<String>(),
      createdAt: fields[5] as DateTime?,
      lastStudied: fields[6] as DateTime?,
      totalCards: fields[7] as int,
      masteredCards: fields[8] as int,
      isPublic: fields[9] as bool,
      createdBy: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, FlashcardDeck obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.subject)
      ..writeByte(4)
      ..write(obj.flashcardIds)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.lastStudied)
      ..writeByte(7)
      ..write(obj.totalCards)
      ..writeByte(8)
      ..write(obj.masteredCards)
      ..writeByte(9)
      ..write(obj.isPublic)
      ..writeByte(10)
      ..write(obj.createdBy);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlashcardDeckAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
