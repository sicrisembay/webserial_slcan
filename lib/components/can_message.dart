import 'dart:typed_data';

const String kStrCan = 'CAN';
const String kStrCanFd = 'CAN-FD';
const int cr = 0x0D;

enum CanType {
  can,
  canFd,
}

enum CanIdType {
  base,
  extended,
}

enum CanNominalRate {
  nRate250,
  nRate500,
  nRate1000,
}

class CanMessage {
  final int id;
  final CanType canType;
  final CanIdType idType;
  final int length;
  final Uint8List data;

  CanMessage(
      {required this.id,
      required this.canType,
      required this.idType,
      required this.length,
      required this.data});
}
