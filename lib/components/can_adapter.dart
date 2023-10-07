import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:isolate_manager/isolate_manager.dart';
import 'package:serial/serial.dart';
import 'package:webserial_slcan/components/can_message.dart';
import 'package:webserial_slcan/globals.dart';

const int _bufferSize = 8192;

@pragma('vm:entry-point')
void isolateReceiveSerial(dynamic params) async {
  // TODO: final controller = IsolateManagerController<Uint8List, int>(params);
  while (true) {
    final result = await canAdapter!.reader.read();
    canAdapter!.parse(result.value);
    //TODO: controller.sendResult(result.value);
    if (canAdapter!.isRunning() == false) {
      break;
    }
  }
  int retry = 0;
  while (true) {
    retry++;
    canAdapter?.reader.releaseLock();
    await Future.delayed(const Duration(seconds: 1));
    try {
      await canAdapter?.port.close();
    } catch (e) {
      if (retry <= 5) {
        continue; // retry
      } else {
        break;
      }
    }
    break;
  }
}

class CanAdapter {
  final SerialPort port;
  bool _running = false;
  CanType? type;
  CanIdType? idType;
  CanNominalRate? nominalRate;
  final _controller = StreamController<CanMessage>.broadcast();
  Stream<CanMessage> get stream => _controller.stream;
  final Uint8List _buffer = Uint8List(_bufferSize);
  int _wrPtr = 0;
  int _rdPtr = 0;
  final IsolateManager _isolateManager =
      IsolateManager<Uint8List, int>.createOwnIsolate(isolateReceiveSerial,
          isDebug: true);
  late ReadableStreamReader _reader;
  ReadableStreamReader get reader => _reader;

  CanAdapter({required this.port}) {
    _reader = port.readable.reader;
  }

  Future<bool> connect({
    CanType type = CanType.can,
    CanIdType idType = CanIdType.base,
    CanNominalRate nRate = CanNominalRate.nRate1000,
  }) async {
    this.type = type;
    this.idType = idType;
    nominalRate = nRate;
    _running = true;
    _isolateManager.start();

    switch (this.type) {
      case CanType.can:
        {
          switch (nominalRate) {
            case CanNominalRate.nRate250:
              {
                /* 'S5' + CR */
                await _transmit(Uint8List.fromList([0x53, 0x35, cr]));
                break;
              }
            case CanNominalRate.nRate500:
              {
                /* 'S6' + CR */
                await _transmit(Uint8List.fromList([0x53, 0x36, cr]));
                break;
              }
            case CanNominalRate.nRate1000:
              {
                /* 'S8' + CR */
                await _transmit(Uint8List.fromList([0x53, 0x38, cr]));
                break;
              }
            default:
              {
                /* Default: 250kbps */
                /* 'S5' + CR */
                await _transmit(Uint8List.fromList([0x53, 0x35, cr]));
                break;
              }
          }
          // Connect: 'O' + CR
          await _transmit(Uint8List.fromList([0x4F, cr]));
          break;
        }
      case CanType.canFd:
        {
          if (kDebugMode) print('CAN-FD is not yet supported!');
          break;
        }
      default:
        {
          break;
        }
    }

    return true;
  }

  Future<void> disconnect() async {
    _running = false;
    // Close channel
    await _transmit(Uint8List.fromList([0x43, cr])); // 'C' + cr
    // workaround for reader to return its promise
    await _transmit(Uint8List.fromList([0x56, cr]));
  }

  bool isRunning() {
    return _running;
  }

  Future<void> transmit(CanMessage msg) async {
    switch (msg.canType) {
      case CanType.can:
        {
          switch (msg.idType) {
            case CanIdType.base:
              {
                var msgIdHex =
                    msg.id.toRadixString(16).padLeft(3, '0').codeUnits;
                var dlcHex = msg.data.length.toRadixString(16).codeUnits;
                Uint8List packet = Uint8List(5 + 2 * msg.data.length + 1);
                packet[0] = 0x74; // t
                packet[1] = msgIdHex[0];
                packet[2] = msgIdHex[1];
                packet[3] = msgIdHex[2];
                packet[4] = dlcHex[0];
                for (int i = 0; i < msg.data.length; i++) {
                  var data =
                      msg.data[i].toRadixString(16).padLeft(2, '0').codeUnits;
                  packet[5 + (i * 2)] = data[0];
                  packet[6 + (i * 2)] = data[1];
                }
                packet[packet.length - 1] = cr;
                _transmit(packet);
                break;
              }
            case CanIdType.extended:
              {
                if (kDebugMode) print('Not yet supported');
                break;
              }
            default:
              {
                if (kDebugMode) print('Unknown id type');
                break;
              }
          }
          break;
        }
      case CanType.canFd:
        {
          if (kDebugMode) print('Not yet supported');
          break;
        }
      default:
        {
          if (kDebugMode) print('Unknown format');
          break;
        }
    }
  }

  Future<void> _transmit(Uint8List data) async {
    if (data.isEmpty) return;
    final serialPort = port;
    final writer = serialPort.writable.writer;
    await writer.ready;
    await writer.write(data);
    await writer.ready;
    await writer.close();
  }

  bool parse(Uint8List data) {
    for (int i = 0; i < data.length; i++) {
      _buffer[_wrPtr] = data[i];
      _wrPtr = (_wrPtr + 1) % _bufferSize;
    }
    // parse
    int idx = _rdPtr;
    int length = 0;
    while (idx != _wrPtr) {
      /* Find CR (0x0D) delimiter */
      if (_buffer[idx] != cr) {
        idx = (idx + 1) % _bufferSize;
        continue;
      }
      idx = (idx + 1) % _bufferSize;
      /*
        * It will only reach here if CR delimiter is received.
        * Calculate length (including CR)
        */
      if (idx >= _rdPtr) {
        length = idx - _rdPtr;
      } else {
        length = _bufferSize - _rdPtr + idx;
      }
      if (length <= 1) {
        /* No data (it's just CR) */
        _rdPtr = idx;
        continue;
      }
      Uint8List data = Uint8List(length - 1);
      for (int i = 0; i < data.length; i++) {
        data[i] = _buffer[(_rdPtr + i) % _bufferSize];
      }
      _parseFrame(data);
      /* Done with this packet */
      _rdPtr = idx;
    }

    return true;
  }

  void _parseFrame(Uint8List buffer) {
    switch (buffer[0]) {
      case 0x74: //'t'
        {
          /* CAN Standard */
          final int msgId =
              int.parse(String.fromCharCodes(buffer.sublist(1, 4)), radix: 16);
          final int dlc = int.parse(String.fromCharCode(buffer[4]), radix: 16);
          Uint8List data = Uint8List(dlc);
          for (int i = 0; i < dlc; i++) {
            int start = 5 + (2 * i);
            int end = 7 + (2 * i);
            data[i] = int.parse(
                String.fromCharCodes(buffer.sublist(start, end)),
                radix: 16);
          }
          if (kDebugMode) {
            print("msgId: $msgId len: $dlc data: $data");
          }
          _controller.sink.add(CanMessage(
              id: msgId,
              canType: CanType.can,
              idType: CanIdType.base,
              length: dlc,
              data: data));
          break;
        }
      default:
        {
          break;
        }
    }
  }
}
