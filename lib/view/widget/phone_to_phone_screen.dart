import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:ndef/ndef.dart' as ndef;

// void main() {
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Phone NFC Communication',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//         visualDensity: VisualDensity.adaptivePlatformDensity,
//       ),
//       home: PhoneNFCScreen(),
//     );
//   }
// }

class PhoneNFCScreen extends StatefulWidget {
  @override
  _PhoneNFCScreenState createState() => _PhoneNFCScreenState();
}

class _PhoneNFCScreenState extends State<PhoneNFCScreen> {
  NFCAvailability _availability = NFCAvailability.not_supported;
  String _result = '';
  bool _isScanning = false;
  bool _isEmulating = false;
  
  final TextEditingController _messageController = TextEditingController();

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

  // Method 1: Read from another phone (when other phone is in card emulation mode)
  Future<void> _readFromPhone() async {
    if (_availability != NFCAvailability.available) {
      _showSnackBar('NFC is not available');
      return;
    }

    setState(() {
      _isScanning = true;
      _result = 'Hold this phone near another phone in NFC mode...';
    });

    try {
      // Poll for NFC tags/devices
      NFCTag tag = await FlutterNfcKit.poll(
        timeout: Duration(seconds: 15),
        iosMultipleTagMessage: "Multiple devices found",
        iosAlertMessage: "Hold near another phone",
      );

      setState(() {
        _result = 'Connected to device!\n';
        _result += 'Type: ${tag.type}\n';
        _result += 'ID: ${tag.id}\n';
        _result += 'NDEF Available: ${tag.ndefAvailable}\n';
      });

      // Try to read NDEF data
      if (tag.ndefAvailable == true) {
        try {
          List<ndef.NDEFRecord> records = await FlutterNfcKit.readNDEFRecords();
          
          setState(() {
            _result += '\n📱 RECEIVED MESSAGE:\n';
            
            if (records.isEmpty) {
              _result += 'No message received';
            } else {
              for (int i = 0; i < records.length; i++) {
                var record = records[i];
                if (record is ndef.TextRecord) {
                  _result += '💬 "${record.text}"\n';
                } else {
                  _result += '📄 ${_getRecordInfo(record)}\n';
                }
              }
            }
          });
        } catch (e) {
          setState(() {
            _result += '\nError reading message: $e';
          });
        }
      } else {
        setState(() {
          _result += '\nDevice does not support NDEF messaging';
        });
      }

    } catch (e) {
      setState(() {
        _result = 'Error connecting to device: $e\n\n';
        _result += 'Make sure the other phone is:\n';
        _result += '• In NFC card emulation mode\n';
        _result += '• Very close to this phone\n';
        _result += '• Has NFC enabled';
      });
    } finally {
      setState(() {
        _isScanning = false;
      });
      
      try {
        await FlutterNfcKit.finish();
      } catch (e) {
        print('Error finishing NFC session: $e');
      }
    }
  }

  // Method 2: Android Beam equivalent (requires both phones to support P2P)
  Future<void> _sendBeamMessage() async {
    if (_messageController.text.trim().isEmpty) {
      _showSnackBar('Please enter a message to send');
      return;
    }

    setState(() {
      _result = 'This feature requires Android Beam or similar P2P NFC.\n\n';
      _result += 'Alternative methods:\n';
      _result += '1. Use a physical NFC tag as intermediary\n';
      _result += '2. Use apps like "NFC Tools" or "TagWriter"\n';
      _result += '3. Enable card emulation mode on one phone\n\n';
      _result += 'Your message: "${_messageController.text.trim()}"';
    });
  }

  // Method 3: Simulate card emulation (limited support)
  Future<void> _enableCardEmulation() async {
    setState(() {
      _isEmulating = true;
      _result = '📱 Card Emulation Mode\n\n';
      _result += 'This phone is now acting like an NFC tag.\n';
      _result += 'Another phone can scan this device.\n\n';
      _result += 'Message ready to send:\n';
      _result += '"${_messageController.text.trim()}"\n\n';
      _result += 'Hold another phone close to this one...';
    });

    // Note: True card emulation requires system-level permissions
    // and is not fully supported by flutter_nfc_kit
    // This is a simulation for demonstration
    
    await Future.delayed(Duration(seconds: 10));
    
    setState(() {
      _isEmulating = false;
      _result += '\n\n⏰ Card emulation timeout.\n';
      _result += 'Real card emulation requires:\n';
      _result += '• Android HCE (Host Card Emulation)\n';
      _result += '• System-level app permissions\n';
      _result += '• Custom AID registration';
    });
  }

  String _getRecordInfo(ndef.NDEFRecord record) {
    try {
      if (record is ndef.TextRecord) {
        return 'Text: "${record.text}"';
      } else if (record is ndef.UriRecord) {
        return 'URL: ${record.content}';
      } else {
        if (record.payload != null && record.payload!.isNotEmpty) {
          String decoded = String.fromCharCodes(record.payload!.toList());
          return 'Data: $decoded';
        }
        return 'Unknown data type';
      }
    } catch (e) {
      return 'Error reading data: $e';
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

  void _clearAll() {
    _messageController.clear();
    setState(() {
      _result = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Phone NFC Communication'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _checkNFCAvailability,
            tooltip: 'Refresh NFC Status',
          ),
          IconButton(
            icon: Icon(Icons.clear),
            onPressed: _clearAll,
            tooltip: 'Clear All',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // NFC Status
            Card(
              elevation: 4,
              color: _availability == NFCAvailability.available 
                  ? Colors.green[50] : Colors.red[50],
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      _availability == NFCAvailability.available
                          ? Icons.check_circle
                          : Icons.error,
                      color: _availability == NFCAvailability.available
                          ? Colors.green
                          : Colors.red,
                      size: 32,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NFC Status',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            _availability.toString().split('.').last
                                .replaceAll('_', ' ').toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _availability == NFCAvailability.available
                                  ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Message Input
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Message to Send/Receive',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        labelText: 'Your Message',
                        hintText: 'Enter text to send to another phone',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.message),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Communication Options
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Communication Methods',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 16),

                    // Read from another phone
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: (_isScanning || _isEmulating) ? null : _readFromPhone,
                        icon: _isScanning 
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(Icons.nfc),
                        label: Text(_isScanning ? 'Scanning...' : 'Read from Another Phone'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),

                    // Send via Android Beam (deprecated but showing concept)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _sendBeamMessage,
                        icon: Icon(Icons.send),
                        label: Text('Send Message (P2P Info)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),

                    // Emulate NFC tag
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: (_isScanning || _isEmulating || _messageController.text.trim().isEmpty) 
                            ? null : _enableCardEmulation,
                        icon: _isEmulating
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Icon(Icons.credit_card),
                        label: Text(_isEmulating ? 'Emulating...' : 'Act as NFC Tag'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Results
            if (_result.isNotEmpty)
              Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Results',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SizedBox(height: 12),
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
                  ),
                ),
              ),
            SizedBox(height: 16),

            // Instructions
            Card(
              elevation: 2,
              color: Colors.yellow[50],
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📱 Phone-to-Phone NFC Tips:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• True P2P communication requires specialized apps\n'
                      '• One phone acts as a "tag", the other as "reader"\n'
                      '• Use apps like "NFC Tools" for easier phone-to-phone transfer\n'
                      '• Physical NFC tags work more reliably than phone-to-phone\n'
                      '• Both phones need NFC enabled and screens on\n'
                      '• Hold phones very close (back-to-back) for 2-3 seconds',
                      style: TextStyle(fontSize: 13),
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
    _messageController.dispose();
    super.dispose();
  }
}