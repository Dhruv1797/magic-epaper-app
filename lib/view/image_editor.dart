import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:magic_epaper_app/pro_image_editor/features/movable_background_image.dart';
import 'package:magic_epaper_app/view/widget/flip_controls.dart';
import 'package:magic_epaper_app/util/image_editor_utils.dart';
import 'package:magic_epaper_app/view/widget/image_list.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;

import 'package:magic_epaper_app/provider/image_loader.dart';
import 'package:magic_epaper_app/util/epd/epd.dart';
import 'package:magic_epaper_app/constants/color_constants.dart';

class ImageEditor extends StatefulWidget {
  final Epd epd;
  const ImageEditor({super.key, required this.epd});

  @override
  State<ImageEditor> createState() => _ImageEditorState();
}

class _ImageEditorState extends State<ImageEditor> {
  bool flipHorizontal = false;
  bool flipVertical = false;

  void toggleFlipHorizontal() {
    setState(() {
      flipHorizontal = !flipHorizontal;
    });
  }

  void toggleFlipVertical() {
    setState(() {
      flipVertical = !flipVertical;
    });
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final imgLoader = context.read<ImageLoader>();
      if (imgLoader.image == null) {
        imgLoader.loadFinalizedImage(
          width: widget.epd.width,
          height: widget.epd.height,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var imgLoader = context.watch<ImageLoader>();
    final orgImg = imgLoader.image;

    final List<img.Image> processedImgs = orgImg != null
        ? processImages(
            originalImage: orgImg,
            epd: widget.epd,
          )
        : [];

    final imgList = ImageList(
      imgList: processedImgs,
      epd: widget.epd,
      flipHorizontal: flipHorizontal,
      flipVertical: flipVertical,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        backgroundColor: colorAccent,
        elevation: 0,
        title: const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              'Select Your Filter',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        toolbarHeight: 85,
        actions: <Widget>[
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                final success = await imgLoader.pickImage(
                  width: widget.epd.width,
                  height: widget.epd.height,
                );
                if (success && imgLoader.image != null) {
                  final bytes =
                      Uint8List.fromList(img.encodePng(imgLoader.image!));
                  await imgLoader.saveFinalizedImageBytes(bytes);
                }
              },
              child: const Text(
                "Import Image",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final canvasBytes = await Navigator.of(context).push<Uint8List>(
                MaterialPageRoute(
                  builder: (context) => const MovableBackgroundImageExample(),
                ),
              );
              if (canvasBytes != null) {
                await imgLoader.updateImage(
                  bytes: canvasBytes,
                  width: widget.epd.width,
                  height: widget.epd.height,
                );
                await imgLoader.saveFinalizedImageBytes(canvasBytes);
              }
            },
            child: const Text("Open Editor"),
          ),
        ],
      ),
      floatingActionButton: orgImg != null
          ? FlipControls(
              onFlipHorizontal: toggleFlipHorizontal,
              onFlipVertical: toggleFlipVertical,
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child:
              imgLoader.isLoading ? Center(child: Text('Loading..')) : imgList,
        ),
      ),
    );
  }
}
