import 'dart:io';
import 'package:deepar_flutter/deepar_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:media_store_plus/media_store_plus.dart';

import '../constants.dart';
import '../data/filter_data.dart';

class CameraController extends GetxController {
  final DeepArController deepArController = DeepArController();

  var isRecording = false.obs;
  var selectedFilterIndex = (-1).obs;
  var initFuture = Rxn<Future<void>>();

  final pageController = PageController(viewportFraction: 0.25);

  @override
  void onInit() {
    super.onInit();
    MediaStore.ensureInitialized();
    MediaStore.appFolder = 'DeepAR/Videos';
    initFuture.value = initializeController();
  }

  Future<void> initializeController() async {
    await deepArController.initialize(
      androidLicenseKey: licenseKey,
      iosLicenseKey: '',
      resolution: Resolution.high,
    );

    // Just apply default filter (0) on startup
    if (filters.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        applyFilter(0);
        pageController.jumpToPage(0);
      });
    }
  }

  Future<void> capturePhoto() async {
    final filePath = await deepArController.takeScreenshot();
    if (filePath != null) {
      final mediaStore = MediaStore();
      await mediaStore.saveFile(
        tempFilePath: filePath.path,
        dirType: DirType.photo,
        dirName: DirName.dcim,
      );
      Get.snackbar("Success", "Photo saved to gallery");
    }
  }

  Future<void> toggleVideoRecording() async {
    if (!isRecording.value) {
      final Directory dir = await getTemporaryDirectory();
      final String videoPath = '${dir.path}/deepar_video_${DateTime.now().millisecondsSinceEpoch}.mp4';

      await deepArController.startVideoRecording();
      isRecording.value = true;
    } else {
      final filePath = await deepArController.stopVideoRecording();
      if (filePath != null) {
        final mediaStore = MediaStore();
        MediaStore.appFolder = 'DeepAR/Videos';

        await mediaStore.saveFile(
          tempFilePath: filePath.path,
          dirType: DirType.video,
          dirName: DirName.movies,
        );

        Get.snackbar("Success", "Video saved to gallery");
      }
      isRecording.value = false;
    }
  }

  Future<void> applyFilter(int index) async {
    final filter = filters[index];
    final effectFile = File('assets/filters/${filter.filterPath}').path;
    deepArController.switchEffect(effectFile);
    selectedFilterIndex.value = index;

    pageController.animateToPage(index, duration: 300.milliseconds, curve: Curves.easeInOut);
  }

  @override
  void onClose() {
    deepArController.destroy();
    pageController.dispose();
    super.onClose();
  }
}
