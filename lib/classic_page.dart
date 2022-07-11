import 'package:flutter/material.dart';
import 'package:flutter_refresh_component/controller/controller.dart';
import 'package:flutter_refresh_component/easy_refresh.dart';
import 'package:flutter_refresh_component/indicator/indicator.dart';
import 'package:flutter_refresh_component/skeleton_item.dart';
import 'package:flutter_refresh_component/style/classic/footer/classic_footer.dart';
import 'package:flutter_refresh_component/style/classic/header/classic_header.dart';
import 'package:get/get.dart';

class ClassicPage extends StatefulWidget {
  const ClassicPage({Key? key}) : super(key: key);

  @override
  State<ClassicPage> createState() => _ClassicPageState();
}

class _ClassicPageState extends State<ClassicPage> {
  late EasyRefreshController _controller;
  int _count = 10;
  Axis _scrollDirection = Axis.vertical;
  final _CIProperties _headerProperties = _CIProperties(
    name: 'Header',
    alignment: MainAxisAlignment.center,
    infinite: false,
  );
  final _CIProperties _footerProperties = _CIProperties(
    name: 'Footer',
    alignment: MainAxisAlignment.start,
    infinite: true,
  );

  @override
  void initState() {
    super.initState();
    _controller = EasyRefreshController(
      controlFinishRefresh: true,
      controlFinishLoad: true,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Classic'.tr),
      ),
      body: EasyRefresh(
        controller: _controller,
        header: ClassicHeader(
          clamping: _headerProperties.clamping,
          backgroundColor: _headerProperties.background
              ? Theme.of(context).colorScheme.surfaceVariant
              : null,
          mainAxisAlignment: _headerProperties.alignment,
          showMessage: _headerProperties.message,
          showText: _headerProperties.text,
          infiniteOffset: _headerProperties.infinite ? 70 : null,
          dragText: 'Pull to refresh'.tr,
          armedText: 'Release ready'.tr,
          readyText: 'Refreshing...'.tr,
          processingText: 'Refreshing...'.tr,
          processedText: 'Succeeded'.tr,
          noMoreText: 'No more'.tr,
          failedText: 'Failed'.tr,
          messageText: 'Last updated at %T'.tr,
        ),
        footer: ClassicFooter(
          clamping: _footerProperties.clamping,
          backgroundColor: _footerProperties.background
              ? Theme.of(context).colorScheme.surfaceVariant
              : null,
          mainAxisAlignment: _footerProperties.alignment,
          showMessage: _footerProperties.message,
          showText: _footerProperties.text,
          infiniteOffset: _footerProperties.infinite ? 70 : null,
          dragText: 'Pull to load'.tr,
          armedText: 'Release ready'.tr,
          readyText: 'Loading...'.tr,
          processingText: 'Loading...'.tr,
          processedText: 'Succeeded'.tr,
          noMoreText: 'No more'.tr,
          failedText: 'Failed'.tr,
          messageText: 'Last updated at %T'.tr,
        ),
        onRefresh: _headerProperties.disable
            ? null
            : () async {
          await Future.delayed(const Duration(seconds: 2));
          if (!mounted) {
            return;
          }
          setState(() {
            _count = 10;
          });
          _controller.finishRefresh();
          _controller.resetFooter();
        },
        onLoad: _footerProperties.disable
            ? null
            : () async {
          await Future.delayed(const Duration(seconds: 2));
          if (!mounted) {
            return;
          }
          setState(() {
            _count += 5;
          });
          _controller.finishLoad(_count >= 20
              ? IndicatorResult.noMore
              : IndicatorResult.success);
        },
        child: ListView.builder(
          clipBehavior: Clip.none,
          scrollDirection: _scrollDirection,
          padding: EdgeInsets.zero,
          itemCount: _count,
          itemBuilder: (ctx, index) {
            return SkeletonItem(
              direction: _scrollDirection,
            );
          },
        ),
      ),
    );
  }
}

/// Classic indicator properties.
class _CIProperties {
  final String name;
  bool disable = false;
  bool clamping = false;
  bool background = false;
  MainAxisAlignment alignment;
  bool message = true;
  bool text = true;
  bool infinite;

  _CIProperties({
    required this.name,
    required this.alignment,
    required this.infinite,
  });
}
