import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:ndef/ndef.dart' as ndef;
import 'dart:typed_data';
import 'dart:convert';

// void main() {
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'NFC Reader/Writer (NDEF + ISO15693)',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//         visualDensity: VisualDensity.adaptivePlatformDensity,
//       ),
//       home: NFCScreen(),
//     );
//   }
// }

class NFCScreen extends StatefulWidget {
  @override
  _NFCScreenState createState() => _NFCScreenState();
}

class _NFCScreenState extends State<NFCScreen> {
  NFCAvailability _availability = NFCAvailability.not_supported;
  NFCTag? _tag;
  String _result = '';
  List<ndef.NDEFRecord> _records = [];
  bool _isReading = false;
  bool _isWriting = false;
  String _tagType = '';

  // Controllers for writing data
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _wifiSSIDController = TextEditingController();
  final TextEditingController _wifiPasswordController = TextEditingController();
  final TextEditingController _rawDataController = TextEditingController();
  final TextEditingController _blockAddressController =
      TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    _checkNFCAvailability();
  }

  Future<void> _checkNFCAvailability() async {
    NFCAvailability availability;
    try {
      availability = await FlutterNfcKit.nfcAvailability;
    } catch (e) {
      availability = NFCAvailability.not_supported;
    }
    setState(() {
      _availability = availability;
    });
  }

  Future<void> _scanTag() async {
    if (_availability != NFCAvailability.available) {
      _showSnackBar('NFC is not available');
      return;
    }

    setState(() {
      _isReading = true;
      _result = 'Scanning for NFC tag...';
      _records.clear();
      _tagType = '';
    });

    try {
      // Poll for NFC tags
      NFCTag tag = await FlutterNfcKit.poll(
        timeout: Duration(seconds: 15),
        iosMultipleTagMessage: "Multiple tags found, please select one",
        iosAlertMessage: "Scan your NFC tag",
      );

      setState(() {
        _tag = tag;
        _tagType = tag.type.toString();
        _result = 'Tag found!\n';
        _result += 'Type: ${tag.type}\n';
        _result += 'ID: ${tag.id}\n';
        _result += 'Standard: ${tag.standard}\n';
        _result += 'NDEF Available: ${tag.ndefAvailable}\n';
        _result += 'NDEF Writable: ${tag.ndefWritable}\n';
        _result += 'NDEF Can Make Read Only: ${tag.ndefCanMakeReadOnly}\n';
        _result += 'NDEF Capacity: ${tag.ndefCapacity}\n';
        _result += 'NDEF Type: ${tag.ndefType}\n\n';
      });

      // Handle different tag types
      if (tag.type?.toString().toUpperCase().contains('ISO15693') == true) {
        await _handleISO15693Tag(tag);
      } else if (tag.ndefAvailable == true) {
        await _handleNDEFTag(tag);
      } else {
        setState(() {
          _result +=
              'This tag type (${tag.type}) is not fully supported by this app.\n';
          _result += 'You can try raw data operations for ISO15693 tags.';
        });
      }
    } catch (e) {
      setState(() {
        _result = 'Error reading tag: $e';
      });
    } finally {
      setState(() {
        _isReading = false;
      });
      // Finish NFC session
      try {
        await FlutterNfcKit.finish();
      } catch (e) {
        print('Error finishing NFC session: $e');
      }
    }
  }

  Future<void> _handleNDEFTag(NFCTag tag) async {
    try {
      // Read NDEF records
      List<ndef.NDEFRecord> records = await FlutterNfcKit.readNDEFRecords();

      setState(() {
        _records = records;
        _result += 'NDEF Records found: ${_records.length}\n';

        // Add detailed record information
        for (int i = 0; i < records.length; i++) {
          _result += '\nRecord ${i + 1}:\n';
          _result += '  Type: ${_getRecordTypeString(records[i])}\n';
          _result += '  TNF: ${records[i].tnf}\n';
          _result += '  Content: ${_getRecordInfo(records[i])}\n';
        }
      });
    } catch (e) {
      setState(() {
        _result += 'Error reading NDEF records: $e\n';
      });
    }
  }

  Future<void> _handleISO15693Tag(NFCTag tag) async {
    setState(() {
      _result += '📡 ISO15693 Tag Detected\n';
      _result += 'This tag uses raw block-based storage.\n';
      _result += 'NDEF operations are not supported.\n\n';
    });

    try {
      // Try to read system information if available
      setState(() {
        _result += 'Attempting to read tag information...\n';
      });

      // For ISO15693, we'll try to read the first few blocks to see what data is there
      await _readISO15693Blocks(0, 4); // Read first 4 blocks
    } catch (e) {
      setState(() {
        _result += 'Error reading ISO15693 tag: $e\n';
      });
    }
  }

  Future<void> _readISO15693Blocks(int startBlock, int numBlocks) async {
    setState(() {
      _result +=
          '\n🔍 Reading ISO15693 blocks $startBlock to ${startBlock + numBlocks - 1}:\n';
    });

    try {
      for (int i = 0; i < numBlocks; i++) {
        int blockNum = startBlock + i;
        try {
          // Attempt to read block using transceive
          Uint8List command = Uint8List.fromList([
            0x02, // Flags (addressed mode)
            0x20, // Read Single Block command
            blockNum, // Block number
          ]);

          Uint8List response = await FlutterNfcKit.transceive(command);

          setState(() {
            _result += 'Block $blockNum: ${_bytesToHex(response)}\n';
            _result += '  ASCII: ${_bytesToAscii(response)}\n';
          });
        } catch (blockError) {
          setState(() {
            _result += 'Block $blockNum: Error - $blockError\n';
          });
        }
      }
    } catch (e) {
      setState(() {
        _result += 'Error during block read: $e\n';
      });
    }
  }

  Future<void> _writeISO15693Block() async {
    if (_availability != NFCAvailability.available) {
      _showSnackBar('NFC is not available');
      return;
    }

    if (_rawDataController.text.trim().isEmpty) {
      _showSnackBar('Please enter data to write');
      return;
    }

    int blockAddress;
    try {
      blockAddress = int.parse(_blockAddressController.text.trim());
    } catch (e) {
      _showSnackBar('Invalid block address');
      return;
    }

    setState(() {
      _isWriting = true;
      _result = 'Scanning for ISO15693 tag to write...';
    });

    try {
      NFCTag tag = await FlutterNfcKit.poll(
        timeout: Duration(seconds: 15),
        iosMultipleTagMessage: "Multiple tags found",
        iosAlertMessage: "Scan ISO15693 tag to write",
      );

      if (tag.type?.toString().toUpperCase().contains('ISO15693') != true) {
        setState(() {
          _result =
              'Error: This operation requires an ISO15693 tag.\nDetected: ${tag.type}';
        });
        return;
      }

      setState(() {
        _result = 'ISO15693 tag detected: ${tag.type}\n';
        _result += 'Writing to block $blockAddress...\n';
      });

      // Convert text to bytes
      List<int> dataBytes;
      String inputData = _rawDataController.text.trim();

      if (inputData.startsWith('0x') || _isHexString(inputData)) {
        // Handle hex input
        String hexData = inputData.replaceAll('0x', '').replaceAll(' ', '');
        dataBytes = _hexToBytes(hexData);
      } else {
        // Handle text input
        dataBytes = utf8.encode(inputData);
      }

      // ISO15693 blocks are typically 4 bytes, pad or truncate as needed
      while (dataBytes.length < 4) {
        dataBytes.add(0x00);
      }
      if (dataBytes.length > 4) {
        dataBytes = dataBytes.take(4).toList();
      }

      // Write Single Block command
      Uint8List command = Uint8List.fromList([
        0x02, // Flags
        0x21, // Write Single Block command
        blockAddress, // Block number
        ...dataBytes, // Data to write
      ]);

      try {
        Uint8List response = await FlutterNfcKit.transceive(command);

        setState(() {
          _result += '✅ Write successful!\n';
          _result +=
              'Block $blockAddress written with: ${_bytesToHex(Uint8List.fromList(dataBytes))}\n';
          _result += 'Response: ${_bytesToHex(response)}\n';
        });

        // Verify by reading back
        await Future.delayed(Duration(milliseconds: 100));
        await _readISO15693Blocks(blockAddress, 1);
      } catch (writeError) {
        setState(() {
          _result += '❌ Write failed: $writeError\n';
        });
      }
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
    } finally {
      setState(() {
        _isWriting = false;
      });
      try {
        await FlutterNfcKit.finish();
      } catch (e) {
        print('Error finishing NFC session: $e');
      }
    }
  }

  Future<void> _readISO15693Tag() async {
    if (_availability != NFCAvailability.available) {
      _showSnackBar('NFC is not available');
      return;
    }

    setState(() {
      _isReading = true;
      _result = 'Scanning for ISO15693 tag...';
    });

    try {
      NFCTag tag = await FlutterNfcKit.poll(
        timeout: Duration(seconds: 15),
        iosMultipleTagMessage: "Multiple tags found",
        iosAlertMessage: "Scan ISO15693 tag to read",
      );

      setState(() {
        _result = 'Tag Type: ${tag.type}\n';
        _result += 'Tag ID: ${tag.id}\n\n';
      });

      if (tag.type?.toString().toUpperCase().contains('ISO15693') == true) {
        await _readISO15693Blocks(0, 8); // Read first 8 blocks
      } else {
        setState(() {
          _result +=
              'This is not an ISO15693 tag.\nUse the regular scan for NDEF tags.';
        });
      }
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
    } finally {
      setState(() {
        _isReading = false;
      });
      try {
        await FlutterNfcKit.finish();
      } catch (e) {
        print('Error finishing NFC session: $e');
      }
    }
  }

  // NDEF writing methods (existing functionality)
  Future<void> _writeNDEF(List<ndef.NDEFRecord> records) async {
    if (_availability != NFCAvailability.available) {
      _showSnackBar('NFC is not available');
      return;
    }

    if (records.isEmpty) {
      _showSnackBar('No records to write');
      return;
    }

    setState(() {
      _isWriting = true;
      _result = 'Scanning for NDEF-compatible tag to write...';
    });

    try {
      NFCTag tag = await FlutterNfcKit.poll(
        timeout: Duration(seconds: 15),
        iosMultipleTagMessage: "Multiple tags found",
        iosAlertMessage: "Scan NDEF-compatible tag to write",
      );

      setState(() {
        _tag = tag;
        _result = 'Tag found: ${tag.type}\nID: ${tag.id}\n';
        _result += 'NDEF Available: ${tag.ndefAvailable}\n';
        _result += 'NDEF Writable: ${tag.ndefWritable}\n';
        _result += 'Writing ${records.length} record(s)...\n';
      });

      if (tag.ndefAvailable == true) {
        if (tag.ndefWritable == true) {
          try {
            await FlutterNfcKit.writeNDEFRecords(records);

            setState(() {
              _result += '\n✅ NDEF records written successfully!\n';
              _result += 'Records written: ${records.length}\n';

              for (int i = 0; i < records.length; i++) {
                _result += '\nWritten Record ${i + 1}:\n';
                _result += '  Type: ${_getRecordTypeString(records[i])}\n';
                _result += '  Content: ${_getRecordInfo(records[i])}\n';
              }
            });
          } catch (writeError) {
            setState(() {
              _result += '\n❌ Error writing records: $writeError';
            });
          }
        } else {
          setState(() {
            _result += '\n❌ Tag is not writable';
          });
        }
      } else {
        setState(() {
          _result += '\n❌ Tag does not support NDEF\n';
          _result +=
              'Try using ISO15693 raw data operations if this is an ISO15693 tag.';
        });
      }
    } catch (e) {
      setState(() {
        _result = 'Error accessing tag: $e';
      });
    } finally {
      setState(() {
        _isWriting = false;
      });
      try {
        await FlutterNfcKit.finish();
      } catch (e) {
        print('Error finishing NFC session: $e');
      }
    }
  }

  void _writeTextRecord() {
    if (_textController.text.trim().isEmpty) {
      _showSnackBar('Please enter text to write');
      return;
    }

    try {
      ndef.NDEFRecord textRecord = ndef.TextRecord(
        text: _textController.text.trim(),
        language: 'en',
        encoding: ndef.TextEncoding.UTF8,
      );

      _writeNDEF([textRecord]);
    } catch (e) {
      _showSnackBar('Error creating text record: $e');
    }
  }

  void _writeUrlRecord() {
    if (_urlController.text.trim().isEmpty) {
      _showSnackBar('Please enter URL to write');
      return;
    }

    try {
      String url = _urlController.text.trim();
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }

      ndef.NDEFRecord urlRecord = ndef.UriRecord.fromString(url);
      _writeNDEF([urlRecord]);
    } catch (e) {
      _showSnackBar('Error creating URL record: $e');
    }
  }

  // Helper methods
  String _bytesToHex(Uint8List bytes) {
    return bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join(' ')
        .toUpperCase();
  }

  String _bytesToAscii(Uint8List bytes) {
    try {
      return String.fromCharCodes(bytes.where((b) => b >= 32 && b <= 126));
    } catch (e) {
      return 'Non-ASCII data';
    }
  }

  List<int> _hexToBytes(String hex) {
    List<int> bytes = [];
    for (int i = 0; i < hex.length; i += 2) {
      String hexByte = hex.substring(i, i + 2);
      bytes.add(int.parse(hexByte, radix: 16));
    }
    return bytes;
  }

  bool _isHexString(String str) {
    return RegExp(r'^[0-9A-Fa-f\s]+$').hasMatch(str.replaceAll('0x', ''));
  }

  String _getRecordTypeString(ndef.NDEFRecord record) {
    try {
      if (record.type != null) {
        return String.fromCharCodes(record.type!);
      } else {
        return 'Unknown (null)';
      }
    } catch (e) {
      return 'Unknown (${record.type})';
    }
  }

  String _getRecordInfo(ndef.NDEFRecord record) {
    try {
      if (record is ndef.TextRecord) {
        return 'Text: "${record.text}" (Language: ${record.language})';
      } else if (record is ndef.UriRecord) {
        return 'URI: ${record.content}';
      } else if (record is ndef.MimeRecord) {
        return 'MIME: ${record.decodedType}';
      } else if (record is ndef.AbsoluteUriRecord) {
        return 'Absolute URI: ${record.decodedType}';
      } else {
        try {
          if (record.payload != null && record.payload!.isNotEmpty) {
            List<int> payloadList = record.payload!.toList();
            String decoded = String.fromCharCodes(payloadList);
            return 'Raw: $decoded';
          } else {
            return 'Empty payload';
          }
        } catch (e) {
          int payloadLength = record.payload?.length ?? 0;
          return 'Binary data ($payloadLength bytes): ${record.decodedType}';
        }
      }
    } catch (e) {
      return 'Error decoding record: $e';
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _clearFields() {
    _textController.clear();
    _urlController.clear();
    _wifiSSIDController.clear();
    _wifiPasswordController.clear();
    _rawDataController.clear();
    _blockAddressController.text = '0';
    setState(() {
      _result = '';
      _records.clear();
      _tagType = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('NFC Reader/Writer'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _checkNFCAvailability,
            tooltip: 'Refresh NFC Status',
          ),
          IconButton(
            icon: Icon(Icons.clear),
            onPressed: _clearFields,
            tooltip: 'Clear All Fields',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // NFC Status Card
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NFC Status',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _availability == NFCAvailability.available
                              ? Icons.check_circle
                              : _availability == NFCAvailability.disabled
                                  ? Icons.warning
                                  : Icons.error,
                          color: _availability == NFCAvailability.available
                              ? Colors.green
                              : _availability == NFCAvailability.disabled
                                  ? Colors.orange
                                  : Colors.red,
                          size: 24,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _availability
                                .toString()
                                .split('.')
                                .last
                                .replaceAll('_', ' ')
                                .toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _availability == NFCAvailability.available
                                  ? Colors.green
                                  : _availability == NFCAvailability.disabled
                                      ? Colors.orange
                                      : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_tagType.isNotEmpty) ...[
                      SizedBox(height: 8),
                      Text(
                        'Last scanned: $_tagType',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Scan/Read Section
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scan & Read Tags',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isReading ? null : _scanTag,
                            icon: _isReading
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : Icon(Icons.nfc),
                            label: Text(
                                _isReading ? 'Scanning...' : 'Scan Any Tag'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isReading ? null : _readISO15693Tag,
                            icon: Icon(Icons.memory),
                            label: Text('Read ISO15693'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_result.isNotEmpty) ...[
                      SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        height: 300,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            _result,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // ISO15693 Write Section
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ISO15693 Raw Data Write',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _blockAddressController,
                            decoration: InputDecoration(
                              labelText: 'Block Address',
                              hintText: '0',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _rawDataController,
                            decoration: InputDecoration(
                              labelText: 'Data (Text or Hex)',
                              hintText: 'Hello or 48656C6C',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isWriting ? null : _writeISO15693Block,
                        icon: _isWriting
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Icon(Icons.storage),
                        label: Text(
                            _isWriting ? 'Writing...' : 'Write ISO15693 Block'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // NDEF Write Section
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NDEF Write (Compatible Tags Only)',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        labelText: 'Text Record',
                        hintText: 'Enter text to write',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.text_fields),
                      ),
                    ),
                    SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isWriting ? null : _writeTextRecord,
                        icon: Icon(Icons.text_fields),
                        label: Text('Write Text (NDEF)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _urlController,
                      decoration: InputDecoration(
                        labelText: 'URL Record',
                        hintText: 'Enter URL',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.link),
                      ),
                    ),
                    SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isWriting ? null : _writeUrlRecord,
                        icon: Icon(Icons.link),
                        label: Text('Write URL (NDEF)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Instructions
            Card(
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Instructions:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Use "Scan Any Tag" to detect and read both NDEF and ISO15693 tags\n'
                      '• For ISO15693 tags: Use raw data operations to read/write blocks\n'
                      '• For NDEF tags: Use the NDEF write functions\n'
                      '• Data can be entered as text or hex (e.g., "48656C6C" for "Hell")\n'
                      '• ISO15693 blocks are typically 4 bytes each\n'
                      '• Block addresses usually start from 0',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _urlController.dispose();
    _wifiSSIDController.dispose();
    _wifiPasswordController.dispose();
    _rawDataController.dispose();
    _blockAddressController.dispose();
    super.dispose();
  }
}
