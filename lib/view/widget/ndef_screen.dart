import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:ndef/ndef.dart' as ndef;
import 'dart:typed_data';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NDEF Reader/Writer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: NDEFScreen(),
    );
  }
}

class NDEFScreen extends StatefulWidget {
  @override
  _NDEFScreenState createState() => _NDEFScreenState();
}

class _NDEFScreenState extends State<NDEFScreen> {
  NFCAvailability _availability = NFCAvailability.not_supported;
  NFCTag? _tag;
  String _result = '';
  List<ndef.NDEFRecord> _records = [];
  bool _isReading = false;
  bool _isWriting = false;

  // Controllers for writing data
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _wifiSSIDController = TextEditingController();
  final TextEditingController _wifiPasswordController = TextEditingController();

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

  Future<void> _readNDEF() async {
    if (_availability != NFCAvailability.available) {
      _showSnackBar('NFC is not available');
      return;
    }

    setState(() {
      _isReading = true;
      _result = 'Scanning for NFC tag...';
      _records.clear();
    });

    try {
      // Poll for NFC tags
      NFCTag tag = await FlutterNfcKit.poll(
        timeout: Duration(seconds: 10),
        iosMultipleTagMessage: "Multiple tags found, please select one",
        iosAlertMessage: "Scan your NFC tag",
      );

      setState(() {
        _tag = tag;
        _result = 'Tag found: ${tag.type}\nID: ${tag.id}';
      });

      // Check if tag is NDEF available
      if (tag.ndefAvailable == true) {
        try {
          // Read NDEF records
          List<ndef.NDEFRecord> records = await FlutterNfcKit.readNDEFRecords();

          setState(() {
            _records = records;
            _result += '\n\nNDEF Records found: ${_records.length}';

            // Add detailed record information
            for (int i = 0; i < records.length; i++) {
              _result += '\n\nRecord ${i + 1}:';
              _result += '\n  Type: ${_getRecordTypeString(records[i])}';
              _result += '\n  TNF: ${records[i].tnf}';
              _result += '\n  Content: ${_getRecordInfo(records[i])}';
            }
          });
        } catch (e) {
          setState(() {
            _result += '\n\nError reading NDEF records: $e';
          });
        }
      } else {
        setState(() {
          _result += '\n\nTag is not NDEF compatible';
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
      _result = 'Scanning for NFC tag to write...';
    });

    try {
      // Poll for NFC tags
      NFCTag tag = await FlutterNfcKit.poll(
        timeout: Duration(seconds: 10),
        iosMultipleTagMessage: "Multiple tags found, please select one",
        iosAlertMessage: "Scan your NFC tag to write",
      );

      setState(() {
        _tag = tag;
        _result = 'Tag found: ${tag.type}\nID: ${tag.id}';
        _result += '\nNDEF Available: ${tag.ndefAvailable}';
        _result += '\nNDEF Writable: ${tag.ndefWritable}';
        _result += '\nWriting ${records.length} record(s)...';
      });

      // Check if tag supports NDEF and is writable
      if (tag.ndefAvailable == true) {
        if (tag.ndefWritable == true) {
          try {
            // Write NDEF records
            await FlutterNfcKit.writeNDEFRecords(records);

            setState(() {
              _result += '\n\n✅ NDEF records written successfully!';
              _result += '\nRecords written: ${records.length}';

              // Show what was written
              for (int i = 0; i < records.length; i++) {
                _result += '\n\nWritten Record ${i + 1}:';
                _result += '\n  Type: ${_getRecordTypeString(records[i])}';
                _result += '\n  Content: ${_getRecordInfo(records[i])}';
              }
            });
          } catch (writeError) {
            setState(() {
              _result += '\n\n❌ Error writing records: $writeError';
            });
          }
        } else {
          setState(() {
            _result += '\n\n❌ Tag is not writable';
          });
        }
      } else {
        setState(() {
          _result += '\n\n❌ Tag does not support NDEF';
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
      // Finish NFC session
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
      // Create a proper text record
      ndef.NDEFRecord textRecord = ndef.TextRecord(
        text: _textController.text.trim(),
        language: 'en',
        encoding: ndef.TextEncoding.UTF8,
      );

      print(
          'Creating text record with content: "${_textController.text.trim()}"');
      _writeNDEF([textRecord]);
    } catch (e) {
      _showSnackBar('Error creating text record: $e');
      print('Text record creation error: $e');
    }
  }

  void _writeUrlRecord() {
    if (_urlController.text.trim().isEmpty) {
      _showSnackBar('Please enter URL to write');
      return;
    }

    try {
      String url = _urlController.text.trim();

      // Ensure URL has proper protocol
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }

      ndef.NDEFRecord urlRecord = ndef.UriRecord.fromString(url);
      print('Creating URL record with content: "$url"');
      _writeNDEF([urlRecord]);
    } catch (e) {
      _showSnackBar('Error creating URL record: $e');
      print('URL record creation error: $e');
    }
  }

  void _writeWifiRecord() {
    if (_wifiSSIDController.text.trim().isEmpty) {
      _showSnackBar('Please enter WiFi SSID');
      return;
    }

    try {
      // Create WiFi configuration string
      String wifiConfig =
          'WIFI:T:WPA;S:${_wifiSSIDController.text.trim()};P:${_wifiPasswordController.text.trim()};;';

      // Create as text record for better compatibility
      ndef.NDEFRecord wifiRecord = ndef.TextRecord(
        text: wifiConfig,
        language: 'en',
        encoding: ndef.TextEncoding.UTF8,
      );

      print('Creating WiFi record with config: "$wifiConfig"');
      _writeNDEF([wifiRecord]);
    } catch (e) {
      _showSnackBar('Error creating WiFi record: $e');
      print('WiFi record creation error: $e');
    }
  }

  void _writeMultipleRecords() {
    List<ndef.NDEFRecord> records = [];

    try {
      if (_textController.text.trim().isNotEmpty) {
        records.add(ndef.TextRecord(
          text: _textController.text.trim(),
          language: 'en',
          encoding: ndef.TextEncoding.UTF8,
        ));
      }

      if (_urlController.text.trim().isNotEmpty) {
        String url = _urlController.text.trim();
        if (!url.startsWith('http://') && !url.startsWith('https://')) {
          url = 'https://$url';
        }
        records.add(ndef.UriRecord.fromString(url));
      }

      if (_wifiSSIDController.text.trim().isNotEmpty) {
        String wifiConfig =
            'WIFI:T:WPA;S:${_wifiSSIDController.text.trim()};P:${_wifiPasswordController.text.trim()};;';
        records.add(ndef.TextRecord(
          text: wifiConfig,
          language: 'en',
          encoding: ndef.TextEncoding.UTF8,
        ));
      }

      if (records.isEmpty) {
        _showSnackBar('Please enter at least one record to write');
        return;
      }

      print('Creating ${records.length} records for writing');
      _writeNDEF(records);
    } catch (e) {
      _showSnackBar('Error creating multiple records: $e');
      print('Multiple records creation error: $e');
    }
  }

  // Verify what's actually written on the tag
  Future<void> _verifyWrite() async {
    if (_availability != NFCAvailability.available) {
      _showSnackBar('NFC is not available');
      return;
    }

    setState(() {
      _result = 'Scanning tag for verification...';
    });

    try {
      NFCTag tag = await FlutterNfcKit.poll(
        timeout: Duration(seconds: 10),
        iosMultipleTagMessage: "Multiple tags found",
        iosAlertMessage: "Scan tag to verify content",
      );

      if (tag.ndefAvailable == true) {
        List<ndef.NDEFRecord> records = await FlutterNfcKit.readNDEFRecords();

        setState(() {
          _result = '🔍 VERIFICATION RESULTS:\n';
          _result += 'Tag Type: ${tag.type}\n';
          _result += 'Tag ID: ${tag.id}\n';
          _result += 'NDEF Available: ${tag.ndefAvailable}\n';
          _result += 'NDEF Writable: ${tag.ndefWritable}\n';
          _result += 'Records Found: ${records.length}\n\n';

          if (records.isEmpty) {
            _result += '❌ No NDEF records found on tag\n';
            _result += 'This means the tag is empty or the write failed.';
          } else {
            for (int i = 0; i < records.length; i++) {
              var record = records[i];
              _result += '📄 Record ${i + 1}:\n';
              _result += '  TNF: ${record.tnf}\n';
              _result += '  Type: ${_getRecordTypeString(record)}\n';
              _result +=
                  '  Payload Size: ${record.payload?.length ?? 0} bytes\n';
              _result += '  Content: ${_getRecordInfo(record)}\n';
              _result +=
                  '  Raw Payload: ${record.payload != null ? record.payload!.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ') : 'null'}\n\n';
            }
          }
        });
      } else {
        setState(() {
          _result = '❌ Tag does not support NDEF';
        });
      }
    } catch (e) {
      setState(() {
        _result = 'Verification Error: $e';
      });
    } finally {
      try {
        await FlutterNfcKit.finish();
      } catch (e) {
        print('Error finishing verification: $e');
      }
    }
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
        // Try to decode as text for debugging
        try {
          // Handle null payload and convert Uint8List to List<int>
          if (record.payload != null && record.payload!.isNotEmpty) {
            List<int> payloadList = record.payload!.toList();
            String decoded = String.fromCharCodes(payloadList);
            return 'Raw: $decoded';
          } else {
            return 'Empty payload';
          }
        } catch (e) {
          // Handle null payload safely
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
    setState(() {
      _result = '';
      _records.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('NDEF Reader/Writer'),
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
            // NFC Availability Status
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
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Read Section
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Read NDEF Tags',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isReading ? null : _readNDEF,
                            icon: _isReading
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : Icon(Icons.nfc),
                            label: Text(
                                _isReading ? 'Reading...' : 'Read NFC Tag'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _verifyWrite,
                          icon: Icon(Icons.search),
                          label: Text('Verify'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    if (_result.isNotEmpty) ...[
                      SizedBox(height: 16),
                      Container(
                        width: double.infinity,
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

            // Write Section
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Write NDEF Records',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 16),

                    // Text Record
                    TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        labelText: 'Text Record',
                        hintText: 'Enter text to write (e.g., "Hello World")',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.text_fields),
                      ),
                      maxLines: 2,
                    ),
                    SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isWriting ? null : _writeTextRecord,
                        icon: Icon(Icons.text_fields),
                        label: Text('Write Text Only'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // URL Record
                    TextField(
                      controller: _urlController,
                      decoration: InputDecoration(
                        labelText: 'URL Record',
                        hintText: 'Enter URL (e.g., "google.com")',
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
                        label: Text('Write URL Only'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // WiFi Record
                    TextField(
                      controller: _wifiSSIDController,
                      decoration: InputDecoration(
                        labelText: 'WiFi SSID',
                        hintText: 'Enter WiFi network name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.wifi),
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: _wifiPasswordController,
                      decoration: InputDecoration(
                        labelText: 'WiFi Password',
                        hintText: 'Enter WiFi password (optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                      obscureText: true,
                    ),
                    SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isWriting ? null : _writeWifiRecord,
                        icon: Icon(Icons.wifi),
                        label: Text('Write WiFi Only'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Write Multiple Records
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isWriting ? null : _writeMultipleRecords,
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
                            : Icon(Icons.library_books),
                        label: Text(
                            _isWriting ? 'Writing...' : 'Write All Records'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

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
                      '1. Make sure NFC is enabled on your device\n'
                      '2. Enter text in the fields above\n'
                      '3. Tap a write button and scan an NFC tag\n'
                      '4. Use "Verify" to check what was written\n'
                      '5. Test with other NFC apps to confirm compatibility',
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
    super.dispose();
  }
}
