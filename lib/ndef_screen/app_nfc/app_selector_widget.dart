// import 'package:flutter/material.dart';
// import 'package:magic_epaper_app/constants/string_constants.dart';
// import 'package:magic_epaper_app/ndef_screen/app_nfc/app_data_model.dart';
// import 'package:magic_epaper_app/ndef_screen/app_nfc/app_selection_service.dart';


// class AppSelectorWidget extends StatefulWidget {
//   final AppInfo? selectedApp;
//   final Function(AppInfo?) onAppSelected;
//   final bool isWriting;

//   const AppSelectorWidget({
//     Key? key,
//     required this.selectedApp,
//     required this.onAppSelected,
//     required this.isWriting,
//   }) : super(key: key);

//   @override
//   State<AppSelectorWidget> createState() => _AppSelectorWidgetState();
// }

// class _AppSelectorWidgetState extends State<AppSelectorWidget> {
//   List<AppInfo> _allApps = [];
//   List<AppInfo> _filteredApps = [];
//   bool _isLoading = true;
//   String _searchQuery = '';
//   final TextEditingController _searchController = TextEditingController();
//   final TextEditingController _customPackageController = TextEditingController();
//   bool _showCustomInput = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadApps();
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     _customPackageController.dispose();
//     super.dispose();
//   }

//   Future<void> _loadApps() async {
//     setState(() => _isLoading = true);
    
//     try {
//       final apps = await AppLauncherService.getInstalledApps();
//       setState(() {
//         _allApps = apps;
//         _filteredApps = apps;
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() => _isLoading = false);
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error loading apps: $e')),
//         );
//       }
//     }
//   }

//   void _filterApps(String query) {
//     setState(() {
//       _searchQuery = query;
//       _filteredApps = AppLauncherService.searchApps(_allApps, query);
//     });
//   }

//   void _addCustomApp() {
//     final packageName = _customPackageController.text.trim();
//     if (packageName.isEmpty) return;

//     if (!AppLauncherService.isValidPackageName(packageName)) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text(StringConstants.invalidPackageName)),
//       );
//       return;
//     }

//     final customApp = AppInfo(
//       appName: 'Custom: $packageName',
//       packageName: packageName,
//     );

//     widget.onAppSelected(customApp);
//     _customPackageController.clear();
//     setState(() => _showCustomInput = false);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 4,
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 const Icon(Icons.apps, color: Colors.blue),
//                 const SizedBox(width: 8),
//                 Text(
//                   StringConstants.writeAppLauncherData,
//                   style: Theme.of(context).textTheme.titleLarge,
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
            
//             // Search bar
//             TextField(
//               controller: _searchController,
//               decoration: InputDecoration(
//                 hintText: StringConstants.searchApps,
//                 prefixIcon: const Icon(Icons.search),
//                 suffixIcon: IconButton(
//                   icon: const Icon(Icons.add),
//                   onPressed: () => setState(() => _showCustomInput = !_showCustomInput),
//                   tooltip: StringConstants.customPackageName,
//                 ),
//                 border: const OutlineInputBorder(),
//               ),
//               onChanged: _filterApps,
//             ),
            
//             // Custom package input
//             if (_showCustomInput) ...[
//               const SizedBox(height: 8),
//               Row(
//                 children: [
//                   Expanded(
//                     child: TextField(
//                       controller: _customPackageController,
//                       decoration: const InputDecoration(
//                         hintText: StringConstants.enterPackageName,
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   ElevatedButton(
//                     onPressed: _addCustomApp,
//                     child: const Text('Add'),
//                   ),
//                 ],
//               ),
//             ],
            
//             const SizedBox(height: 16),
            
//             // Selected app display
//             if (widget.selectedApp != null) ...[
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.blue.shade50,
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: Colors.blue.shade200),
//                 ),
//                 child: Row(
//                   children: [
//                     const Icon(Icons.check_circle, color: Colors.green),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             widget.selectedApp!.appName,
//                             style: const TextStyle(fontWeight: FontWeight.bold),
//                           ),
//                           Text(
//                             widget.selectedApp!.packageName,
//                             style: TextStyle(
//                               fontSize: 12,
//                               color: Colors.grey.shade600,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     IconButton(
//                       icon: const Icon(Icons.clear),
//                       onPressed: () => widget.onAppSelected(null),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 16),
//             ],
            
//             // App list
//             if (_isLoading)
//               const Center(child: CircularProgressIndicator())
//             else if (_filteredApps.isEmpty)
//               const Center(child: Text(StringConstants.noAppsFound))
//             else
//               SizedBox(
//                 height: 200,
//                 child: ListView.builder(
//                   itemCount: _filteredApps.length,
//                   itemBuilder: (context, index) {
//                     final app = _filteredApps[index];
//                     final isSelected = widget.selectedApp?.packageName == app.packageName;
                    
//                     return ListTile(
//                       leading: const Icon(Icons.android),
//                       title: Text(app.appName),
//                       subtitle: Text(
//                         app.packageName,
//                         style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
//                       ),
//                       trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
//                       selected: isSelected,
//                       onTap: () => widget.onAppSelected(app),
//                     );
//                   },
//                 ),
//               ),
            
//             const SizedBox(height: 16),
            
//             // Write button
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton.icon(
//                 onPressed: widget.selectedApp != null && !widget.isWriting
//                     ? () => _writeAppLauncher()
//                     : null,
//                 icon: widget.isWriting
//                     ? const SizedBox(
//                         width: 16,
//                         height: 16,
//                         child: CircularProgressIndicator(strokeWidth: 2),
//                       )
//                     : const Icon(Icons.nfc),
//                 label: Text(
//                   widget.isWriting
//                       ? 'Writing...'
//                       : StringConstants.writeAppLauncher,
//                 ),
//                 style: ElevatedButton.styleFrom(
//                   padding: const EdgeInsets.all(16),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _writeAppLauncher() {
//     if (widget.selectedApp != null) {
//       // This will be called from the parent widget
//       // You'll need to pass a callback function to handle the write operation
//     }
//   }
// }