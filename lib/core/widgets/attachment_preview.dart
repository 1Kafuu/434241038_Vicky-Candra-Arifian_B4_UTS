import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';

class AttachmentPreviewDialog extends StatefulWidget {
  final String? url;
  final File? file;
  final String? title;

  const AttachmentPreviewDialog({
    super.key,
    this.url,
    this.file,
    this.title,
  }) : assert(url != null || file != null, 'Either url or file must be provided');

  static void show(BuildContext context, {String? url, File? file, String? title}) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      useSafeArea: false,
      builder: (context) => AttachmentPreviewDialog(
        url: url,
        file: file,
        title: title,
      ),
    );
  }

  @override
  State<AttachmentPreviewDialog> createState() => _AttachmentPreviewDialogState();
}

class _AttachmentPreviewDialogState extends State<AttachmentPreviewDialog>
    with SingleTickerProviderStateMixin {
  late TransformationController _transformationController;
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..addListener(() {
        _transformationController.value = _animation!.value;
      });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    final currentMatrix = _transformationController.value;
    final double currentScale = currentMatrix.getMaxScaleOnAxis();

    final Matrix4 endMatrix;
    if (currentScale > 1.0) {
      // Reset to default scale
      endMatrix = Matrix4.identity();
    } else {
      // Zoom in to 2.5x centered on screen
      final double targetScale = 2.5;
      final size = MediaQuery.of(context).size;
      final double x = size.width / 2;
      final double y = size.height / 2;

      endMatrix = Matrix4.identity()
        ..translate(x, y)
        ..scale(targetScale)
        ..translate(-x, -y);
    }

    _animation = Matrix4Tween(
      begin: currentMatrix,
      end: endMatrix,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    // Extract filename from URL or file path
    String displayName = widget.title ?? '';
    if (displayName.isEmpty) {
      if (widget.file != null) {
        displayName = widget.file!.path.split('/').last.split('\\').last;
      } else if (widget.url != null) {
        displayName = widget.url!.split('/').last;
      }
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Glassmorphic Backdrop
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                color: Colors.black.withOpacity(0.4),
              ),
            ),
          ),
          
          // Image Viewer (Expanded to full screen to catch all pinch/pan gestures)
          Positioned.fill(
            child: GestureDetector(
              onDoubleTap: _handleDoubleTap,
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: Hero(
                    tag: widget.url ?? widget.file?.path ?? 'attachment_preview',
                    child: widget.file != null
                        ? Image.file(
                            widget.file!,
                            fit: BoxFit.contain,
                          )
                        : Image.network(
                            widget.url!,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.broken_image_rounded,
                                    color: Colors.white60,
                                    size: 64,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Gagal memuat gambar',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                ),
              ),
            ),
          ),

          // Header Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Row(
              children: [
                // Close button with circular background blur
                ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      color: Colors.black.withOpacity(0.5),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Filename
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        color: Colors.black.withOpacity(0.5),
                        child: Text(
                          displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
