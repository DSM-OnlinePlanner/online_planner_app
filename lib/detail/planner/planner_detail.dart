import 'dart:io';

import 'package:bottom_picker/bottom_picker.dart';
import 'package:dio/dio.dart';
import 'package:f_datetimerangepicker/f_datetimerangepicker.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animated_dialog/flutter_animated_dialog.dart';
import 'package:flutter_swipe_action_cell/core/cell.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:imagebutton/imagebutton.dart';
import 'package:intl/intl.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:online_planner_app/detail/planner/WritePlanner.dart';
import 'package:online_planner_app/detail/login/login_detail.dart';
import 'package:online_planner_app/detail/planner/ReadPlanner.dart';
import 'package:online_planner_app/detail/record/record_detail.dart';
import 'package:online_planner_app/detail/user_info/user_info_detail.dart';
import 'package:online_planner_app/login/login_page.dart';
import 'package:online_planner_app/main/main_page.dart';
import 'package:online_planner_app/main/notice_page.dart';
import 'package:outline_search_bar/outline_search_bar.dart';
import 'package:page_transition/page_transition.dart';
import 'package:progress_indicators/progress_indicators.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../SideMenuWidget.dart';

class PlannerPage extends StatefulWidget {
  String tier = "", date = "";

  PlannerPage(this.tier, this.date);

  _PlannerWidget createState() => _PlannerWidget(tier, date);
}

class _PlannerWidget extends State<PlannerPage> {
  _PlannerWidget(this.initTier, this.date);

  ScrollController _scrollController = ScrollController();

  int pageNum = 0;

  String date = "";

  String initTier = "";
  String nickName = "", tier = "";
  int exp = -1, maxExp = -1, userLevel = -1;

  late UserInfo userInfo;

  late SearchPlanner searchPlanner;
  late SearchRoutine searchRoutine;

  List<Planner> plannerItem = [];
  late Future<List<Planner>> fPlannerItem;

  String imageName = "";

  String pageName = "할일", title = "";

  bool successFailed = false, isSetImage = false;

  int _fragType = 0;

  Color bellColor = Color(0xff585858);
  Color searchColor = Color(0xff585858);

  bool _isBell = false;
  bool _isSearch = false;

  PageController _mainPageController = PageController(
    initialPage: 0,
  );

  late SharedPreferences _preferences;
  bool _notSearch = true;

  final String url = 'http://220.90.237.33:7070';

  Future<List<Planner>> _getPlanner() async {
    _preferences = await SharedPreferences.getInstance();
    try {
      Dio dio = Dio();
      final response =
          await dio.get(url + '/planner/' + pageNum.toString(), options: Options(headers: {HttpHeaders.authorizationHeader: _preferences.getString('accessToken')}), queryParameters: {'date': date});

      if (response.statusCode == 200) {
        if(plannerItem.isNotEmpty)
          plannerItem.addAll((response.data as List).map((e) => Planner.fromJson(e)).toList());
        else
          plannerItem = (response.data as List).map((e) => Planner.fromJson(e)).toList();
      }
      return plannerItem;
    } catch (e) {
      await _retryPlanner();
      print(e);

      return plannerItem;
    }
  }

  _retryPlanner() async {
    _preferences = await SharedPreferences.getInstance();
    try {
      Dio dio = Dio();
      final response =
          await dio.get(url + '/planner/' + pageNum.toString(), options: Options(headers: {HttpHeaders.authorizationHeader: _preferences.getString('accessToken')}), queryParameters: {'date': date});

      if (response.statusCode == 200) {
        plannerItem.addAll((response.data as List).map((e) => Planner.fromJson(e)).toList());
      }
      return plannerItem;
    } catch (e) {
      print(e);
      await _logout();
    }
  }

  _logout() async {
    FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
    try {
      Dio dio = Dio();
      final response = await dio.delete(url + '/user/logout', options: Options(headers: {HttpHeaders.contentTypeHeader: "application/json", "deviceToken": await firebaseMessaging.getToken() ?? ""}));

      if (response.statusCode == 200) {
        _preferences.remove("isAuth");
        _preferences.remove("accessToken");
        _preferences.remove("refreshToken");
        _preferences.remove("userImage");

        Navigator.of(context).pushAndRemoveUntil(PageTransition(child: StartPage(), type: PageTransitionType.bottomToTop), (route) => false);
      }
    } catch (e) {
      print(e);
    }
  }

  _setFragState() {
    if (_fragType == 0) {
      setState(() {
        bellColor = Color(0xffD1D1D1);
        searchColor = Color(0xff585858);
      });
    } else if (_fragType == 1) {
      setState(() {
        if (_isBell) {
          bellColor = Color(0xff585858);
          _isSearch = false;
          _mainPageController.jumpToPage(0);
          pageName = '할일';
        } else {
          bellColor = Color(0xffD1D1D1);
          searchColor = Color(0xff585858);
          _fragType = 1;
          _isSearch = false;
          _mainPageController.jumpToPage(1);
          pageName = "알림";
        }

        _isBell = !_isBell;
      });
    } else if (_fragType == 2) {
      setState(() {
        if (_isSearch) {
          searchColor = Color(0xff585858);
          _fragType = 0;
          _isBell = false;
          _mainPageController.jumpToPage(0);
          pageName = '할일';
          _notSearch = true;
        } else {
          searchColor = Color(0xffD1D1D1);
          bellColor = Color(0xff585858);
          _fragType = 2;
          _isBell = false;
          _mainPageController.jumpToPage(2);
          pageName = '검색';
        }

        _isSearch = !_isSearch;
      });
    }
  }

  _succeedPlanner(int plannerId) async {
    try {
      Dio dio = Dio();
      final response = await dio.put(url + '/planner/check/' + plannerId.toString(), options: Options(headers: {HttpHeaders.authorizationHeader: _preferences.getString('accessToken') ?? ""}));

      if (response.statusCode == 200) {
        _showTaost('할 일을 성공하셨습니다');

        successFailed = true;
      }
    } catch (e) {
      print(e.toString());

      if (e.toString().contains('409')) {
        _showTaost('할 일이 이미 실패했습니다..');
        return;
      }

      await _retrySucceedPlanner(plannerId);
    }
  }

  _retrySucceedPlanner(int plannerId) async {
    await _refreshToken();
    try {
      Dio dio = Dio();
      final response = await dio.put(url + '/planner/check/' + plannerId.toString(), options: Options(headers: {HttpHeaders.authorizationHeader: _preferences.getString('accessToken') ?? ""}));

      if (response.statusCode == 200) {
        _showTaost('할 일을 성공하셨습니다');

        successFailed = true;
      }
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> failedPlanner(int plannerId) async {
    try {
      Dio dio = Dio();
      final response = await dio.put(url + '/planner/failed/' + plannerId.toString(), options: Options(headers: {HttpHeaders.authorizationHeader: _preferences.getString('accessToken') ?? ""}));

      if (response.statusCode == 200) {
        _showTaost('할 일을 실패하셨습니다');

        successFailed = true;
      }
    } catch (e) {
      print(e.toString());

      if (e.toString().contains('409')) {
        _showTaost('할 일이 이미 성공했습니다!');
        return;
      }

      await _retryFailedPlanner(plannerId);
    }
  }

  _retryFailedPlanner(int plannerId) async {
    await _refreshToken();
    try {
      Dio dio = Dio();
      final response = await dio.put(url + '/planner/failed/' + plannerId.toString(), options: Options(headers: {HttpHeaders.authorizationHeader: _preferences.getString('accessToken') ?? ""}));

      if (response.statusCode == 200) {
        _showTaost('할 일을 실패하셨습니다');

        successFailed = true;
      }
    } catch (e) {
      print(e.toString());

      if (e.toString().contains('409')) {
        _showTaost('할 일이 이미 성공했습니다!');
        return;
      }
      _preferences.remove("isAuth");
      _preferences.remove("accessToken");
      _preferences.remove("refreshToken");
      _preferences.remove("userImage");

      Navigator.of(context).pushAndRemoveUntil(PageTransition(child: StartPage(), type: PageTransitionType.bottomToTop), (route) => false);
    }
  }

  Future<SearchRoutine> _searchRoutine(String title) async {
    _preferences = await SharedPreferences.getInstance();

    try {
      Dio dio = Dio();
      final response =
          await dio.get(url + '/routine/search', options: Options(headers: {HttpHeaders.authorizationHeader: _preferences.getString('accessToken') ?? ""}), queryParameters: {'title': title});

      if (response.statusCode == 200) {
        searchRoutine = SearchRoutine.fromJson(response.data);

        return searchRoutine;
      } else {
        await _refreshToken();
        return _searchRoutine(title);
      }
    } catch (e) {
      print('search page routine : ' + e.toString());

      await _refreshToken();
      return _searchRoutine(title);
    }
  }

  Future<bool> _refreshToken() async {
    Dio dio = Dio();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    try {
      final response = await dio.put(url + '/auth', options: Options(headers: {HttpHeaders.contentTypeHeader: 'application/json', 'X-Refresh-Token': sharedPreferences.getString('refreshToken')}));

      if (response.statusCode == 200) {
        _preferences = await SharedPreferences.getInstance();

        var token = Token.fromJson(response.data);

        _preferences.setString("accessToken", token.accessToken);
        _preferences.setString("refreshToken", token.refreshToken);

        return true;
      } else {
        await _logout();
        return false;
      }
    } catch (e) {
      print("refreshToken in mainPage : " + e.toString());
      await _logout();
      return false;
    }
  }

  Future<SearchPlanner> _searchPlanner(String title) async {
    _preferences = await SharedPreferences.getInstance();
    try {
      Dio dio = Dio();
      final response =
          await dio.get(url + '/planner/search', options: Options(headers: {HttpHeaders.authorizationHeader: _preferences.getString('accessToken') ?? ""}), queryParameters: {'title': title});

      if (response.statusCode == 200) {
        searchPlanner = SearchPlanner.fromJson(response.data);

        return searchPlanner;
      } else {
        await _refreshToken();
        return _searchPlanner(title);
      }
    } catch (e) {
      print('search page : ' + e.toString());

      await _refreshToken();
      return _searchPlanner(title);
    }
  }

  _latePlanner(int plannerId, DateTime startDate, DateTime endDate) async {
    try {
      Dio dio = Dio();
      final response = await dio
          .put(url + '/planner/check/' + plannerId.toString(), options: Options(headers: {HttpHeaders.authorizationHeader: _preferences.getString('accessToken') ?? ""}), data: <String, dynamic>{
        'startDate': DateFormat("yyyy-MM-dd").format(startDate),
        'endDate': DateFormat("yyyy-MM-dd").format(endDate),
        'startTime': DateFormat("HH:mm:ss").format(startDate),
        'endTime': DateFormat("HH:mm:ss").format(endDate)
      });

      if (response.statusCode == 200) {
        _showTaost('할일을 미뤘습니다');

        successFailed = true;
      }
    } catch (e) {
      print(e);
      await _retryLatePlanner(plannerId, startDate, endDate);
    }
  }

  _retryLatePlanner(int plannerId, DateTime startDate, DateTime endDate) async {
    await _refreshToken();
    try {
      Dio dio = Dio();
      final response = await dio
          .put(url + '/planner/check/' + plannerId.toString(), options: Options(headers: {HttpHeaders.authorizationHeader: _preferences.getString('accessToken') ?? ""}), data: <String, dynamic>{
        'startDate': DateFormat("yyyy-MM-dd").format(startDate),
        'endDate': DateFormat("yyyy-MM-dd").format(endDate),
        'startTime': DateFormat("HH:mm:ss").format(startDate),
        'endTime': DateFormat("HH:mm:ss").format(endDate)
      });

      if (response.statusCode == 200) {
        _showTaost('할 일을 성공하셨습니다');

        successFailed = true;
      }
    } catch (e) {
      await _logout();
    }
  }

  _showTaost(String message) {
    return Fluttertoast.showToast(msg: message, textColor: Colors.black, backgroundColor: Colors.grey, gravity: ToastGravity.BOTTOM, fontSize: 15);
  }

  _setUserImage() {
    print("set" + initTier);

    if (initTier == "A4 용지") {
      setState(() {
        imageName = 'assets/images/just_paper.png';
      });
    } else if (initTier == "무료 플래너") {
      setState(() {
        imageName = 'assets/images/free_paper.png';
      });
    } else if (initTier == "스프링 노트 플래너") {
      setState(() {
        imageName = 'assets/images/spring_planner.png';
      });
    } else if (initTier == "플라스틱 커버 플래너") {
      setState(() {
        imageName = 'assets/images/plastic_planner.png';
      });
    } else if (initTier == "가죽 슬러브 플래너") {
      setState(() {
        imageName = 'assets/images/gaguck_planner.png';
      });
    } else if (initTier == "고급 가죽 슬러브 플래너") {
      setState(() {
        imageName = 'assets/images/good_gaguck_planner.png';
      });
    } else if (initTier == "맞춤 재작 플래너") {
      setState(() {
        imageName = 'assets/images/best_planner.png';
      });
    } else if (initTier == "최고의 플래너") {
      setState(() {
        imageName = 'assets/images/end_tier.png';
      });
    } else if (initTier.isEmpty) {
      _logout();
    }
  }

  _checkUserImage() {
    if (initTier.isNotEmpty) {
      _setUserImage();
      isSetImage = true;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        print('position');
        if (plannerItem.length >= 40) {
          print('length');
          setState(() {
            pageNum++;
            _getPlanner();
          });
        }
      }
    });
    fPlannerItem = _getPlanner();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var _height = MediaQuery.of(context).size.height;
    var _width = MediaQuery.of(context).size.width;

    _checkUserImage();

    return Scaffold(
      backgroundColor: Color(0xffFBFBFB),
      drawer: SideMenuWidget(tier: initTier),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Color(0xffFBFBFB),
        toolbarHeight: 60,
        centerTitle: false,
        title: Text(
          pageName,
          style: TextStyle(fontFamily: 'NotoSansKR', fontWeight: FontWeight.w700, fontSize: 26, color: Color(0xff2C2C2C)),
        ),
        titleSpacing: 0,
        leading: Container(
            child: Builder(
                builder: (context) => Container(
                      margin: EdgeInsets.only(left: 10),
                      child: IconButton(
                        icon: Icon(Icons.menu),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                        color: Color(0xff2C2C2C),
                        iconSize: 35,
                      ),
                    ))),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                  child: IconButton(
                      onPressed: () {
                        _fragType = 1;
                        _setFragState();
                      },
                      icon: Icon(Icons.notifications_none),
                      iconSize: 40,
                      color: bellColor)),
              Container(
                margin: EdgeInsets.only(right: 10),
                child: IconButton(
                  onPressed: () {
                    _fragType = 2;
                    _setFragState();
                  },
                  icon: Icon(Icons.search),
                  iconSize: 40,
                  color: searchColor,
                ),
              ),
              Container(
                margin: EdgeInsets.only(right: 20),
                child: ImageButton(
                  children: [],
                  unpressedImage: Image.asset(imageName, fit: BoxFit.fill),
                  pressedImage: Image.asset(imageName, fit: BoxFit.fill),
                  onTap: () {
                    Navigator.of(context).push(PageTransition(child: UserInfoPage(), type: PageTransitionType.bottomToTop));
                  },
                  width: 42,
                  height: 42,
                ),
                width: 42,
                height: 42,
              )
            ],
          ),
        ],
      ),
      body: PageView(
        physics: NeverScrollableScrollPhysics(),
        controller: _mainPageController,
        children: [
          SingleChildScrollView(
            child: Container(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Container(
                              margin: EdgeInsets.only(top: 10, left: _width * 0.061),
                              child: Text(
                                '할 일',
                                style: TextStyle(fontFamily: 'NotoSansKR', fontWeight: FontWeight.w700, fontSize: 28, color: Color(0xff000000)),
                              ),
                            )
                          ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            margin: EdgeInsets.only(top: 10, right: _width * 0.061),
                            child: IconButton(
                              icon: Icon(
                                Icons.add_rounded,
                                color: Color(0xff000000),
                                size: 40,
                              ),
                              onPressed: () {
                                showCupertinoModalBottomSheet(context: context, builder: (context) => WritePlannerWidget());
                                setState(() {
                                  fPlannerItem = _getPlanner();
                                });
                              },
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Container(
                                margin: EdgeInsets.only(left: _width * 0.061),
                                child: TextButton(
                                  onPressed: () {
                                    BottomPicker.date(
                                      title: '날짜를 선택해주세요!',
                                      titleStyle: TextStyle(fontFamily: 'NotoSansKR', fontWeight: FontWeight.w700, fontSize: 20, color: Color(0xff2C2C2C)),
                                      initialDateTime: DateTime.now(),
                                      onSubmit: (val) {
                                        setState(() {
                                          date = DateFormat("yyyy-MM-dd").format(val);
                                        });
                                      },
                                      maxDateTime: DateTime(DateTime.now().year, DateTime.december, 31),
                                      minDateTime: DateTime(DateTime.now().year, DateTime.january, 1),
                                    ).show(context);
                                  },
                                  child: Text(
                                    date,
                                    style: TextStyle(fontFamily: 'NotoSansKR', fontWeight: FontWeight.w700, fontSize: 18, color: Color(0xff9B9B9B)),
                                  ),
                                )),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            margin: EdgeInsets.only(right: _width * 0.061),
                            child: TextButton(
                              onPressed: () {
                                Navigator.pushAndRemoveUntil(context, PageTransition(child: RecordPage(initTier, date), type: PageTransitionType.bottomToTop), (route) => false);
                              },
                              child: Text(
                                '이날 기록 보기',
                                style: TextStyle(fontFamily: 'NotoSansKR', fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xff2F5DFB)),
                              ),
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                  Center(
                    child: Container(
                      margin: EdgeInsets.only(top: 10),
                      child: FutureBuilder<List<Planner>>(
                        future: _getPlanner(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData == false) {
                            return Center(
                              child: FadingText(
                                'Loading..',
                                style: TextStyle(fontFamily: 'NotoSansKR', fontWeight: FontWeight.w700, fontSize: 16),
                              ),
                            );
                          } else if (snapshot.hasError) {
                            return _logout();
                          } else {
                            if (plannerItem.isEmpty) {
                              return ListView(
                                shrinkWrap: true,
                                children: [
                                  Center(
                                    child: Container(
                                      child: RaisedButton(
                                        onPressed: () {
                                          showCupertinoModalBottomSheet(context: this.context, builder: (context) => WritePlannerWidget());

                                          setState(() {
                                            fPlannerItem = _getPlanner();
                                          });
                                        },
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        child: Text(
                                          '오늘 할 일이 없습니다!\n 지금 할일을 추가하세요!',
                                          style: TextStyle(fontFamily: 'NotoSansKR', fontWeight: FontWeight.w500, fontSize: 16, color: Color(0xff9B9B9B)),
                                        ),
                                        color: Color(0xffF4F4F4),
                                        elevation: 0,
                                      ),
                                      width: _width * 0.87,
                                      height: 85,
                                    ),
                                  )
                                ],
                              );
                            } else {
                              return Container(
                                height: _height * 0.75,
                                child: ListView.builder(
                                  controller: _scrollController,
                                  shrinkWrap: true,
                                  itemCount: plannerItem.length == 0 ? 1 : plannerItem.length,
                                  itemBuilder: (context, index) {
                                    Color itemColor;
                                    Color itemTextColor;

                                    String content = "";

                                    String want = plannerItem[index].want;
                                    if (!plannerItem[index].isSucceed && !plannerItem[index].isFailed) {
                                      if (want == "ONE")
                                        itemColor = Color(0xffFF4631);
                                      else if (want == "TWO")
                                        itemColor = Color(0xffFF974B);
                                      else if (want == "THREE")
                                        itemColor = Color(0xffFEBA2B);
                                      else if (want == "FOUR")
                                        itemColor = Color(0xff1BB778);
                                      else
                                        itemColor = Color(0xff2F5DFB);

                                      content = '중요도 : ' + plannerItem[index].priority + ' | ' + plannerItem[index].startTime.substring(0, 5) + ' ~ ' + plannerItem[index].endTime.substring(0, 5);
                                      itemTextColor = Color(0xffFFFFFF);
                                    } else {
                                      itemColor = Color(0xffF4F4F4);
                                      itemTextColor = Color(0xff9B9B9B);

                                      content = '중요도 : ' + plannerItem[index].priority + ' | ' + plannerItem[index].startTime.substring(0, 5) + ' ~ ' + plannerItem[index].endTime.substring(0, 5);
                                    }
                                    return Center(
                                      child: Container(
                                        height: 85,
                                        width: _width * 0.87,
                                        margin: EdgeInsets.only(top: 10),
                                        child: SwipeActionCell(
                                          key: ObjectKey(plannerItem[index]),
                                          performsFirstActionWithFullSwipe: true,
                                          trailingActions: [
                                            SwipeAction(
                                              title: '성공',
                                              style: TextStyle(fontFamily: 'NotoSansKR', fontWeight: FontWeight.normal, fontSize: 18, color: Colors.blue),
                                              onTap: (handler) async {
                                                await handler(false);
                                                showAnimatedDialog(
                                                    context: context,
                                                    barrierDismissible: false,
                                                    builder: (context) {
                                                      return ClassicGeneralDialogWidget(
                                                        titleText: '할일 성공',
                                                        contentText: '성공하셨습니까?',
                                                        onPositiveClick: () {
                                                          _succeedPlanner(plannerItem[index].plannerId);
                                                          setState(() {
                                                            plannerItem[index].isSucceed = true;
                                                          });
                                                          Navigator.of(context).pop();
                                                        },
                                                        onNegativeClick: () {
                                                          _showTaost('취소');
                                                          Navigator.of(context).pop();
                                                        },
                                                        positiveText: '네..',
                                                        negativeText: '아니요!',
                                                        negativeTextStyle: TextStyle(color: Colors.red, fontFamily: 'NotoSansKR', fontWeight: FontWeight.w500, fontSize: 16),
                                                        positiveTextStyle: TextStyle(color: Color(0xff2F5DFB), fontFamily: 'NotoSansKR', fontWeight: FontWeight.w500, fontSize: 16),
                                                      );
                                                    });
                                              },
                                              color: Color(0xffF4F4F4),
                                              backgroundRadius: 10,
                                            ),
                                            SwipeAction(
                                              title: '실패',
                                              style: TextStyle(fontFamily: 'NotoSansKR', fontWeight: FontWeight.normal, fontSize: 18, color: Colors.red),
                                              onTap: (handler) async {
                                                await handler(false);
                                                showAnimatedDialog(
                                                    context: context,
                                                    barrierDismissible: false,
                                                    builder: (context) {
                                                      return ClassicGeneralDialogWidget(
                                                        titleText: '할일 성공',
                                                        contentText: '성공하셨습니까?',
                                                        onPositiveClick: () {
                                                          failedPlanner(plannerItem[index].plannerId);
                                                          setState(() {
                                                            plannerItem[index].isFailed = true;
                                                          });
                                                          Navigator.of(context).pop();
                                                        },
                                                        onNegativeClick: () {
                                                          _showTaost('취소');
                                                          Navigator.of(context).pop();
                                                        },
                                                        positiveText: '네..',
                                                        negativeText: '아니요!',
                                                        negativeTextStyle: TextStyle(color: Colors.red, fontFamily: 'NotoSansKR', fontWeight: FontWeight.w500, fontSize: 16),
                                                        positiveTextStyle: TextStyle(color: Color(0xff2F5DFB), fontFamily: 'NotoSansKR', fontWeight: FontWeight.w500, fontSize: 16),
                                                      );
                                                    });
                                              },
                                              color: Color(0xffF4F4F4),
                                              backgroundRadius: 10,
                                            ),
                                            SwipeAction(
                                              title: '미루기',
                                              style: TextStyle(fontFamily: 'NotoSansKR', fontWeight: FontWeight.normal, fontSize: 18, color: Color(0xff9B9B9B)),
                                              onTap: (handler) async {
                                                await handler(false);
                                                if (plannerItem[index].isSucceed || plannerItem[index].isFailed) {
                                                  _showTaost('미룰 수 없습니다');
                                                  return;
                                                }
                                                DateTimeRangePicker(
                                                  startText: "시작시간",
                                                  endText: "끝낼시간",
                                                  doneText: "확인",
                                                  cancelText: "취소",
                                                  interval: 5,
                                                  initialStartTime: DateTime.now(),
                                                  initialEndTime: DateTime.now(),
                                                  mode: DateTimeRangePickerMode.dateAndTime,
                                                  minimumTime: DateTime(2000),
                                                  maximumTime: DateTime(2100),
                                                  use24hFormat: true,
                                                  onConfirm: (start, end) {
                                                    print('$start ~ $end');

                                                    _latePlanner(plannerItem[index].plannerId, start, end);
                                                  },
                                                ).showPicker(context);
                                              },
                                              color: Color(0xffF4F4F4),
                                              backgroundRadius: 10,
                                            ),
                                          ],
                                          child: RaisedButton(
                                            elevation: 0,
                                            onPressed: () {
                                              print(plannerItem[index].content);
                                              Navigator.push(
                                                  context,
                                                  PageTransition(
                                                      child: ReadPlannerWidget(
                                                          plannerItem[index].title,
                                                          plannerItem[index].content,
                                                          plannerItem[index].plannerId,
                                                          plannerItem[index].startDate,
                                                          plannerItem[index].endTime,
                                                          plannerItem[index].endDate,
                                                          plannerItem[index].isFailed,
                                                          plannerItem[index].priority,
                                                          plannerItem[index].isSucceed,
                                                          plannerItem[index].startTime,
                                                          plannerItem[index].isPushed,
                                                          plannerItem[index].want),
                                                      type: PageTransitionType.rightToLeft));
                                            },
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      margin: EdgeInsets.only(left: 20),
                                                      child: Text(
                                                        plannerItem[index].title,
                                                        style: TextStyle(fontFamily: 'NotoSansKR', fontWeight: FontWeight.w700, fontSize: 18, color: itemTextColor),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      margin: EdgeInsets.only(top: 10, left: 20),
                                                      child: Text(
                                                        content,
                                                        style: TextStyle(fontFamily: 'NotoSansKR', fontWeight: FontWeight.w700, fontSize: 12, color: itemTextColor),
                                                      ),
                                                    )
                                                  ],
                                                )
                                              ],
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            color: itemColor,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          NoticePage(),
          Container(
              child: ListView(
            children: [
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        margin: EdgeInsets.only(top: 20),
                        child: OutlineSearchBar(
                          keyboardType: TextInputType.text,
                          borderRadius: BorderRadius.all(Radius.circular(30)),
                          backgroundColor: Color(0xffF3F3F3),
                          textInputAction: TextInputAction.search,
                          hintText: '검색어를 입력하세요.',
                          hintStyle: TextStyle(fontFamily: 'NotoSansKR', fontWeight: FontWeight.normal, fontSize: 16, color: Color(0xffD1D1D1)),
                          textStyle: TextStyle(fontFamily: 'NotoSansKR', fontWeight: FontWeight.normal, fontSize: 16, color: Color(0xff9B9B9B)),
                          textPadding: EdgeInsets.only(left: 30),
                          borderWidth: 0,
                          borderColor: Color(0xffF3F3F3),
                          searchButtonIconColor: Color(0xffD1D1D1),
                          onSearchButtonPressed: (value) {
                            setState(() {
                              title = value;
                              _notSearch = false;
                            });
                          },
                        ),
                        width: _width * 0.87,
                        height: 50,
                      ),
                    ],
                  ),
                  ListView(
                    shrinkWrap: true,
                    children: [
                      Container(
                        margin: EdgeInsets.only(bottom: 100),
                        child: Column(
                          children: [
                            Visibility(
                                visible: _notSearch,
                                child: Container(
                                  margin: EdgeInsets.only(top: 80),
                                  child: Text(
                                    '검색 결과가 여기에 표시됩니다.',
                                    style: TextStyle(fontFamily: 'NotoSansKR', fontWeight: FontWeight.w500, fontSize: 20, color: Color(0xffD1D1D1)),
                                  ),
                                )),
                            Visibility(
                                visible: !_notSearch,
                                child: FutureBuilder<SearchPlanner>(
                                  future: _searchPlanner(title),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData == false) {
                                      return FadingText(
                                        'Loading..',
                                        style: TextStyle(fontFamily: 'NotoSansKR', fontWeight: FontWeight.w700, fontSize: 16),
                                      );
                                    } else if (snapshot.hasError) {
                                      return _logout();
                                    } else {
                                      if (searchPlanner.planners.isEmpty || title.length == 0) {
                                        return Column(
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.start,
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                Container(
                                                  margin: EdgeInsets.only(top: 20, left: _width * 0.061, bottom: 10),
                                                  child: Text(
                                                    '검색된 할 일 목록',
                                                    style: TextStyle(fontFamily: 'NotoSansKR', fontWeight: FontWeight.w700, fontSize: 25),
                                                  ),
                                                ),
                                                Container(
                                                  margin: EdgeInsets.only(left: 10),
                                                  child: Text(
                                                    title.length == 0 ? '0' : searchPlanner.searchNum.toString(),
                                                    style: TextStyle(fontFamily: 'NotoSansKR', fontWeight: FontWeight.w700, fontSize: 27, color: Color(0xff2F5DFB)),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            ListView(
                                              shrinkWrap: true,
                                              children: [
                                                Center(
                                                  child: Container(
                                                    margin: EdgeInsets.only(top: 20),
                                                    child: RaisedButton(
                                                      onPressed: () {
                                                        showCupertinoModalBottomSheet(context: context, builder: (context) => WritePlannerWidget());
                                                      },
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                      child: Text(
                                                        '검색된 할 일이 없습니다!\n 지금 할일을 추가하세요!',
                                                        style: TextStyle(fontFamily: 'NotoSansKR', fontWeight: FontWeight.w500, fontSize: 16, color: Color(0xff9B9B9B)),
                                                      ),
                                                      color: Color(0xffF4F4F4),
                                                      elevation: 0,
                                                    ),
                                                    width: _width * 0.87,
                                                    height: 85,
                                                  ),
                                                )
                                              ],
                                            )
                                          ],
                                        );
                                      } else {
                                        return Column(
                                          children: [
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              mainAxisAlignment: MainAxisAlignment.start,
                                              children: [
                                                Container(
                                                  margin: EdgeInsets.only(top: 20, left: _width * 0.061, bottom: 10),
                                                  child: Text(
                                                    '검색된 할 일 목록',
                                                    style: TextStyle(fontFamily: 'NotoSansKR', fontWeight: FontWeight.w700, fontSize: 25),
                                                  ),
                                                ),
                                                Container(
                                                  margin: EdgeInsets.only(left: 10),
                                                  child: Text(
                                                    searchPlanner.searchNum.toString(),
                                                    style: TextStyle(fontFamily: 'NotoSansKR', fontWeight: FontWeight.w700, fontSize: 27, color: Color(0xff2F5DFB)),
                                                  ),
                                                ),
                                                Container(
                                                  margin: EdgeInsets.only(top: 6),
                                                  child: IconButton(
                                                    onPressed: () {
                                                      Navigator.pushAndRemoveUntil(
                                                          context,
                                                          PageTransition(child: PlannerPage(tier, DateFormat("yyyy-MM-dd").format(DateTime.now())), type: PageTransitionType.bottomToTop),
                                                          (route) => false);
                                                    },
                                                    icon: Icon(Icons.add),
                                                    iconSize: 35,
                                                  ),
                                                )
                                              ],
                                            ),
                                            ListView.builder(
                                                physics: NeverScrollableScrollPhysics(),
                                                shrinkWrap: true,
                                                itemCount: searchPlanner.planners.length == 0 ? 1 : searchPlanner.planners.length,
                                                itemBuilder: (context, index) {
                                                  Color itemColor;
                                                  Color itemTextColor;

                                                  String content = "";

                                                  String want = searchPlanner.planners[index].want;

                                                  if (!searchPlanner.planners[index].isSucceed && !searchPlanner.planners[index].isFailed) {
                                                    if (want == "ONE")
                                                      itemColor = Color(0xffFF4631);
                                                    else if (want == "TWO")
                                                      itemColor = Color(0xffFF974B);
                                                    else if (want == "THREE")
                                                      itemColor = Color(0xffFEBA2B);
                                                    else if (want == "FOUR")
                                                      itemColor = Color(0xff1BB778);
                                                    else
                                                      itemColor = Color(0xff2F5DFB);

                                                    content = '중요도 : ' +
                                                        searchPlanner.planners[index].priority +
                                                        ' | ' +
                                                        searchPlanner.planners[index].startTime.substring(0, 5) +
                                                        ' ~ ' +
                                                        searchPlanner.planners[index].endTime.substring(0, 5);
                                                    itemTextColor = Color(0xffFFFFFF);
                                                  } else {
                                                    itemColor = Color(0xffF4F4F4);
                                                    itemTextColor = Color(0xff9B9B9B);

                                                    content = '중요도 : ' +
                                                        searchPlanner.planners[index].priority +
                                                        ' | ' +
                                                        searchPlanner.planners[index].startTime.substring(0, 5) +
                                                        ' ~ ' +
                                                        searchPlanner.planners[index].endTime.substring(0, 5);
                                                  }
                                                  return Center(
                                                    child: Container(
                                                      height: 85,
                                                      width: _width * 0.87,
                                                      margin: EdgeInsets.only(top: 10),
                                                      child: SwipeActionCell(
                                                        key: ObjectKey(searchPlanner.planners[index]),
                                                        performsFirstActionWithFullSwipe: true,
                                                        trailingActions: [
                                                          SwipeAction(
                                                            title: '자세히',
                                                            style: TextStyle(fontFamily: 'NotoSansKR', fontWeight: FontWeight.normal, fontSize: 18, color: Colors.blue),
                                                            widthSpace: 90,
                                                            onTap: (handler) async {
                                                              await handler(false);
                                                              Navigator.push(
                                                                  context,
                                                                  PageTransition(
                                                                      child: ReadPlannerWidget(
                                                                          searchPlanner.planners[index].title,
                                                                          searchPlanner.planners[index].content,
                                                                          searchPlanner.planners[index].plannerId,
                                                                          searchPlanner.planners[index].startDate,
                                                                          searchPlanner.planners[index].endTime,
                                                                          searchPlanner.planners[index].endDate,
                                                                          searchPlanner.planners[index].isFailed,
                                                                          searchPlanner.planners[index].priority,
                                                                          searchPlanner.planners[index].isSucceed,
                                                                          searchPlanner.planners[index].startTime,
                                                                          searchPlanner.planners[index].isPushed,
                                                                          searchPlanner.planners[index].want),
                                                                      type: PageTransitionType.rightToLeft));
                                                            },
                                                            color: Color(0xffF4F4F4),
                                                            backgroundRadius: 10,
                                                          ),
                                                        ],
                                                        child: RaisedButton(
                                                          elevation: 0,
                                                          onPressed: () {
                                                            Navigator.push(
                                                                context,
                                                                PageTransition(
                                                                    child: ReadPlannerWidget(
                                                                        searchPlanner.planners[index].title,
                                                                        searchPlanner.planners[index].content,
                                                                        searchPlanner.planners[index].plannerId,
                                                                        searchPlanner.planners[index].startDate,
                                                                        searchPlanner.planners[index].endTime,
                                                                        searchPlanner.planners[index].endDate,
                                                                        searchPlanner.planners[index].isFailed,
                                                                        searchPlanner.planners[index].priority,
                                                                        searchPlanner.planners[index].isSucceed,
                                                                        searchPlanner.planners[index].startTime,
                                                                        searchPlanner.planners[index].isPushed,
                                                                        searchPlanner.planners[index].want),
                                                                    type: PageTransitionType.rightToLeft));
                                                          },
                                                          child: Column(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              Row(
                                                                mainAxisAlignment: MainAxisAlignment.start,
                                                                children: [
                                                                  Container(
                                                                    margin: EdgeInsets.only(left: 20),
                                                                    child: Text(
                                                                      searchPlanner.planners[index].title,
                                                                      style: TextStyle(fontFamily: 'NotoSansKR', fontWeight: FontWeight.w700, fontSize: 18, color: itemTextColor),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              Row(
                                                                mainAxisAlignment: MainAxisAlignment.start,
                                                                children: [
                                                                  Container(
                                                                    margin: EdgeInsets.only(top: 10, left: 20),
                                                                    child: Text(
                                                                      content,
                                                                      style: TextStyle(fontFamily: 'NotoSansKR', fontWeight: FontWeight.w700, fontSize: 12, color: itemTextColor),
                                                                    ),
                                                                  )
                                                                ],
                                                              )
                                                            ],
                                                          ),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(10),
                                                          ),
                                                          color: itemColor,
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                }),
                                          ],
                                        );
                                      }
                                    }
                                  },
                                )),
                            Container(
                              margin: EdgeInsets.only(bottom: 200),
                              child: Visibility(
                                  visible: !_notSearch,
                                  child: FutureBuilder<SearchRoutine>(
                                    future: _searchRoutine(title),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData == false) {
                                        return FadingText(
                                          'Loading..',
                                          style: TextStyle(fontFamily: 'NotoSansKR', fontWeight: FontWeight.w700, fontSize: 16),
                                        );
                                      } else if (snapshot.hasError) {
                                        return _logout();
                                      } else {
                                        if (searchRoutine.routines.isEmpty || title.length == 0) {
                                          return Column(
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    margin: EdgeInsets.only(top: 20, left: _width * 0.061, bottom: 10),
                                                    child: Text(
                                                      '검색된 루틴 목록',
                                                      style: TextStyle(fontFamily: 'NotoSansKR', fontWeight: FontWeight.w700, fontSize: 25),
                                                    ),
                                                  ),
                                                  Container(
                                                    margin: EdgeInsets.only(top: 26, left: 10),
                                                    child: Text(
                                                      title.length == 0 ? '0' : searchPlanner.searchNum.toString(),
                                                      style: TextStyle(fontFamily: 'NotoSansKR', fontWeight: FontWeight.w700, fontSize: 27, color: Color(0xff2F5DFB)),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              ListView(
                                                physics: NeverScrollableScrollPhysics(),
                                                shrinkWrap: true,
                                                children: [
                                                  Center(
                                                    child: Container(
                                                      margin: EdgeInsets.only(bottom: 20),
                                                      child: RaisedButton(
                                                        onPressed: () {},
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                        child: Text(
                                                          '검색된 루틴이 없습니다!\n 지금 루틴을 추가하세요!',
                                                          style: TextStyle(fontFamily: 'NotoSansKR', fontWeight: FontWeight.w500, fontSize: 16, color: Color(0xff9B9B9B)),
                                                        ),
                                                        color: Color(0xffF4F4F4),
                                                        elevation: 0,
                                                      ),
                                                      width: _width * 0.87,
                                                      height: 85,
                                                    ),
                                                  )
                                                ],
                                              )
                                            ],
                                          );
                                        } else {
                                          return Column(
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    margin: EdgeInsets.only(top: 20, left: _width * 0.061, bottom: 10),
                                                    child: Text(
                                                      '검색된 루틴 목록',
                                                      style: TextStyle(fontFamily: 'NotoSansKR', fontWeight: FontWeight.w700, fontSize: 25),
                                                    ),
                                                  ),
                                                  Container(
                                                    margin: EdgeInsets.only(top: 6, left: 10),
                                                    child: Text(
                                                      searchRoutine.searchNum.toString(),
                                                      style: TextStyle(fontFamily: 'NotoSansKR', fontWeight: FontWeight.w700, fontSize: 27, color: Color(0xff2F5DFB)),
                                                    ),
                                                  ),
                                                  Container(
                                                    margin: EdgeInsets.only(top: 6),
                                                    child: IconButton(
                                                      onPressed: () {},
                                                      icon: Icon(Icons.add),
                                                      iconSize: 35,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              ListView.builder(
                                                physics: const NeverScrollableScrollPhysics(),
                                                shrinkWrap: true,
                                                itemCount: searchRoutine.routines.length,
                                                itemBuilder: (context, index) {
                                                  String content = '';
                                                  for (String week in searchRoutine.routines[index].dayOfWeeks) content += week + ' ';

                                                  content += '| ' + searchRoutine.routines[index].startTime.substring(0, 5) + ' ~ ' + searchRoutine.routines[index].endTime.substring(0, 5);

                                                  return Center(
                                                    child: Container(
                                                      height: 85,
                                                      width: _width * 0.87,
                                                      margin: EdgeInsets.only(top: 10),
                                                      child: SwipeActionCell(
                                                        key: ObjectKey(searchRoutine.routines[index]),
                                                        trailingActions: [SwipeAction(
                                                          title: '자세히',
                                                          style: TextStyle(fontFamily: 'NotoSansKR', fontWeight: FontWeight.normal, fontSize: 18, color: Colors.blue),
                                                          widthSpace: 90,
                                                          onTap: (handler) async {
                                                            await handler(false);
                                                          },
                                                          color: Color(0xffF4F4F4),
                                                          backgroundRadius: 10,
                                                        ),
                                                        ],
                                                        child: RaisedButton(
                                                          elevation: 0,
                                                          onPressed: () {},
                                                          child: Column(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              Row(
                                                                mainAxisAlignment: MainAxisAlignment.start,
                                                                children: [
                                                                  Container(
                                                                    margin: EdgeInsets.only(left: 20),
                                                                    child: Text(
                                                                      searchRoutine.routines[index].title,
                                                                      style: TextStyle(fontFamily: 'NotoSansKR', fontWeight: FontWeight.w700, fontSize: 18, color: Color(0xff9B9B9B)),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              Row(
                                                                mainAxisAlignment: MainAxisAlignment.start,
                                                                children: [
                                                                  Container(
                                                                    margin: EdgeInsets.only(top: 10, left: 20),
                                                                    child: Text(
                                                                      content,
                                                                      style: TextStyle(fontFamily: 'NotoSansKR', fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xff9B9B9B)),
                                                                    ),
                                                                  )
                                                                ],
                                                              )
                                                            ],
                                                          ),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(10),
                                                          ),
                                                          color: Color(0xffEAEAEA),
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              )
                                            ],
                                          );
                                        }
                                      }
                                    },
                                  )),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ))
        ],
      ),
    );
  }
}

class Token {
  final String accessToken;
  final String refreshToken;

  Token({required this.accessToken, required this.refreshToken});

  factory Token.fromJson(Map<String, dynamic> tokenMap) {
    return Token(accessToken: tokenMap['accessToken'], refreshToken: tokenMap['refreshToken']);
  }
}
