// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BookAdapter extends TypeAdapter<Book> {
  @override
  final int typeId = 0;

  @override
  Book read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Book(
      id: fields[0] as String,
      title: fields[1] as String,
      authors: (fields[2] as List).cast<String>(),
      description: fields[3] as String?,
      coverImage: fields[4] as String?,
      categories: (fields[5] as List).cast<String>(),
      language: fields[6] as String?,
      pageCount: fields[7] as int?,
      publisher: fields[8] as String?,
      publishedDate: fields[9] as DateTime?,
      averageRating: fields[10] as double?,
      ratingsCount: fields[11] as int?,
      previewLink: fields[12] as String?,
      downloadLink: fields[13] as String?,
      format: fields[14] as String?,
      source: fields[15] as String?,
      isDownloaded: fields[16] as bool,
      localPath: fields[17] as String?,
      isFavorite: fields[18] as bool,
      lastReadAt: fields[19] as DateTime?,
      lastPageRead: fields[20] as int?,
      readingProgress: fields[21] as double?,
      bookmarks: (fields[22] as List).cast<String>(),
      createdAt: fields[23] as DateTime?,
      updatedAt: fields[24] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Book obj) {
    writer
      ..writeByte(25)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.authors)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.coverImage)
      ..writeByte(5)
      ..write(obj.categories)
      ..writeByte(6)
      ..write(obj.language)
      ..writeByte(7)
      ..write(obj.pageCount)
      ..writeByte(8)
      ..write(obj.publisher)
      ..writeByte(9)
      ..write(obj.publishedDate)
      ..writeByte(10)
      ..write(obj.averageRating)
      ..writeByte(11)
      ..write(obj.ratingsCount)
      ..writeByte(12)
      ..write(obj.previewLink)
      ..writeByte(13)
      ..write(obj.downloadLink)
      ..writeByte(14)
      ..write(obj.format)
      ..writeByte(15)
      ..write(obj.source)
      ..writeByte(16)
      ..write(obj.isDownloaded)
      ..writeByte(17)
      ..write(obj.localPath)
      ..writeByte(18)
      ..write(obj.isFavorite)
      ..writeByte(19)
      ..write(obj.lastReadAt)
      ..writeByte(20)
      ..write(obj.lastPageRead)
      ..writeByte(21)
      ..write(obj.readingProgress)
      ..writeByte(22)
      ..write(obj.bookmarks)
      ..writeByte(23)
      ..write(obj.createdAt)
      ..writeByte(24)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
