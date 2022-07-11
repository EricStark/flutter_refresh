import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_refresh_component/classic_page.dart';
import 'package:flutter_refresh_component/easy_refresh.dart';
import 'package:flutter_refresh_component/style/classic/footer/classic_footer.dart';
import 'package:flutter_refresh_component/style/classic/header/classic_header.dart';
import 'package:get/get.dart';
import 'package:get/get_utils/src/platform/platform.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {

  final _appKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    Widget app = GetMaterialApp(
      key: _appKey,
      title: 'EasyRefresh',
      locale: Get.deviceLocale,
      home: ClassicPage()
    );
    return app;
  }
}
