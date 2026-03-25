import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../app/theme.dart';
import '../../shared/adaptive/adaptive_dialog.dart';
import '../../shared/adaptive/adaptive_progress_indicator.dart';
import '../../shared/adaptive/adaptive_scaffold.dart';
import '../../shared/adaptive/platform_utils.dart';
import 'capture_provider.dart';

class CaptureScreen extends ConsumerStatefulWidget {
  final String bookId;

  const CaptureScreen({super.key, required this.bookId});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _permissionDenied = false;
  FlashMode _flashMode = FlashMode.auto;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() => _permissionDenied = true);
        }
        return;
      }
      // Prefer back camera
      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller.initialize();

      if (!mounted) return;

      setState(() {
        _controller = controller;
        _isInitialized = true;
      });
    } on CameraException catch (e) {
      if (e.code == 'CameraAccessDenied' ||
          e.code == 'CameraAccessDeniedWithoutPrompt' ||
          e.code == 'CameraAccessRestricted') {
        if (mounted) {
          setState(() => _permissionDenied = true);
          _showPermissionDeniedDialog();
        }
      } else {
        if (mounted) {
          setState(() => _permissionDenied = true);
        }
      }
    }
  }

  Future<void> _showPermissionDeniedDialog() async {
    if (!mounted) return;
    await showAdaptiveAlert(
      context,
      title: 'Camera Access Needed',
      message: 'Focus Read needs camera access to photograph book pages. '
          'Please enable camera access in your device settings.',
    );
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_isInitialized) return;
    FlashMode next;
    switch (_flashMode) {
      case FlashMode.auto:
        next = FlashMode.always;
      case FlashMode.always:
        next = FlashMode.off;
      case FlashMode.off:
        next = FlashMode.auto;
      default:
        next = FlashMode.auto;
    }
    await _controller!.setFlashMode(next);
    setState(() => _flashMode = next);
  }

  IconData get _flashIcon {
    switch (_flashMode) {
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.always:
        return Icons.flash_on;
      case FlashMode.off:
        return Icons.flash_off;
      default:
        return Icons.flash_auto;
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_isInitialized) return;
    try {
      final xFile = await _controller!.takePicture();
      await _processFile(File(xFile.path));
    } on CameraException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: ${e.description}')),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery);
    if (xFile == null) return;
    await _processFile(File(xFile.path));
  }

  Future<void> _processFile(File file) async {
    final notifier = ref.read(captureProvider(widget.bookId).notifier);
    await notifier.processImage(file);
  }

  Future<void> _handleSuccess(String pageId) async {
    if (!mounted) return;
    String? result;

    if (isIOSPlatform) {
      result = await showCupertinoDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Page saved!'),
          content: const Text('What would you like to do next?'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop('another'),
              child: const Text('Add another page'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(ctx).pop('read'),
              child: const Text('Start reading'),
            ),
          ],
        ),
      );
    } else {
      result = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Page saved!'),
          content: const Text('What would you like to do next?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('another'),
              child: const Text('Add another page'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop('read'),
              child: const Text('Start reading'),
            ),
          ],
        ),
      );
    }

    if (!mounted) return;
    ref.read(captureProvider(widget.bookId).notifier).reset();

    if (result == 'read') {
      context.go('/book/${widget.bookId}/read/$pageId');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final captureStatus = ref.watch(captureProvider(widget.bookId));

    // React to state changes
    ref.listen(captureProvider(widget.bookId), (prev, next) {
      if (next.state == CaptureState.success && next.savedPageId != null) {
        _handleSuccess(next.savedPageId!);
      } else if (next.state == CaptureState.error &&
          next.errorMessage != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
          ref.read(captureProvider(widget.bookId).notifier).reset();
        }
      }
    });

    final isProcessing = captureStatus.state == CaptureState.processing;

    return AdaptiveScaffold(
      title: 'Capture Page',
      actions: [
        IconButton(
          icon: Icon(_flashIcon),
          onPressed: _isInitialized && !isProcessing ? _toggleFlash : null,
          tooltip: 'Toggle flash',
        ),
        IconButton(
          icon: const Icon(Icons.photo_library),
          onPressed: !isProcessing ? _pickFromGallery : null,
          tooltip: 'Choose from gallery',
        ),
      ],
      body: Scaffold(
        // Inner Scaffold provides ScaffoldMessenger for snackbars
        backgroundColor: Colors.black,
        body: Stack(
        children: [
          // Camera preview or fallback
          if (_permissionDenied)
            _PermissionDeniedView(onRetry: _initCamera)
          else if (!_isInitialized)
            const Center(
              child: AdaptiveProgressIndicator(color: Colors.white),
            )
          else
            Positioned.fill(
              child: CameraPreview(_controller!),
            ),

          // Loading overlay during OCR
          if (isProcessing)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AdaptiveProgressIndicator(color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      'Recognizing text...',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Shutter button at the bottom
          if (!_permissionDenied)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap:
                      _isInitialized && !isProcessing ? _takePicture : null,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: AppColors.primary,
                        width: 4,
                      ),
                    ),
                    child: const Icon(
                      Icons.camera,
                      size: 36,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      ),
    );
  }
}

class _PermissionDeniedView extends StatelessWidget {
  final VoidCallback onRetry;

  const _PermissionDeniedView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt, size: 64, color: Colors.white54),
            const SizedBox(height: 16),
            const Text(
              'Camera access is required to photograph book pages.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
