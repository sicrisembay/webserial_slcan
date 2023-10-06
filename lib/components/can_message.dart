const String kStrCan = 'CAN';
const String kStrCanFd = 'CAN-FD';

enum CanType {
  CAN,
  CANFD,
}

enum CanIdType {
  BASE,
  EXTENDED,
}

enum CanNominalRate {
  NRATE250,
  NRATE500,
  NRATE1000,
}
