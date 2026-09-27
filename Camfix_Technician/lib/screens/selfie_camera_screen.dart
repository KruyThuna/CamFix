import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../lang_aware.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

class SelfieCameraScreen extends StatefulWidget {
  const SelfieCameraScreen({super.key});

  @override
  State<SelfieCameraScreen> createState() => _SelfieCameraScreenState();
}

class _SelfieCameraScreenState extends State<SelfieCameraScreen>
    with WidgetsBindingObserver, LangAware<SelfieCameraScreen> {
  CameraController? _camera;
  Uint8List? _photo;
  bool _loading = true;
  bool _capturing = false;
  String? _error;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _openCamera();
  }

  Future<void> _openCamera() async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    CameraController? next;
    try {
      final cameras = await availableCameras();
      if (!mounted || generation != _generation) return;
      if (cameras.isEmpty) {
        throw CameraException('NoCamera', 'No camera available');
      }
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      next = CameraController(front, ResolutionPreset.high, enableAudio: false);
      await next.initialize();
      if (!mounted || generation != _generation) {
        await next.dispose();
        return;
      }
      setState(() {
        _camera = next;
        _loading = false;
      });
    } catch (_) {
      await next?.dispose();
      if (mounted && generation == _generation) {
        setState(() {
          _error = 'cameraUnavailable';
          _loading = false;
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      ++_generation;
      final camera = _camera;
      _camera = null;
      camera?.dispose();
      if (mounted) setState(() => _loading = true);
    } else if (state == AppLifecycleState.resumed &&
        _photo == null &&
        _camera == null) {
      _openCamera();
    }
  }

  Future<void> _capture() async {
    final camera = _camera;
    if (camera == null || _capturing) return;
    setState(() => _capturing = true);
    try {
      final file = await camera.takePicture();
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      if (bytes.length > 5 * 1024 * 1024) {
        showError(context, AppStrings.t('photoTooLarge'));
        return;
      }
      setState(() {
        _photo = bytes;
        _camera = null;
      });
      ++_generation;
      await camera.dispose();
    } catch (_) {
      if (mounted) showError(context, AppStrings.t('cameraCaptureFailed'));
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  @override
  void dispose() {
    ++_generation;
    WidgetsBinding.instance.removeObserver(this);
    _camera?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('facePhotoTitle'))),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(AppStrings.t(_photo == null ? 'faceFrameHint' : 'reviewFacePhoto'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Text(
                  AppStrings.t('facePhotoHelp'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.pal.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: AspectRatio(
                    aspectRatio: 4 / 5,
                    child: ColoredBox(
                      color: const Color(0xFF151B2D),
                      child: _photo != null
                          ? Image.memory(_photo!, fit: BoxFit.cover, alignment: Alignment.center)
                          : _error != null
                          ? Padding(
                              padding: const EdgeInsets.all(24),
                              child: Center(
                                child: Text(
                                  AppStrings.t(_error!),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            )
                          : _loading || _camera == null
                          ? const Center(child: CircularProgressIndicator())
                          : Stack(
                              alignment: Alignment.center,
                              children: [
                                Center(child: CameraPreview(_camera!, child:
                                IgnorePointer(
                                  child: Center(child: FractionallySizedBox(
                                    widthFactor: .68,
                                    heightFactor: .86,
                                    child: DecoratedBox(
                                      decoration: ShapeDecoration(
                                        shape: OvalBorder(
                                          side: BorderSide(color: Colors.white70, width: 2),
                                        ),
                                      ),
                                    ),
                                  )),
                                ),
                                )),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (_photo != null) ...[
                  PrimaryButton(
                    label: AppStrings.t('useFacePhoto'),
                    onPressed: () => Navigator.pop(context, _photo),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: BorderSide(color: context.pal.border),
                    ),
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: () {
                      setState(() => _photo = null);
                      _openCamera();
                    },
                    label: Text(AppStrings.t('retakeFacePhoto')),
                  ),
                ] else if (_error != null)
                  PrimaryButton(
                    label: AppStrings.t('retryCamera'),
                    onPressed: _openCamera,
                  )
                else
                  Column(children: [
                    SizedBox(width: 80, height: 80,
                      child: IconButton.filled(
                        tooltip: AppStrings.t('captureFacePhoto'),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _loading || _capturing ? null : _capture,
                        icon: _capturing
                            ? const SizedBox(width: 26, height: 26,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.camera_alt_rounded, size: 30),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(AppStrings.t('captureFacePhoto'),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
