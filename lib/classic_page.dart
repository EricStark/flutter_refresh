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

class _ClassicPageState extends State<ClassicPage> with SingleTickerProviderStateMixin{
  late EasyRefreshController _controller;
  late AnimationController _animationController;
  bool clickFloatBtn_expanded = false;
  int _expandedIndex = -1;
  int _count = 10;
  Duration floatButtonAnimationDuration = const Duration(milliseconds: 300);
  Axis _scrollDirection = Axis.vertical;
  ///设置property
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
    ///设置controller
    _controller = EasyRefreshController(
      controlFinishRefresh: true,
      controlFinishLoad: true,
    );
    _animationController = AnimationController(vsync: this, duration: floatButtonAnimationDuration)
      ..drive(Tween(begin: 0, end: 1));
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final propertiesItems = [_headerProperties, _footerProperties];
    return Scaffold(
      appBar: AppBar(
        title: Text('Joma'.tr),
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
      /// 悬浮按钮
      floatingActionButton: FloatingActionButton(
        child: AnimatedIcon(
          icon: AnimatedIcons.menu_close,
          progress: _animationController,
        ),
        onPressed: () {
          setState(() {
            clickFloatBtn_expanded = !clickFloatBtn_expanded;
          });
          _animationController.animateTo(clickFloatBtn_expanded ? 1 : 0);
        },
      ),
      /// 下面是点击按钮后展开的部分
      bottomNavigationBar: AnimatedContainer(
        duration: floatButtonAnimationDuration,
        height: clickFloatBtn_expanded ? 400 : 0,
        child: SingleChildScrollView(
          child: Column(
            children: [
              ListTile(
                title: Text('Direction'.tr),
                trailing: IntrinsicWidth(
                  child: Row(
                    children: [
                      Radio<Axis>(
                        value: Axis.vertical,
                        groupValue: _scrollDirection,
                        onChanged: (value) {
                          setState(() {
                            _scrollDirection = value!;
                          });
                        },
                      ),
                      Text('Vertical'.tr),
                      Radio<Axis>(
                        value: Axis.horizontal,
                        groupValue: _scrollDirection,
                        onChanged: (value) {
                          setState(() {
                            _scrollDirection = value!;
                          });
                        },
                      ),
                      Text('Horizontal'.tr),
                    ],
                  ),
                ),
              ),
              ExpansionPanelList(
                dividerColor: Colors.transparent,
                expansionCallback: (panelIndex, isExpanded) {
                  setState(() {
                    if (!isExpanded) {
                      _expandedIndex = panelIndex;
                    } else {
                      _expandedIndex = -1;
                    }
                  });
                },
                children: [
                  for (int i = 0; i < propertiesItems.length; i++)
                    ExpansionPanel(
                      canTapOnHeader: true,
                      headerBuilder: (ctx, isExpanded) {
                        return ListTile(
                          title: Text(propertiesItems[i].name),
                          selected: isExpanded,
                        );
                      },
                      body: Builder(
                        builder: (ctx) {
                          final properties = propertiesItems[i];
                          return Column(
                            children: [
                              ListTile(
                                title: Text('Disable'.tr),
                                trailing: Switch(
                                  value: properties.disable,
                                  onChanged: (value) {
                                    setState(() {
                                      properties.disable = value;
                                    });
                                  },
                                ),
                              ),
                              ListTile(
                                title: Text('Clamping'.tr),
                                trailing: Switch(
                                  value: properties.clamping,
                                  onChanged: (value) {
                                    setState(() {
                                      properties.clamping = value;
                                      if (value && properties.infinite) {
                                        properties.infinite = false;
                                      }
                                    });
                                  },
                                ),
                              ),
                              ListTile(
                                title: Text('Background'.tr),
                                trailing: Switch(
                                  value: properties.background,
                                  onChanged: (value) {
                                    setState(() {
                                      properties.background = value;
                                    });
                                  },
                                ),
                              ),
                              ListTile(
                                title: Text('Alignment'.tr),
                                trailing: IntrinsicWidth(
                                  child: Row(
                                    children: [
                                      Radio<MainAxisAlignment>(
                                        value: MainAxisAlignment.center,
                                        groupValue: properties.alignment,
                                        onChanged: (value) {
                                          setState(() {
                                            properties.alignment = value!;
                                          });
                                        },
                                      ),
                                      Text('Center'.tr),
                                      Radio<MainAxisAlignment>(
                                        value: MainAxisAlignment.start,
                                        groupValue: properties.alignment,
                                        onChanged: (value) {
                                          setState(() {
                                            properties.alignment = value!;
                                          });
                                        },
                                      ),
                                      Text('Start'.tr),
                                      Radio<MainAxisAlignment>(
                                        value: MainAxisAlignment.end,
                                        groupValue: properties.alignment,
                                        onChanged: (value) {
                                          setState(() {
                                            properties.alignment = value!;
                                          });
                                        },
                                      ),
                                      Text('End'.tr),
                                    ],
                                  ),
                                ),
                              ),
                              ListTile(
                                title: Text('Infinite'.tr),
                                trailing: Switch(
                                  value: properties.infinite,
                                  onChanged: (value) {
                                    setState(() {
                                      properties.infinite = value;
                                      if (value && properties.clamping) {
                                        properties.clamping = false;
                                      }
                                    });
                                  },
                                ),
                              ),
                              ListTile(
                                title: Text('Message'.tr),
                                trailing: Switch(
                                  value: properties.message,
                                  onChanged: (value) {
                                    setState(() {
                                      properties.message = value;
                                    });
                                  },
                                ),
                              ),
                              ListTile(
                                title: Text('Text'.tr),
                                trailing: Switch(
                                  value: properties.text,
                                  onChanged: (value) {
                                    setState(() {
                                      properties.text = value;
                                    });
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      isExpanded: _expandedIndex == i,
                    ),
                ],
              ),
            ],
          ),
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
