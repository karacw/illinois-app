import 'dart:async';

import 'package:flutter/material.dart';
import 'package:illinois/model/Canvas.dart';
import 'package:illinois/service/Canvas.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/widgets/TrianglePainter.dart';
import 'package:intl/intl.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class HomeCanvasCoursesWidget extends StatefulWidget {
  final StreamController<void>? refreshController;

  HomeCanvasCoursesWidget({this.refreshController});

  @override
  _HomeCanvasCoursesWidgetState createState() => _HomeCanvasCoursesWidgetState();
}

class _HomeCanvasCoursesWidgetState extends State<HomeCanvasCoursesWidget> implements NotificationsListener {

  List<CanvasCourse>? _courses;

  @override
  void initState() {
    super.initState();

    NotificationService().subscribe(this, [
      FlexUI.notifyChanged,
    ]);


    if (widget.refreshController != null) {
      widget.refreshController!.stream.listen((_) {
        _loadCourses();
      });
    }

    _loadCourses();
  }

  @override
  void dispose() {
    super.dispose();
    NotificationService().unsubscribe(this);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == FlexUI.notifyChanged) {
      _loadCourses();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
        visible: _hasCourses,
        child: Container(
            child: Column(children: [
          _buildHeader(),
          Stack(children: <Widget>[
            _buildSlant(),
            _buildCoursesContent(),
          ])
        ])));
  }

  Widget _buildHeader() {
    return Semantics(
        container: true,
        header: true,
        child: Container(
            color: Styles().colors!.fillColorPrimary,
            child: Padding(
                padding: EdgeInsets.only(left: 20, top: 10, bottom: 10),
                child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Padding(
                      padding: EdgeInsets.only(right: 16),
                      child: Image.asset(
                        'images/campus-tools.png',
                        excludeFromSemantics: true,
                      )),
                  Expanded(
                      child: Text(Localization().getStringEx('widget.home_canvas_courses.header.label', 'Courses')!,
                          style: TextStyle(color: Styles().colors!.white, fontFamily: Styles().fontFamilies!.extraBold, fontSize: 20)))
                ]))));
  }

  Widget _buildSlant() {
    return Column(children: <Widget>[
      Container(color: Styles().colors!.fillColorPrimary, height: 45),
      Container(
          color: Styles().colors!.fillColorPrimary,
          child: CustomPaint(painter: TrianglePainter(painterColor: Styles().colors!.background, left: true), child: Container(height: 65)))
    ]);
  }

  Widget _buildCoursesContent() {
    List<Widget> courseWidgets = <Widget>[];
    if (CollectionUtils.isNotEmpty(_courses)) {
      for (CanvasCourse course in _courses!) {
        courseWidgets.add(_buildCourseCard(course));
      }
    }

    return Center(child: Padding(
        padding: EdgeInsets.only(top: 10, bottom: 20),
        child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Padding(padding: EdgeInsets.only(right: 10, bottom: 6), child: Row(children: courseWidgets)))),);
  }

  Widget _buildCourseCard(CanvasCourse course) {
    final Color defaultColor = Colors.black;
    const double height = 150;
    const double width = 180;
    //TBD: check from which field to take this value
    String completionPercentage = _formatDecimalValue(0);
    Color? mainColor = StringUtils.isNotEmpty(course.courseColor) ? UiColors.fromHex(course.courseColor!) : defaultColor;
    if (mainColor == null) {
      mainColor = defaultColor;
    }

    return Padding(padding: EdgeInsets.only(left: 10), child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
            color: mainColor,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [BoxShadow(color: Styles().colors!.blackTransparent018!, spreadRadius: 2.0, blurRadius: 6.0, offset: Offset(2, 2))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
                  child: Padding(
                      padding: EdgeInsets.only(left: 5, top: 5),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(
                          padding: EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Styles().colors!.white),
                          child: Text('$completionPercentage%', style: TextStyle(color: mainColor, fontSize: 16, fontFamily: Styles().fontFamilies!.bold)))]))),
              Expanded(
              child: Container(
                  color: Styles().colors!.background,
                  child: Padding(
                      padding: EdgeInsets.all(6),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(StringUtils.ensureNotEmpty(course.name), maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: defaultColor, fontSize: 18, fontFamily: Styles().fontFamilies!.extraBold)),
                        Text(StringUtils.ensureNotEmpty(course.courseCode), overflow: TextOverflow.ellipsis, style: TextStyle(color: Styles().colors!.textSurface, fontSize: 16, fontFamily: Styles().fontFamilies!.bold))
                      ]))))
        ])));
  }

  void _loadCourses() {
    Canvas().loadCourses().then((courses) {
      _courses = courses;
      if (mounted) {
        setState(() {});
      }
    });
  }

  String _formatDecimalValue(double num, {int minimumFractionDigits = 0, int maximumFractionDigits = 2}) {
    NumberFormat percentageFormatter = NumberFormat();
    percentageFormatter.minimumFractionDigits = minimumFractionDigits;
    percentageFormatter.maximumFractionDigits = maximumFractionDigits;
    return percentageFormatter.format(num);
  }

  bool get _hasCourses {
    return CollectionUtils.isNotEmpty(_courses);
  }
}
