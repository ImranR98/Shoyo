import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shoyo/custom_app_bar.dart';
import 'dart:async';
import 'package:path/path.dart';

import 'package:flutter_sharing_intent/flutter_sharing_intent.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const Shoyo());
}

class Shoyo extends StatelessWidget {
  const Shoyo({super.key});

  @override
  Widget build(BuildContext context) {
    ThemeData theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
      useMaterial3: true,
    );
    ThemeData darkTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red.shade400, brightness: Brightness.dark),
      useMaterial3: true,
    );
    return MaterialApp(
      title: 'Shoyo',
      theme: theme,
      darkTheme: darkTheme,
      home: const MainPage(title: 'Shoyo'),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key, required this.title});
  final String title;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late StreamSubscription _intentDataStreamSubscription;
  List<MapEntry<String, String?>>? results;

  @override
  void initState() {
    super.initState();
    _intentDataStreamSubscription =
        FlutterSharingIntent.instance.getMediaStream().listen(saveSharedFiles);
    FlutterSharingIntent.instance.getInitialSharing().then(saveSharedFiles);
  }

  Future<void> saveSharedFiles(List<SharedFile> sharedFiles) async {
    if (!(await Permission.manageExternalStorage.isGranted)) {
      Fluttertoast.showToast(msg: 'This permission is required.');
      await Permission.manageExternalStorage.request();
    }
    if (await Permission.manageExternalStorage.isGranted &&
        sharedFiles.isNotEmpty) {
      List<String> files = sharedFiles
          .map((a) => a.value ?? '')
          .where((f) => f.isNotEmpty)
          .toList();
      String downloadsDir = '/storage/emulated/0/Download';
      results = await Future.wait(files.map((f) async {
        String fileName = basename(f);
        try {
          File(f).copySync('$downloadsDir/$fileName');
          return MapEntry<String, String?>(fileName, null);
        } catch (e) {
          return MapEntry<String, String?>(fileName, e.toString());
        }
      }));
    } else {
      results = null;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    String message = 'No Files Saved.';
    String subtitle =
        'Share files from other apps\nto save them locally via ${widget.title}.';
    String errorMessage = '';
    List<MapEntry<String, String>> errors = [];
    if (results != null) {
      int savedFileCount = 0;
      for (var r in results!) {
        if (r.value == null) {
          savedFileCount++;
        } else {
          errors.add(MapEntry(r.key, r.value!));
        }
        message =
            '$savedFileCount of ${results!.length} File${results!.length == 1 ? '' : 's'} Saved to Downloads.';
        errorMessage = '';
        for (MapEntry<String, String> e in errors) {
          errorMessage += '${e.key}: ${e.value}\n\n';
        }
        errorMessage = errorMessage.trim();
      }
    }
    return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: CustomScrollView(slivers: <Widget>[
          CustomAppBar(title: widget.title),
          SliverFillRemaining(
              child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                  child: results == null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              message,
                              style: Theme.of(context).textTheme.displaySmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(
                              height: 32,
                            ),
                            Text(subtitle, textAlign: TextAlign.center),
                            const SizedBox(
                              height: 64,
                            )
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              message,
                              style: Theme.of(context).textTheme.titleLarge,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(
                              height: 32,
                            ),
                            Text(
                              errorMessage,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(fontFamily: 'monospace'),
                            ),
                            const SizedBox(
                              height: 32,
                            )
                          ],
                        )))
        ]));
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }
}

void showSnackBar(BuildContext ctx, String message) {
  ScaffoldMessenger.of(ctx).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
