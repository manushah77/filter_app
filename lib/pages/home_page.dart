import 'dart:io';
import 'package:deepar_flutter/deepar_flutter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:media_store_plus/media_store_plus.dart';

import '../camera_controller/camera_controller.dart';
import '../constants.dart';
import '../data/filter_data.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final CameraController controller = Get.put(CameraController());

  Widget buildCameraPreview() => SizedBox(
    height: Get.height * 0.82,
    child: Transform.scale(
      scale: 1.5,
      child: DeepArPreview(controller.deepArController),
    ),
  );

  Widget buildButtons() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    children: [
      IconButton(
          onPressed: controller.deepArController.flipCamera,
          icon: const Icon(Icons.flip_camera_ios_outlined, size: 34, color: Colors.white)),
      Obx(() => controller.isRecording.value ? SizedBox.shrink() : FilledButton(onPressed: controller.capturePhoto, child: const Icon(Icons.camera_alt)),),

      Obx(() => FilledButton(
          onPressed: controller.toggleVideoRecording,
          child: Icon(controller.isRecording.value ? Icons.stop : Icons.videocam))),
      controller.isRecording.value ? SizedBox(width: 20,) : SizedBox(width: 0,),
      IconButton(
          onPressed: controller.deepArController.toggleFlash,
          icon: const Icon(Icons.flash_on, size: 34, color: Colors.white)),
    ],
  );

  Widget buildFilters() {
    final double filterHeight = Get.height * 0.1;

    return Obx(() {
      if (controller.isRecording.value) {
        final index = controller.selectedFilterIndex.value;
        if (index == -1) return SizedBox(height: filterHeight);

        final filter = filters[index];
        return SizedBox(
          height: filterHeight,
          child: Center(
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                color: Colors.white,
                image: DecorationImage(
                  image: AssetImage('assets/previews/${filter.imagePath}'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        );
      }

      return SizedBox(
        height: filterHeight,
        child: PageView.builder(
          controller: controller.pageController,
          itemCount: filters.length,
          scrollDirection: Axis.horizontal,
          onPageChanged: controller.applyFilter,
          itemBuilder: (context, index) {
            return Obx(() {
              final filter = filters[index];
              final isSelected = controller.selectedFilterIndex.value == index;

              return GestureDetector(
                onTap: () => controller.applyFilter(index),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      color: Colors.white,
                      image: DecorationImage(
                        image: AssetImage('assets/previews/${filter.imagePath}'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    width: 55,
                    height: 55,
                  ),
                ),
              );
            });
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(() {
        final future = controller.initFuture.value;
        if (future == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return FutureBuilder(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return Column(
                  children: [buildCameraPreview(), buildButtons(), buildFilters()]);
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        );
      }),
    );
  }
}
