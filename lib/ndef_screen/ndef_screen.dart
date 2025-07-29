import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:magic_epaper_app/constants/string_constants.dart';
import 'package:magic_epaper_app/ndef_screen/app_nfc/app_data_model.dart';
import 'package:magic_epaper_app/ndef_screen/app_nfc/app_selection_service.dart';
import 'package:magic_epaper_app/ndef_screen/controller/nfc_controller.dart';
import 'package:magic_epaper_app/ndef_screen/widgets/nfc_status_card.dart';
import 'package:magic_epaper_app/ndef_screen/widgets/nfc_write_card.dart';
import 'package:magic_epaper_app/ndef_screen/widgets/nfc_read_card.dart';
import 'package:magic_epaper_app/view/widget/common_scaffold_widget.dart';

class NDEFScreen extends StatefulWidget {
  const NDEFScreen({super.key});

  @override
  State<NDEFScreen> createState() => _NDEFScreenState();
}

class _NDEFScreenState extends State<NDEFScreen> {
  late NFCController _nfcController;
  String _textValue = '';
  String _urlValue = '';
  String _wifiSSIDValue = '';
  String _wifiPasswordValue = '';
  AppData? _selectedApp; // Add this line

  @override
  void initState() {
    super.initState();
    _nfcController = NFCController();
    _nfcController.addListener(_onNFCStateChanged);
    _checkNFCAvailability();
  }

  @override
  void dispose() {
    _nfcController.removeListener(_onNFCStateChanged);
    _nfcController.dispose();
    super.dispose();
  }

  void _onNFCStateChanged() {
    setState(() {});
  }

  Future<void> _checkNFCAvailability() async {
    await _nfcController.checkNFCAvailability();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Add this method for app selection
  void _onAppSelected(AppData? app) {
    setState(() {
      _selectedApp = app;
    });
  }

  // Add this method for writing app launcher
  Future<void> _writeAppLauncher() async {
    if (_selectedApp != null) {
      await _nfcController
          .writeAppLauncherRecordSingle(_selectedApp!.packageName);
      _handleWriteResult();
      if (_nfcController.result.contains(StringConstants.successfully)) {
        setState(() {
          _selectedApp = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      title: StringConstants.appName,
      index: 1,
      actions: [
        IconButton(
          icon: const Icon(
            Icons.clear_all,
            color: Colors.white,
          ),
          onPressed: _nfcController.result.isNotEmpty
              ? () {
                  _nfcController.clearResult();
                  _showSnackBar('Results cleared');
                }
              : null,
          tooltip: 'Clear Results',
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            NFCStatusCard(
              availability: _nfcController.availability,
              onRefresh: _checkNFCAvailability,
            ),
            const SizedBox(height: 16),
            NFCReadCard(
              isReading: _nfcController.isReading,
              isClearing: _nfcController.isClearing,
              result: _nfcController.result,
              onRead: () async {
                await _nfcController.readNDEF();
                if (_nfcController.result.contains(StringConstants.error)) {
                  _showSnackBar(StringConstants.readOperationFailed,
                      isError: true);
                } else {
                  _showSnackBar(StringConstants.tagReadSuccessfully);
                }
              },
              onVerify: () async {
                await _nfcController.verifyWrite();
                if (_nfcController.result.contains(StringConstants.error)) {
                  _showSnackBar(StringConstants.verificationFailed,
                      isError: true);
                } else {
                  _showSnackBar(StringConstants.tagVerifiedSuccessfully);
                }
              },
              onClear: () async {
                bool confirmed = await _showConfirmDialog(
                  StringConstants.clearNfcTag,
                  StringConstants.clearNfcTagConfirmation,
                );
                if (confirmed) {
                  await _nfcController.clearNDEF();
                  if (_nfcController.result.contains(StringConstants.error)) {
                    _showSnackBar(StringConstants.clearOperationFailed,
                        isError: true);
                  } else {
                    _showSnackBar(StringConstants.tagClearedSuccessfully);
                  }
                }
              },
            ),
            const SizedBox(height: 16),
            if (_nfcController.availability == NFCAvailability.available) ...[
              NFCWriteCard(
                isWriting: _nfcController.isWriting,
                textValue: _textValue,
                urlValue: _urlValue,
                wifiSSIDValue: _wifiSSIDValue,
                wifiPasswordValue: _wifiPasswordValue,
                onTextChanged: (value) => setState(() => _textValue = value),
                onUrlChanged: (value) => setState(() => _urlValue = value),
                onWifiSSIDChanged: (value) =>
                    setState(() => _wifiSSIDValue = value),
                onWifiPasswordChanged: (value) =>
                    setState(() => _wifiPasswordValue = value),
                onWriteText: () async {
                  await _nfcController.writeTextRecord(_textValue);
                  _handleWriteResult();
                },
                onWriteUrl: () async {
                  await _nfcController.writeUrlRecord(_urlValue);
                  _handleWriteResult();
                },
                onWriteWifi: () async {
                  await _nfcController.writeWifiRecord(
                      _wifiSSIDValue, _wifiPasswordValue);
                  _handleWriteResult();
                },
                onWriteMultiple: () async {
                  await _nfcController.writeMultipleRecords(_textValue,
                      _urlValue, _wifiSSIDValue, _wifiPasswordValue);
                  _handleWriteResult();
                },
              ),
              const SizedBox(height: 16),
              // Add the App Launcher Card here
              AppLauncherCard(
                selectedApp: _selectedApp,
                onAppSelected: _onAppSelected,
                isWriting: _nfcController.isWriting,
                onWriteAppLauncher: _writeAppLauncher,
              ),
            ] else ...[
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(Icons.warning, size: 48, color: Colors.orange),
                      const SizedBox(height: 16),
                      Text(
                        StringConstants.nfcNotAvailable,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        StringConstants.enableNfcMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _handleWriteResult() {
    if (_nfcController.result.contains(StringConstants.error)) {
      _showSnackBar(StringConstants.writeOperationFailed, isError: true);
    } else if (_nfcController.result.contains(StringConstants.successfully)) {
      _showSnackBar(StringConstants.dataWrittenSuccessfully);
      setState(() {
        _textValue = '';
        _urlValue = '';
        _wifiSSIDValue = '';
        _wifiPasswordValue = '';
      });
    }
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(title),
              content: Text(content),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(StringConstants.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text(StringConstants.confirm),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}

// Complete AppLauncherCard widget
class AppLauncherCard extends StatefulWidget {
  final AppData? selectedApp;
  final Function(AppData?) onAppSelected;
  final bool isWriting;
  final VoidCallback onWriteAppLauncher;

  const AppLauncherCard({
    Key? key,
    required this.selectedApp,
    required this.onAppSelected,
    required this.isWriting,
    required this.onWriteAppLauncher,
  }) : super(key: key);

  @override
  State<AppLauncherCard> createState() => _AppLauncherCardState();
}

class _AppLauncherCardState extends State<AppLauncherCard> {
  List<AppData> _allApps = [];
  List<AppData> _filteredApps = [];
  bool _isLoading = true;
  bool _isExpanded = false;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _customPackageController =
      TextEditingController();
  bool _showCustomInput = false;

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _customPackageController.dispose();
    super.dispose();
  }

  Future<void> _loadApps() async {
    setState(() => _isLoading = true);

    try {
      final apps = await AppLauncherService.getInstalledApps();
      setState(() {
        _allApps = apps;
        _filteredApps = apps;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading apps: $e')),
        );
      }
    }
  }

  void _filterApps(String query) {
    setState(() {
      _filteredApps = AppLauncherService.searchApps(_allApps, query);
    });
  }

  void _addCustomApp() {
    final packageName = _customPackageController.text.trim();
    if (packageName.isEmpty) return;

    if (!AppLauncherService.isValidPackageName(packageName)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(StringConstants.invalidPackageName)),
      );
      return;
    }

    final customApp = AppData(
      appName: 'Custom: $packageName',
      packageName: packageName,
    );

    widget.onAppSelected(customApp);
    _customPackageController.clear();
    setState(() => _showCustomInput = false);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with expand/collapse button
            Row(
              children: [
                const Icon(Icons.apps, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    StringConstants.writeAppLauncherData,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  icon:
                      Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                ),
              ],
            ),

            // Selected app display (always visible)
            if (widget.selectedApp != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.selectedApp!.appName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            widget.selectedApp!.packageName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => widget.onAppSelected(null),
                    ),
                  ],
                ),
              ),
            ],

            // Write button (always visible when app is selected)
            if (widget.selectedApp != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      !widget.isWriting ? widget.onWriteAppLauncher : null,
                  icon: widget.isWriting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.nfc),
                  label: Text(
                    widget.isWriting
                        ? 'Writing...'
                        : StringConstants.writeAppLauncher,
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],

            // Expandable app selection section
            if (_isExpanded) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // Search bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: StringConstants.searchApps,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () =>
                        setState(() => _showCustomInput = !_showCustomInput),
                    tooltip: StringConstants.customPackageName,
                  ),
                  border: const OutlineInputBorder(),
                ),
                onChanged: _filterApps,
              ),

              // Custom package input
              if (_showCustomInput) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customPackageController,
                        decoration: const InputDecoration(
                          hintText: StringConstants.enterPackageName,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _addCustomApp,
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),

              // App list
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_filteredApps.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(StringConstants.noAppsFound),
                  ),
                )
              else
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    itemCount: _filteredApps.length,
                    itemBuilder: (context, index) {
                      final app = _filteredApps[index];
                      final isSelected =
                          widget.selectedApp?.packageName == app.packageName;

                      return ListTile(
                        leading: const Icon(Icons.android),
                        title: Text(app.appName),
                        subtitle: Text(
                          app.packageName,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check, color: Colors.green)
                            : null,
                        selected: isSelected,
                        onTap: () {
                          widget.onAppSelected(app);
                          setState(() => _isExpanded = false);
                        },
                      );
                    },
                  ),
                ),
            ],

            // Select app button when no app is selected and not expanded
            if (widget.selectedApp == null && !_isExpanded) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _isExpanded = true),
                  icon: const Icon(Icons.apps),
                  label: const Text(StringConstants.selectApplication),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
