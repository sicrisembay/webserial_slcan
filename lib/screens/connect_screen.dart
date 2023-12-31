import 'dart:html';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:multi_dropdown/multiselect_dropdown.dart';
import 'package:serial/serial.dart';
import 'package:webserial_slcan/components/bottom_button.dart';
import 'package:webserial_slcan/components/can_adapter.dart';
import 'package:webserial_slcan/components/can_message.dart';
import 'package:webserial_slcan/globals.dart';
import 'package:webserial_slcan/screens/main_screen.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});
  static const String id = "ConnectScreen";

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  static const String _idBase = '11';
  static const String _idExtended = '29';

  static const List<ValueItem> _canTypeList = [
    ValueItem(label: kStrCan),
    ValueItem(label: kStrCanFd),
  ];
  static const List<ValueItem> _canIdFormatList = [
    ValueItem(label: '11-bit', value: _idBase),
    ValueItem(label: '29-bit', value: _idExtended),
  ];
  static const List<ValueItem> _canRateList = [
    ValueItem(label: '250kps'),
    ValueItem(label: '500kps'),
    ValueItem(label: '1Mbps'),
    ValueItem(label: '2Mbps'),
    ValueItem(label: '5Mps'),
    ValueItem(label: '8Mps'),
  ];
  ValueItem _canType = _canTypeList[0];
  final ValueItem _idFormat = _canIdFormatList[0];
  ValueItem _nominalBitRate = _canRateList[2];
  final ValueItem _dataBitRate = _canRateList[3];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(
                height: 20.0,
              ),
              MultiSelectDropDown(
                onOptionSelected: (List<ValueItem> selectedItem) {
                  setState(() {
                    _canType = selectedItem[0];
                  });
                },
                options: _canTypeList,
                selectionType: SelectionType.single,
                selectedOptions: [_canType],
              ),
              const SizedBox(
                height: 20.0,
              ),
              MultiSelectDropDown(
                onOptionSelected: (List<ValueItem> selectedItem) {},
                options: _canIdFormatList,
                selectionType: SelectionType.single,
                selectedOptions: [_idFormat],
              ),
              const SizedBox(
                height: 20.0,
              ),
              MultiSelectDropDown(
                onOptionSelected: (List<ValueItem> selectedItem) {
                  setState(() {
                    _nominalBitRate = selectedItem[0];
                  });
                },
                options: [
                  _canRateList[0],
                  _canRateList[1],
                  _canRateList[2],
                  if (_canType.label == kStrCanFd) _canRateList[3],
                  if (_canType.label == kStrCanFd) _canRateList[4],
                  if (_canType.label == kStrCanFd) _canRateList[5],
                ],
                selectionType: SelectionType.single,
                selectedOptions: [_nominalBitRate],
              ),
              const SizedBox(
                height: 20.0,
              ),
              if (_canType.label == kStrCanFd)
                MultiSelectDropDown(
                  onOptionSelected: (List<ValueItem> selectedItem) {},
                  options: _canRateList,
                  selectionType: SelectionType.single,
                  selectedOptions: [_dataBitRate],
                ),
              if (_canType.label == kStrCanFd)
                const SizedBox(
                  height: 20.0,
                ),
              BottomButton(
                  label: 'CONNECT',
                  onTap: () async {
                    CanType canType = CanType.can;
                    CanIdType idType = CanIdType.base;
                    CanNominalRate nominalRate = CanNominalRate.nRate1000;
                    switch (_canType.label) {
                      case kStrCan:
                        {
                          break;
                        }
                      default:
                        {
                          canType = CanType.can;
                        }
                    }
                    try {
                      final port = await window.navigator.serial.requestPort();
                      await port.open(baudRate: 115200);
                      canAdapter = CanAdapter(port: port);
                      await canAdapter?.connect(
                          type: canType, idType: idType, nRate: nominalRate);
                      setState(() {
                        Navigator.pushNamed(context, MainScreen.id);
                      });
                    } catch (e) {
                      if (kDebugMode) print(e);
                    }
                  }),
            ],
          ),
        ),
      ),
    );
  }
}
