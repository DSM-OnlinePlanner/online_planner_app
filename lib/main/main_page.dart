
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:draw_graph/draw_graph.dart';
import 'package:draw_graph/models/feature.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animated_dialog/flutter_animated_dialog.dart';
import 'package:flutter_circular_chart_two/flutter_circular_chart_two.dart';
import 'package:flutter_swipe_action_cell/core/cell.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:imagebutton/imagebutton.dart';
import 'package:intl/intl.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:online_planner_app/SideMenuWidget.dart';
import 'package:online_planner_app/detail/planner/WritePlanner.dart';
import 'package:online_planner_app/detail/login/login_detail.dart';
import 'package:online_planner_app/detail/planner/ReadPlanner.dart';
import 'package:online_planner_app/detail/routine/ReadRoutine.dart';
import 'package:online_planner_app/detail/user_info/user_info_detail.dart';
import 'package:online_planner_app/login/login_page.dart';
import 'package:online_planner_app/main/notice_page.dart';
import 'package:outline_search_bar/outline_search_bar.dart';
import 'package:page_transition/page_transition.dart';
import 'package:progress_indicators/progress_indicators.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../detail/routine/WriteRoutine.dart';

class MainPage extends StatefulWidget {
  String tier = "";

  MainPage();
  MainPage.init(this.tier);

  _MainWidget createState() {
    if(tier.isEmpty)
      return _MainWidget();
    else
      return _MainWidget.init(tier);
  }
}

class _MainWidget extends State<MainPage> {
  String initTier = "";
  String nickName = "",
      tier = "";
  int exp = -1,
      maxExp = -1,
      userLevel = -1;

  String imageName = "";

  late UserInfo userInfo;

  _MainWidget();
  _MainWidget.init(this.initTier);

  late SearchPlanner searchPlanner;
  late SearchRoutine searchRoutine;

  PageController _mainPageController = PageController(
    initialPage: 0,
  );

  String pageName = "",
      title = "";

  bool successFailed = false, isSetImage = false;

  List<Planner> plannerItem = [];
  List<Routine> routineItem = [];
  late Statistics statiistics;
  late Future<Statistics> fStatistics;
  late Future<double> fPlannerStatistics;
  late Future<List<Planner>> fPlannerItem;
  late Future<List<Routine>> fRoutineItem;

  double plannerNum = 0;

  int _fragType = 0;

  Color bellColor = Color(0xff585858);
  Color searchColor = Color(0xff585858);

  late SharedPreferences _preferences;

  late Token token;

  bool _isBell = false;
  bool _isSearch = false;

  Image userImage = Image.asset('assets/images/splash.png');

  String accessToken = "",
      refreshToken = "",
      deviceToken = "";

  final String url = 'http://220.90.237.33:7070';

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  bool _notSearch = true;

  _setUserImage() {
    print("set" + initTier);

    if (initTier == "A4 용지") {
      setState(() {
        userImage = Image.asset('assets/images/just_paper.png');
        imageName = 'assets/images/just_paper.png';
      });
    } else if (initTier == "무료 플래너") {
      setState(() {
        userImage = Image.asset('assets/images/free_paper.png');
        imageName = 'assets/images/free_paper.png';
      });
    } else if (initTier == "스프링 노트 플래너") {
      setState(() {
        userImage = Image.asset('assets/images/spring_planner.png');
        imageName = 'assets/images/spring_planner.png';
      });
    } else if (initTier == "플라스틱 커버 플래너") {
      setState(() {
        userImage = Image.asset('assets/images/plastic_planner.png');
        imageName = 'assets/images/plastic_planner.png';
      });
    } else if (initTier == "가죽 슬러브 플래너") {
      setState(() {
        userImage = Image.asset('assets/images/gaguck_planner.png');
        imageName = 'assets/images/gaguck_planner.png';
      });
    } else if (initTier == "고급 가죽 슬러브 플래너") {
      setState(() {
        userImage = Image.asset('assets/images/good_gaguck_planner.png');
        imageName = 'assets/images/good_gaguck_planner.png';
      });
    } else if (initTier == "맞춤 재작 플래너") {
      setState(() {
        userImage = Image.asset('assets/images/best_planner.png');
        imageName = 'assets/images/best_planner.png';
      });
    } else if (initTier == "최고의 플래너") {
      setState(() {
        userImage = Image.asset('assets/images/end_tier.png');
        imageName = 'assets/images/end_tier.png';
      });
    } else if (initTier.isEmpty) {
      _logout();
    }
  }

  Future<SearchRoutine> _searchRoutine(String title) async {
    _preferences = await SharedPreferences.getInstance();
    
    try {
      Dio dio = Dio();
      final response = await dio.get(
        url + '/routine/search',
        options: Options(
          headers: {
            HttpHeaders.authorizationHeader: _preferences.getString('accessToken') ?? ""
          }
        ),
        queryParameters: {
          'title' : title
        }
      );

      if(response.statusCode == 200) {
        searchRoutine = SearchRoutine.fromJson(response.data);

        return searchRoutine;
      }else {
        await _refreshToken();
        return _searchRoutine(title);
      }
    }catch(e) {
      await _retrySearchRoutine(title);

      return searchRoutine;
    }
  }

  _retrySearchRoutine(String title) async {
    _preferences = await SharedPreferences.getInstance();
    await _refreshToken();
    try {
      Dio dio = Dio();
      final response = await dio.get(
          url + '/routine/search',
          options: Options(
              headers: {
                HttpHeaders.authorizationHeader: _preferences.getString('accessToken') ?? ""
              }
          ),
          queryParameters: {
            'title' : title
          }
      );

      if(response.statusCode == 200) {
        searchRoutine = SearchRoutine.fromJson(response.data);
      }
    }catch(e) {
      await _logout();
    }
  }

  Future<SearchPlanner> _searchPlanner(String title) async {
    _preferences = await SharedPreferences.getInstance();
    try {
      Dio dio = Dio();
      final response = await dio.get(
          url + '/planner/search',
          options: Options(
              headers: {
                HttpHeaders.authorizationHeader: _preferences.getString('accessToken') ?? ""
              }
          ),
          queryParameters: {
            'title': title
          }
      );

      if (response.statusCode == 200) {
        searchPlanner = SearchPlanner.fromJson(response.data);

        return searchPlanner;
      } else {
        await _refreshToken();
        return _searchPlanner(title);
      }
    } catch (e) {
      await _retrySearchPlanner(title);

      return searchPlanner;
    }
  }

  _retrySearchPlanner(String title) async {
    await _refreshToken();
    _preferences = await SharedPreferences.getInstance();
    try {
      Dio dio = Dio();
      final response = await dio.get(
          url + '/planner/search',
          options: Options(
              headers: {
                HttpHeaders.authorizationHeader: _preferences.getString('accessToken') ?? ""
              }
          ),
          queryParameters: {
            'title': title
          }
      );

      if (response.statusCode == 200) {
        searchPlanner = SearchPlanner.fromJson(response.data);

        return searchPlanner;
      } else {
        await _refreshToken();
        return _searchPlanner(title);
      }
    } catch (e) {
      await _logout();
    }
  }

  _logout() async {
    FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
    try {
      Dio dio = Dio();
      final response = await dio.delete(
          url + '/user/logout',
          options: Options(
              headers: {
                HttpHeaders.contentTypeHeader: "application/json",
                "deviceToken": await firebaseMessaging.getToken() ?? ""
              }
          )
      );

      if (response.statusCode == 200) {
        _preferences.remove("isAuth");
        _preferences.remove("accessToken");
        _preferences.remove("refreshToken");
        _preferences.remove("userImage");

        Navigator.of(context).pushAndRemoveUntil(
            PageTransition(
                child: StartPage(),
                type: PageTransitionType.bottomToTop
            ),
            (route) => false
        );
      }
    }catch(e) {
      print(e);
    }
  }

  Future<Statistics> _getStatistics() async {
    _preferences = await SharedPreferences.getInstance();
    try {
      var dio = Dio();
      final response = await dio.get(
          url + '/statistics',
          options: Options(
              headers: {
                HttpHeaders.authorizationHeader: _preferences.getString('accessToken') ?? ""
              }
          )
      );

      print(response.statusCode);

      print(response.data.toString());

      if (response.statusCode == 200) {
        statiistics = Statistics.fromJson(response.data);

        print(statiistics.pointResponses);

        return statiistics;
      }

      return statiistics;
    } catch (e) {
      print("main page state : " + e.toString());
      bool isSucceed = await _refreshToken();
      if (isSucceed)
        return _getStatistics();
    }

    return statiistics;
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
          pageName = '';
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
          pageName = '';
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

  _showTaost(String message) {
    return Fluttertoast.showToast(
        msg: message,
        textColor: Colors.black,
        backgroundColor: Colors.grey,
        gravity: ToastGravity.BOTTOM,
        fontSize: 15
    );
  }

  _succeedPlanner(int plannerId) async {
    try {
      Dio dio = Dio();
      final response = await dio.put(
          url + '/planner/check/' + plannerId.toString(),
          options: Options(
              headers: {
                HttpHeaders.authorizationHeader: _preferences.getString('accessToken') ?? ""
              }
          )
      );

      if(response.statusCode == 200) {
        _showTaost('할 일을 성공하셨습니다');

        successFailed = true;
      }
    }catch(e) {
      print(e.toString());

      if(e.toString().contains('409')) {
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
      final response = await dio.put(
          url + '/planner/check/' + plannerId.toString(),
          options: Options(
              headers: {
                HttpHeaders.authorizationHeader: _preferences.getString('accessToken') ?? ""
              }
          )
      );

      if(response.statusCode == 200) {
        _showTaost('할 일을 성공하셨습니다');

        successFailed = true;
      }
    }catch(e) {
      print(e.toString());


    }
  }

  Future<void> failedPlanner(int plannerId) async {
    try {
      Dio dio = Dio();
      final response = await dio.put(
        url + '/planner/failed/' + plannerId.toString(),
        options: Options(
          headers: {
            HttpHeaders.authorizationHeader: _preferences.getString('accessToken') ?? ""
          }
        )
      );

      if(response.statusCode == 200) {
        _showTaost('할 일을 실패하셨습니다');

        successFailed = true;
      }
    }catch(e) {
      print(e.toString());
      
      if(e.toString().contains('409')) {
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
      final response = await dio.put(
          url + '/planner/failed/' + plannerId.toString(),
          options: Options(
              headers: {
                HttpHeaders.authorizationHeader: _preferences.getString('accessToken') ?? ""
              }
          )
      );

      if(response.statusCode == 200) {
        _showTaost('할 일을 실패하셨습니다');

        successFailed = true;
      }
    }catch(e) {
      print(e.toString());

      if(e.toString().contains('409')) {
        _showTaost('할 일이 이미 성공했습니다!');
        return;
      }
      _preferences.remove("isAuth");
      _preferences.remove("accessToken");
      _preferences.remove("refreshToken");
      _preferences.remove("userImage");

      Navigator.of(context).pushAndRemoveUntil(
          PageTransition(
              child: StartPage(),
              type: PageTransitionType.bottomToTop
          ),
              (route) => false
      );
    }
  }

  retryFailedPlanner(int plannerId) async {
    await _refreshToken();
    _preferences = await SharedPreferences.getInstance();
    try {
      Dio dio = Dio();
      final response = await dio.put(
          url + '/planner/failed/' + plannerId.toString(),
          options: Options(
              headers: {
                HttpHeaders.authorizationHeader: _preferences.getString('accessToken') ?? ""
              }
          )
      );

      if(response.statusCode == 200) {
        _showTaost('할 일을 실패하셨습니다');

        successFailed = true;
      }
    }catch(e) {
      print(e.toString());

      if(e.toString().contains('409')) {
        _showTaost('할 일이 이미 성공했습니다!');
        return;
      }

      _preferences.remove("isAuth");
      _preferences.remove("accessToken");
      _preferences.remove("refreshToken");
      _preferences.remove("userImage");

      Navigator.of(context).pushAndRemoveUntil(
          PageTransition(
              child: StartPage(),
              type: PageTransitionType.bottomToTop
          ),
              (route) => false
      );
    }
  }

  Future<List<Planner>> _getPlannerMain() async {
    _preferences = await SharedPreferences.getInstance();
    try {
      var date = DateTime.now();
      var format = 'yyyy-MM-dd';

      print(DateFormat(format).format(date).toString());

      Dio dio = Dio();
      final response = await dio.get(
          url + '/planner/main',
          options: Options(
              headers: {
                HttpHeaders.contentTypeHeader: 'application/json',
                HttpHeaders.authorizationHeader: _preferences.getString('accessToken') ?? ""
              }
          ),
          queryParameters: {
            'date': DateFormat(format).format(date).toString()
          }
      );

      print(response.statusCode);

      print(response.data.toString());

      if (response.statusCode == 200) {
        plannerItem =
            (response.data as List).map((e) => Planner.fromJson(e)).toList();

        if (plannerItem.isNotEmpty)
          print(plannerItem[0].title);
        else
          print('empty');
        return plannerItem;
      } else {
        _refreshToken();
        _getPlannerMain();
      }

      return plannerItem;
    } catch (e) {
      await _retryPlannerMain();

      return plannerItem;
    }
  }

  _retryPlannerMain() async {
    await _refreshToken();
    _preferences = await SharedPreferences.getInstance();
    
    try {
      var date = DateTime.now();
      var format = 'yyyy-MM-dd';

      print(DateFormat(format).format(date).toString());

      Dio dio = Dio();
      final response = await dio.get(
          url + '/planner/main',
          options: Options(
              headers: {
                HttpHeaders.contentTypeHeader: 'application/json',
                HttpHeaders.authorizationHeader: _preferences.getString('accessToken') ?? ""
              }
          ),
          queryParameters: {
            'date': DateFormat(format).format(date).toString()
          }
      );

      print(response.statusCode);

      print(response.data.toString());

      if (response.statusCode == 200) {
        plannerItem =
            (response.data as List).map((e) => Planner.fromJson(e)).toList();

        if (plannerItem.isNotEmpty)
          print(plannerItem[0].title);
        else
          print('empty');
        return plannerItem;
      }
    } catch (e) {
      _preferences.remove("isAuth");
      _preferences.remove("accessToken");
      _preferences.remove("refreshToken");
      _preferences.remove("userImage");

      Navigator.of(context).pushAndRemoveUntil(
          PageTransition(
              child: StartPage(),
              type: PageTransitionType.bottomToTop
          ),
              (route) => false
      );
    }
  }

  Future<double> _getPlannerState() async {
    _preferences = await SharedPreferences.getInstance();
    try {
      Dio dio = Dio();
      final response = await dio.get(
          url + '/statistics/planner',
          options: Options(
              headers: {
                HttpHeaders.authorizationHeader: _preferences.getString('accessToken') ?? ""
              }
          )
      );

      if (response.statusCode == 200) {
        PlannerState plannerState = PlannerState.fromJson(response.data);
        print("planner num" + plannerState.maxPlannerToday.toString());
        print('success num' + plannerState.successPlannerToday.toString());
        plannerNum = plannerState.maxPlannerToday == 0 || plannerState.successPlannerToday == 0 ? 0.0 : double.parse(((plannerState.successPlannerToday / plannerState.maxPlannerToday) * 100).toDouble().toStringAsFixed(1));

        return plannerNum;
      } else {
        await _retryPlannerState();
        return plannerNum;
      }
    } catch (e) {
      print('planner percent : ' + e.toString());

      await _retryPlannerState();
      return plannerNum;
    }
  }

  _retryPlannerState() async {
    _preferences = await SharedPreferences.getInstance();
    await _refreshToken();
    try {
      Dio dio = Dio();
      final response = await dio.get(
          url + '/statistics/planner',
          options: Options(
              headers: {
                HttpHeaders.authorizationHeader: _preferences.getString('accessToken') ?? ""
              }
          )
      );

      if (response.statusCode == 200) {
        PlannerState plannerState = PlannerState.fromJson(response.data);
        plannerNum = plannerState.maxPlannerToday == 0 || plannerState.successPlannerToday == 0 ? 0.0 : double.parse(((plannerState.successPlannerToday / plannerState.maxPlannerToday) * 100).toDouble().toStringAsFixed(1));
      } else {
        _preferences.remove("isAuth");
        _preferences.remove("accessToken");
        _preferences.remove("refreshToken");
        _preferences.remove("userImage");

        Navigator.of(context).pushAndRemoveUntil(
            PageTransition(
                child: StartPage(),
                type: PageTransitionType.bottomToTop
            ),
                (route) => false
        );
      }
    } catch (e) {
      print('planner percent(retry) : ' + e.toString());

      _preferences.remove("isAuth");
      _preferences.remove("accessToken");
      _preferences.remove("refreshToken");
      _preferences.remove("userImage");

      Navigator.of(context).pushAndRemoveUntil(
          PageTransition(
              child: StartPage(),
              type: PageTransitionType.bottomToTop
          ),
              (route) => false
      );
    }
  }

  Future<List<Routine>> _getRoutineMain() async {
    _preferences = await SharedPreferences.getInstance();
    try {
      Dio dio = Dio();
      final response = await dio.get(
          url + '/routine/main',
          options: Options(
              headers: {
                HttpHeaders.contentTypeHeader: 'application/json',
                HttpHeaders.authorizationHeader: _preferences.getString('accessToken') ?? ""
              }
          )
      );

      print(response.statusCode);

      print(response.data.toString());

      if (response.statusCode == 200) {
        routineItem =
            (response.data as List).map((e) => Routine.fromJson(e)).toList();

        if (routineItem.isEmpty)
          print('empty');
        else
          print(routineItem[0].title);

        return routineItem;
      }else {
        await _retryRoutine();
        return routineItem;
      }
    } catch (e) {
      print('getRoutineMain mainPage : ' + e.toString());

      await _retryRoutine();
      return routineItem;
    }
  }

  _retryRoutine() async {
    _preferences = await SharedPreferences.getInstance();
    await _refreshToken();
    try {
      Dio dio = Dio();
      final response = await dio.get(
          url + '/routine/main',
          options: Options(
              headers: {
                HttpHeaders.contentTypeHeader: 'application/json',
                HttpHeaders.authorizationHeader: _preferences.getString('accessToken') ?? ""
              }
          )
      );

      print(response.statusCode);

      print(response.data.toString());

      if (response.statusCode == 200) {
        routineItem =
            (response.data as List).map((e) => Routine.fromJson(e)).toList();

        if (routineItem.isEmpty)
          print('empty');
        else
          _logout();
      }

      return routineItem;
    } catch (e) {
      print('getRoutineMain mainPage(retry) : ' + e.toString());
      _preferences.remove("isAuth");
      _preferences.remove("accessToken");
      _preferences.remove("refreshToken");
      _preferences.remove("userImage");

      Navigator.of(context).pushAndRemoveUntil(
          PageTransition(
              child: StartPage(),
              type: PageTransitionType.bottomToTop
          ),
              (route) => false
      );
    }
  }

  Future<bool> _refreshToken() async {
    Dio dio = Dio();
    try {
      final response = await dio.put(
          url + '/auth',
          options: Options(
              headers: {
                HttpHeaders.contentTypeHeader: 'application/json',
                'X-Refresh-Token': refreshToken
              }
          )
      );

      if (response.statusCode == 200) {
        _preferences = await SharedPreferences.getInstance();

        token = Token.fromJson(response.data);

        _preferences.setString("accessToken", token.accessToken);
        _preferences.setString("refreshToken", token.refreshToken);

        await _getTokens();

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

  _checkUserImage() {
    if(initTier.isNotEmpty) {
      _setUserImage();
      isSetImage = true;
    }
  }

  _getTokens() async {
    _preferences = await SharedPreferences.getInstance();
    accessToken = _preferences.getString("accessToken") ?? "";
    refreshToken = _preferences.getString('refreshToken') ?? "";
    deviceToken = await _firebaseMessaging.getToken() ?? "";
    setState(() {
      imageName = _preferences.getString('imageName') ?? "";
    });

    if (accessToken.isEmpty || refreshToken.isEmpty || deviceToken.isEmpty) {
      _preferences.remove("isAuth");
      _preferences.remove("accessToken");
      _preferences.remove("refreshToken");
      _preferences.remove("userImage");

      Navigator.of(context).pushAndRemoveUntil(
          PageTransition(
              child: StartPage(),
              type: PageTransitionType.bottomToTop
          ),
              (route) => false
      );
    } else {
      print("accessToken : " + accessToken);
    }
  }

  @override
  void initState() {
    _getTokens();
    fPlannerItem = _getPlannerMain();
    fRoutineItem = _getRoutineMain();
    fPlannerStatistics = _getPlannerState();
    fStatistics = _getStatistics();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var _height = MediaQuery
        .of(context)
        .size
        .height;
    var _width = MediaQuery
        .of(context)
        .size
        .width;
    
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
            style: TextStyle(
                fontFamily: 'NotoSansKR',
                fontWeight: FontWeight.w700,
                fontSize: 26,
                color: Color(0xff2C2C2C)
            ),
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
                )
              )
          ),
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
                      Navigator.of(context).push(
                        PageTransition(child: UserInfoPage(), type: PageTransitionType.bottomToTop)
                      );
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
          controller: _mainPageController,
          physics: NeverScrollableScrollPhysics(),
          children: [
            ListView(
              children: [
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          margin: EdgeInsets.only(
                              top: _height * 0.08, left: _width * 0.061),
                          child: Text(
                            '오늘 루틴',
                            style: TextStyle(
                                fontFamily: 'NotoSansKR',
                                fontWeight: FontWeight.w700,
                                fontSize: 30
                            ),
                          ),
                        ),
                      ],
                    ),
                    Center(
                      child: Container(
                        margin: EdgeInsets.only(top: 10),
                        child: FutureBuilder <List<Routine>>(
                          future: _getRoutineMain(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData == false) {
                              return FadingText(
                                'Loading..',
                                style: TextStyle(
                                    fontFamily: 'NotoSansKR',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16
                                ),
                              );
                            } else if (snapshot.hasError) {
                              return _logout();
                            } else {
                              if (routineItem.isEmpty) {
                                return ListView(
                                  physics: NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  children: [
                                    Center(
                                      child: Container(
                                        child: RaisedButton(
                                          onPressed: () {
                                            showCupertinoModalBottomSheet(
                                                context: this.context,
                                                builder: (BuildContext context) => WriteRoutine()
                                            );

                                            setState(() {
                                              fRoutineItem = _getRoutineMain();
                                            });
                                          },
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius
                                                  .circular(10)
                                          ),
                                          child: Text(
                                            '오늘 루틴이 없습니다!\n 지금 루틴을 추가하세요!',
                                            style: TextStyle(
                                                fontFamily: 'NotoSansKR',
                                                fontWeight: FontWeight.w500,
                                                fontSize: 16,
                                                color: Color(0xff9B9B9B)
                                            ),
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
                                return ListView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  itemCount: routineItem.length,
                                  itemBuilder: (context, index) {
                                    String content = '';
                                    for (String week in routineItem[index]
                                        .dayOfWeeks)
                                      content += week + ' ';

                                    content += '| ' +
                                        routineItem[index].startTime.substring(
                                            0, 5) + ' ~ ' +
                                        routineItem[index].endTime.substring(
                                            0, 5);

                                    return Center(
                                      child: Container(
                                        height: 85,
                                        width: _width * 0.87,
                                        margin: EdgeInsets.only(top: 10),
                                        child: SwipeActionCell(
                                          key: ObjectKey(routineItem[index]),
                                          trailingActions: [
                                            SwipeAction(
                                              title: '성공',
                                              style: TextStyle(
                                                  fontFamily: 'NotoSansKR',
                                                  fontWeight: FontWeight.normal,
                                                  fontSize: 18,
                                                  color: Colors.blue
                                              ),
                                              onTap: (handler) async {
                                                await handler(false);
                                                _showTaost('축하합니다! 루틴을 성공하셨습니다!');
                                              },
                                              color: Color(0xffF4F4F4),
                                              backgroundRadius: 10,
                                            ),
                                            SwipeAction(
                                              title: '실패',
                                              style: TextStyle(
                                                  fontFamily: 'NotoSansKR',
                                                  fontWeight: FontWeight.normal,
                                                  fontSize: 18,
                                                  color: Colors.red
                                              ),
                                              onTap: (handler) async {
                                                await handler(false);
                                                _showTaost('이 루틴을 실패하셨습니다..ㅠㅠ');
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
                                                      child: ReadRoutineWidget(routineItem[index]),
                                                      type: PageTransitionType.rightToLeft
                                                  )
                                              );
                                            },
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment
                                                  .center,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment
                                                      .start,
                                                  children: [
                                                    Container(
                                                      margin: EdgeInsets.only(left: 20),
                                                      child: Text(
                                                        routineItem[index].title,
                                                        style: TextStyle(
                                                            fontFamily: 'NotoSansKR',
                                                            fontWeight: FontWeight.w700,
                                                            fontSize: 18,
                                                            color: Color(0xff9B9B9B)
                                                        ),
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
                                                        style: TextStyle(
                                                            fontFamily: 'NotoSansKR',
                                                            fontWeight: FontWeight.w700,
                                                            fontSize: 12,
                                                            color: Color(0xff9B9B9B)
                                                        ),
                                                      ),
                                                    )
                                                  ],
                                                )
                                              ],
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius
                                                  .circular(10),
                                            ),
                                            color: Color(0xffEAEAEA),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Container(
                              margin: EdgeInsets.only(top: 30, left: _width * 0.061),
                              child: Text(
                                '오늘 할일',
                                style: TextStyle(
                                    fontFamily: 'NotoSansKR',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 30
                                ),
                              ),
                            ),
                          ],
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                margin: EdgeInsets.only(top: 40, right: _width *
                                    0.061),
                                child: Row(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          '진행률 ',
                                          style: TextStyle(
                                              fontFamily: 'NotoSansKR',
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16,
                                              color: Color(0xff9B9B9B)
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        FutureBuilder(
                                          future: fPlannerStatistics,
                                          builder: (context, snapshot) {
                                            if (snapshot.hasData == false) {
                                              return Text(
                                                '0.0%',
                                                style: TextStyle(
                                                    fontFamily: 'NotoSansKR',
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 16,
                                                    color: Color(0xff2F5DFB)
                                                ),
                                              );
                                            } else if (snapshot.hasError) {
                                              return _logout();
                                            } else {
                                              return Text(
                                                plannerNum.toString() + '%',
                                                style: TextStyle(
                                                    fontFamily: 'NotoSansKR',
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 16,
                                                    color: Color(0xff2F5DFB)
                                                ),
                                              );
                                            }
                                          },
                                        )
                                      ],
                                    )
                                  ],
                                ),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                    Center(
                      child: Container(
                        margin: EdgeInsets.only(top: 10),
                        child: FutureBuilder <List<Planner>>(
                          future: _getPlannerMain(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData == false) {
                              return FadingText(
                                'Loading..',
                                style: TextStyle(
                                    fontFamily: 'NotoSansKR',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16
                                ),
                              );
                            } else if (snapshot.hasError) {
                              return _logout();
                            } else {
                              if (plannerItem.isEmpty) {
                                return ListView(
                                  physics: NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  children: [
                                    Center(
                                      child: Container(
                                        child: RaisedButton(
                                          onPressed: () {
                                            showCupertinoModalBottomSheet(
                                                context: this.context,
                                                builder: (context) => WritePlannerWidget()
                                            );

                                            setState(() {
                                              fPlannerItem = _getPlannerMain();
                                            });
                                          },
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius
                                                  .circular(10)
                                          ),
                                          child: Text(
                                            '오늘 할 일이 없습니다!\n 지금 할일을 추가하세요!',
                                            style: TextStyle(
                                                fontFamily: 'NotoSansKR',
                                                fontWeight: FontWeight.w500,
                                                fontSize: 16,
                                                color: Color(0xff9B9B9B)
                                            ),
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
                                return ListView.builder(
                                    physics: NeverScrollableScrollPhysics(),
                                    shrinkWrap: true,
                                    itemCount: plannerItem.length == 0
                                        ? 1
                                        : plannerItem.length,
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
                                        else if (want == "FIVE")
                                          itemColor = Color(0xff1BB778);
                                        else
                                          itemColor = Color(0xff2F5DFB);

                                        content =
                                            '중요도 : ' +
                                                plannerItem[index].priority +
                                                ' | ' +
                                                plannerItem[index].startTime
                                                    .substring(0, 5) + ' ~ ' +
                                                plannerItem[index].endTime
                                                    .substring(
                                                    0, 5);
                                        itemTextColor = Color(0xffFFFFFF);
                                      } else {
                                        content =
                                            '중요도 : ' +
                                                plannerItem[index].priority +
                                                ' | ' +
                                                plannerItem[index].startTime
                                                    .substring(0, 5) + ' ~ ' +
                                                plannerItem[index].endTime
                                                    .substring(
                                                    0, 5);

                                        itemColor = Color(0xffF4F4F4);
                                        itemTextColor = Color(0xff9B9B9B);
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
                                                style: TextStyle(
                                                    fontFamily: 'NotoSansKR',
                                                    fontWeight: FontWeight
                                                        .normal,
                                                    fontSize: 18,
                                                    color: Colors.blue
                                                ),
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
                                                            Navigator.of(context).pop();
                                                          },
                                                          onNegativeClick: () {
                                                            _showTaost('취소');
                                                            Navigator.of(context).pop();
                                                          },
                                                          positiveText: '네..',
                                                          negativeText: '아니요!',
                                                          negativeTextStyle: TextStyle(
                                                              color: Colors.red,
                                                              fontFamily: 'NotoSansKR',
                                                              fontWeight: FontWeight.w500,
                                                              fontSize: 16
                                                          ),
                                                          positiveTextStyle: TextStyle(
                                                              color: Color(0xff2F5DFB),
                                                              fontFamily: 'NotoSansKR',
                                                              fontWeight: FontWeight.w500,
                                                              fontSize: 16
                                                          ),
                                                        );
                                                      }
                                                  );
                                                },
                                                color: Color(0xffF4F4F4),
                                                backgroundRadius: 10,
                                              ),
                                              SwipeAction(
                                                title: '실패',
                                                style: TextStyle(
                                                    fontFamily: 'NotoSansKR',
                                                    fontWeight: FontWeight
                                                        .normal,
                                                    fontSize: 18,
                                                    color: Colors.red
                                                ),
                                                onTap: (handler) async {
                                                  await handler(false);
                                                  _showTaost('이 할일을 실패하셨습니다..ㅠㅠ');
                                                  await failedPlanner(plannerItem[index].plannerId);
                                                },
                                                color: Color(0xffF4F4F4),
                                                backgroundRadius: 10,
                                              ),
                                              SwipeAction(
                                                title: '미루기',
                                                style: TextStyle(
                                                    fontFamily: 'NotoSansKR',
                                                    fontWeight: FontWeight
                                                        .normal,
                                                    fontSize: 18,
                                                    color: Color(0xff9B9B9B)
                                                ),
                                                onTap: (handler) async {
                                                  await handler(false);
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
                                                            plannerItem[index].want
                                                        ),
                                                        type: PageTransitionType.rightToLeft)
                                                );
                                              },
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment
                                                    .center,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment
                                                        .start,
                                                    children: [
                                                      Container(
                                                        margin: EdgeInsets.only(
                                                            left: 20),
                                                        child: Text(
                                                          plannerItem[index]
                                                              .title,
                                                          style: TextStyle(
                                                              fontFamily: 'NotoSansKR',
                                                              fontWeight: FontWeight
                                                                  .w700,
                                                              fontSize: 18,
                                                              color: itemTextColor
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment
                                                        .start,
                                                    children: [
                                                      Container(
                                                        margin: EdgeInsets.only(
                                                            top: 10, left: 20),
                                                        child: Text(
                                                          content,
                                                          style: TextStyle(
                                                              fontFamily: 'NotoSansKR',
                                                              fontWeight: FontWeight
                                                                  .w700,
                                                              fontSize: 12,
                                                              color: itemTextColor
                                                          ),
                                                        ),
                                                      )
                                                    ],
                                                  )
                                                ],
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius
                                                    .circular(10),
                                              ),
                                              color: itemColor,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          margin: EdgeInsets.only(
                              top: 30, left: _width * 0.061),
                          child: Text(
                            '통계',
                            style: TextStyle(
                                fontFamily: 'NotoSansKR',
                                fontWeight: FontWeight.w700,
                                fontSize: 30
                            ),
                          ),
                        ),
                      ],
                    ),
                    FutureBuilder <Statistics>(
                      future: fStatistics,
                      builder: (context, snapshot) {
                        if (snapshot.hasData == false) {
                          return FadingText(
                            'Loading..',
                            style: TextStyle(
                                fontFamily: 'NotoSansKR',
                                fontWeight: FontWeight.w700,
                                fontSize: 16
                            ),
                          );
                        } else if (snapshot.hasError) {
                          return _logout();
                        } else {
                          double week = statiistics.weekSucceed == 0
                              ? 0
                              : (statiistics.weekSucceed / statiistics.maxWeek) *
                              100;
                          double month = statiistics.monthSucceed == 0
                              ? 0
                              : statiistics.monthSucceed / statiistics.maxMonth * 100;

                          print(statiistics.maxMonth);
                          print(statiistics.monthSucceed);
                          print(month);

                          List<double> datas = [];
                          List<String> x = [];
                          statiistics.pointResponses.forEach((element) {
                            x.add(element.date.toString());
                            datas.add(element.succeedNum.toDouble() / 10);
                          });

                          print(x);
                          print(datas);

                          return Container(
                              margin: EdgeInsets.only(top: 10),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        margin: EdgeInsets.only(right: 10),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(20)),
                                          color: Color(0xffF4F4F4),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment
                                              .center,
                                          children: [
                                            Container(
                                              child: AnimatedCircularChart(
                                                size: Size(130, 130),
                                                initialChartData: <
                                                    CircularStackEntry>[
                                                  CircularStackEntry(
                                                      <CircularSegmentEntry>[
                                                        CircularSegmentEntry(
                                                            week,
                                                            Color(0xff2F5DFB),
                                                            rankKey: 'succeed'
                                                        ),
                                                        CircularSegmentEntry(
                                                            100 - week,
                                                            Color(0xffD1D1D1),
                                                            rankKey: 'empty'
                                                        ),
                                                      ],
                                                      rankKey: 'week'
                                                  )
                                                ],
                                                chartType: CircularChartType
                                                    .Radial,
                                                percentageValues: false,
                                                holeLabel: week.toStringAsFixed(1) +
                                                    '%',
                                                labelStyle: TextStyle(
                                                  color: Color(0xff2F5DFB),
                                                  fontFamily: 'NotoSansKR',
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment
                                                  .start,
                                              children: [
                                                Container(
                                                  margin: EdgeInsets.only(
                                                      top: 5, left: 20),
                                                  child: Text(
                                                    '이번주 성공률',
                                                    style: TextStyle(
                                                        fontFamily: 'NotoSansKR',
                                                        fontWeight: FontWeight
                                                            .w700,
                                                        fontSize: 18,
                                                        color: Color(0xff9B9B9B)
                                                    ),
                                                  ),
                                                )
                                              ],
                                            )
                                          ],
                                        ),
                                        width: 175,
                                        height: 175,
                                      ),
                                      Container(
                                        margin: EdgeInsets.only(left: 10),
                                        decoration: BoxDecoration(
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(20)),
                                            color: Color(0xffF4F4F4)
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment
                                              .center,
                                          children: [
                                            Container(
                                              child: AnimatedCircularChart(
                                                size: Size(130, 130),
                                                initialChartData: <
                                                    CircularStackEntry>[
                                                  CircularStackEntry(
                                                      <CircularSegmentEntry>[
                                                        CircularSegmentEntry(
                                                            month,
                                                            Color(0xff2F5DFB),
                                                            rankKey: 'succeed'
                                                        ),
                                                        CircularSegmentEntry(
                                                            100 - month,
                                                            Color(0xffD1D1D1),
                                                            rankKey: 'empty'
                                                        ),
                                                      ],
                                                      rankKey: 'month'
                                                  )
                                                ],
                                                chartType: CircularChartType
                                                    .Radial,
                                                percentageValues: true,
                                                holeLabel: month.toStringAsFixed(1) +
                                                    '%',
                                                labelStyle: TextStyle(
                                                  color: Color(0xff2F5DFB),
                                                  fontFamily: 'NotoSansKR',
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment
                                                  .start,
                                              children: [
                                                Container(
                                                  margin: EdgeInsets.only(
                                                      top: 5, left: 20),
                                                  child: Text(
                                                    '이번달 성공률',
                                                    style: TextStyle(
                                                        fontFamily: 'NotoSansKR',
                                                        fontWeight: FontWeight
                                                            .w700,
                                                        fontSize: 18,
                                                        color: Color(0xff9B9B9B)
                                                    ),
                                                  ),
                                                )
                                              ],
                                            ),
                                          ],
                                        ),
                                        width: 175,
                                        height: 175,
                                      )
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        margin: EdgeInsets.only(
                                            top: 20, bottom: 100),
                                        decoration: BoxDecoration(
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(20)),
                                            color: Color(0xffF4F4F4)
                                        ),
                                        child: Column(
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment
                                                  .start,
                                              children: [
                                                Container(
                                                  margin: EdgeInsets.only(
                                                      top: 20,
                                                      left: 20,
                                                      bottom: 10),
                                                  child: Text(
                                                    '최근 완료한 할 일 통계',
                                                    style: TextStyle(
                                                        fontFamily: 'NotoSansKR',
                                                        fontWeight: FontWeight
                                                            .w700,
                                                        fontSize: 18,
                                                        color: Color(0xff9B9B9B)
                                                    ),
                                                  ),
                                                )
                                              ],
                                            ),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment
                                                  .center,
                                              children: [
                                                Container(
                                                  margin: EdgeInsets.only(
                                                      right: 10, bottom: 30),
                                                  child: LineGraph(
                                                    features: [
                                                      Feature(
                                                        title: 'succeed',
                                                        color: Color(
                                                            0xff2F5DFB),
                                                        data: datas,
                                                      )
                                                    ],
                                                    labelX: x,
                                                    labelY: ['3', '6', '9', '12'],
                                                    size: Size(
                                                        _width * 0.79, 120),
                                                    showDescription: false,
                                                    verticalFeatureDirection: true,
                                                    graphColor: Color(
                                                        0xffC4C4C4),
                                                    graphOpacity: 0.3,
                                                  ),
                                                )
                                              ],
                                            ),
                                          ],
                                        ),
                                        width: _width * 0.87,
                                      )
                                    ],
                                  )
                                ],
                              )
                          );
                        }
                      },
                    )
                  ],
                ),
              ],
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
                                hintStyle: TextStyle(
                                    fontFamily: 'NotoSansKR',
                                    fontWeight: FontWeight.normal,
                                    fontSize: 16,
                                    color: Color(0xffD1D1D1)
                                ),
                                textStyle: TextStyle(
                                    fontFamily: 'NotoSansKR',
                                    fontWeight: FontWeight.normal,
                                    fontSize: 16,
                                    color: Color(0xff9B9B9B)
                                ),
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
                                          style: TextStyle(
                                              fontFamily: 'NotoSansKR',
                                              fontWeight: FontWeight.w500,
                                              fontSize: 20,
                                              color: Color(0xffD1D1D1)
                                          ),
                                        ),
                                      )
                                  ),
                                  Visibility(
                                      visible: !_notSearch,
                                      child: FutureBuilder <SearchPlanner>(
                                        future: _searchPlanner(title),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasData == false) {
                                            return FadingText(
                                              'Loading..',
                                              style: TextStyle(
                                                  fontFamily: 'NotoSansKR',
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 16
                                              ),
                                            );
                                          } else if (snapshot.hasError) {
                                            return _logout();
                                          } else {
                                            if (searchPlanner.planners.isEmpty ||
                                                title.length == 0) {
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
                                                          style: TextStyle(
                                                              fontFamily: 'NotoSansKR',
                                                              fontWeight: FontWeight
                                                                  .w700,
                                                              fontSize: 25
                                                          ),
                                                        ),
                                                      ),
                                                      Container(
                                                        margin: EdgeInsets.only(left: 10),
                                                        child: Text(
                                                          title.length == 0
                                                              ? '0'
                                                              : searchPlanner.searchNum
                                                              .toString(),
                                                          style: TextStyle(
                                                              fontFamily: 'NotoSansKR',
                                                              fontWeight: FontWeight
                                                                  .w700,
                                                              fontSize: 27,
                                                              color: Color(0xff2F5DFB)
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  ListView(
                                                    shrinkWrap: true,
                                                    children: [
                                                      Center(
                                                        child: Container(
                                                          margin: EdgeInsets.only(
                                                              top: 20),
                                                          child: RaisedButton(
                                                            onPressed: () {

                                                            },
                                                            shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius
                                                                    .circular(10)
                                                            ),
                                                            child: Text(
                                                              '검색된 할 일이 없습니다!\n 지금 할일을 추가하세요!',
                                                              style: TextStyle(
                                                                  fontFamily: 'NotoSansKR',
                                                                  fontWeight: FontWeight
                                                                      .w500,
                                                                  fontSize: 16,
                                                                  color: Color(
                                                                      0xff9B9B9B)
                                                              ),
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
                                                    mainAxisAlignment: MainAxisAlignment
                                                        .start,
                                                    children: [
                                                      Container(
                                                        margin: EdgeInsets.only(top: 20, left: _width * 0.061, bottom: 10),
                                                        child: Text(
                                                          '검색된 할 일 목록',
                                                          style: TextStyle(
                                                              fontFamily: 'NotoSansKR',
                                                              fontWeight: FontWeight
                                                                  .w700,
                                                              fontSize: 25
                                                          ),
                                                        ),
                                                      ),
                                                      Container(
                                                        margin: EdgeInsets.only(left: 10),
                                                        child: Text(
                                                          searchPlanner.searchNum
                                                              .toString(),
                                                          style: TextStyle(
                                                              fontFamily: 'NotoSansKR',
                                                              fontWeight: FontWeight
                                                                  .w700,
                                                              fontSize: 27,
                                                              color: Color(0xff2F5DFB)
                                                          ),
                                                        ),
                                                      ),
                                                      Container(
                                                        margin: EdgeInsets.only(
                                                            top: 6),
                                                        child: IconButton(
                                                          onPressed: () {

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
                                                      itemCount: searchPlanner.planners
                                                          .length == 0
                                                          ? 1
                                                          : searchPlanner.planners
                                                          .length,
                                                      itemBuilder: (context, index) {
                                                        Color itemColor;
                                                        Color itemTextColor;

                                                        String content = "";


                                                        String want = searchPlanner
                                                            .planners[index].want;

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

                                                          content =
                                                              '중요도 : ' +
                                                                  searchPlanner.planners[index].priority +
                                                                  ' | ' +
                                                                  searchPlanner.planners[index].startTime
                                                                      .substring(0, 5) + ' ~ ' +
                                                                  searchPlanner.planners[index].endTime
                                                                      .substring(
                                                                      0, 5);
                                                          itemTextColor = Color(0xffFFFFFF);
                                                        } else {
                                                          itemColor = Color(0xffF4F4F4);
                                                          itemTextColor = Color(0xff9B9B9B);

                                                          content =
                                                              '중요도 : ' +
                                                                  searchPlanner.planners[index].priority +
                                                                  ' | ' +
                                                                  searchPlanner.planners[index].startTime
                                                                      .substring(0, 5) + ' ~ ' +
                                                                  searchPlanner.planners[index].endTime
                                                                      .substring(
                                                                      0, 5);
                                                        }
                                                        return Center(
                                                          child: Container(
                                                            height: 85,
                                                            width: _width * 0.87,
                                                            margin: EdgeInsets.only(
                                                                top: 10),
                                                            child: SwipeActionCell(
                                                              key: ObjectKey(
                                                                  searchPlanner
                                                                      .planners[index]),
                                                              performsFirstActionWithFullSwipe: true,
                                                              trailingActions: [
                                                                SwipeAction(
                                                                  title: '성공',
                                                                  style: TextStyle(
                                                                      fontFamily: 'NotoSansKR',
                                                                      fontWeight: FontWeight
                                                                          .normal,
                                                                      fontSize: 18,
                                                                      color: Colors.blue
                                                                  ),
                                                                  onTap: (
                                                                      handler) async {
                                                                    await handler(
                                                                        false);
                                                                    _showTaost(
                                                                        '축하합니다! 할일을 성공하셨습니다!');
                                                                  },
                                                                  color: Color(
                                                                      0xffF4F4F4),
                                                                  backgroundRadius: 10,
                                                                ),
                                                                SwipeAction(
                                                                  title: '실패',
                                                                  style: TextStyle(
                                                                      fontFamily: 'NotoSansKR',
                                                                      fontWeight: FontWeight
                                                                          .normal,
                                                                      fontSize: 18,
                                                                      color: Colors.red
                                                                  ),
                                                                  onTap: (
                                                                      handler) async {
                                                                    await handler(
                                                                        false);
                                                                    _showTaost(
                                                                        '이 할일을 실패하셨습니다..ㅠㅠ');
                                                                  },
                                                                  color: Color(
                                                                      0xffF4F4F4),
                                                                  backgroundRadius: 10,
                                                                ),
                                                                SwipeAction(
                                                                  title: '미루기',
                                                                  style: TextStyle(
                                                                      fontFamily: 'NotoSansKR',
                                                                      fontWeight: FontWeight
                                                                          .normal,
                                                                      fontSize: 18,
                                                                      color: Color(
                                                                          0xff9B9B9B)
                                                                  ),
                                                                  onTap: (
                                                                      handler) async {
                                                                    await handler(
                                                                        false);
                                                                  },
                                                                  color: Color(
                                                                      0xffF4F4F4),
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
                                                                              searchPlanner.planners[index].want
                                                                          ),
                                                                          type: PageTransitionType.rightToLeft)
                                                                  );
                                                                },
                                                                child: Column(
                                                                  mainAxisAlignment: MainAxisAlignment
                                                                      .center,
                                                                  children: [
                                                                    Row(
                                                                      mainAxisAlignment: MainAxisAlignment
                                                                          .start,
                                                                      children: [
                                                                        Container(
                                                                          margin: EdgeInsets
                                                                              .only(
                                                                              left: 20),
                                                                          child: Text(
                                                                            searchPlanner
                                                                                .planners[index]
                                                                                .title,
                                                                            style: TextStyle(
                                                                                fontFamily: 'NotoSansKR',
                                                                                fontWeight: FontWeight
                                                                                    .w700,
                                                                                fontSize: 18,
                                                                                color: itemTextColor
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    Row(
                                                                      mainAxisAlignment: MainAxisAlignment
                                                                          .start,
                                                                      children: [
                                                                        Container(
                                                                          margin: EdgeInsets
                                                                              .only(
                                                                              top: 10,
                                                                              left: 20),
                                                                          child: Text(
                                                                            content,
                                                                            style: TextStyle(
                                                                                fontFamily: 'NotoSansKR',
                                                                                fontWeight: FontWeight
                                                                                    .w700,
                                                                                fontSize: 12,
                                                                                color: itemTextColor
                                                                            ),
                                                                          ),
                                                                        )
                                                                      ],
                                                                    )
                                                                  ],
                                                                ),
                                                                shape: RoundedRectangleBorder(
                                                                  borderRadius: BorderRadius
                                                                      .circular(10),
                                                                ),
                                                                color: itemColor,
                                                              ),
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                  ),
                                                ],
                                              );
                                            }
                                          }
                                        },
                                      )
                                  ),
                                  Container(
                                    margin: EdgeInsets.only(bottom: 200),
                                    child: Visibility(
                                        visible: !_notSearch,
                                        child: FutureBuilder <SearchRoutine>(
                                          future: _searchRoutine(title),
                                          builder: (context, snapshot) {
                                            if (snapshot.hasData == false) {
                                              return FadingText(
                                                'Loading..',
                                                style: TextStyle(
                                                    fontFamily: 'NotoSansKR',
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 16
                                                ),
                                              );
                                            } else if (snapshot.hasError) {
                                              return _logout();
                                            } else {
                                              if (searchRoutine.routines.isEmpty || title.length == 0) {
                                                return Column(
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment
                                                          .start,
                                                      children: [
                                                        Container(
                                                          margin: EdgeInsets.only(top: 20, left: _width * 0.061, bottom: 10),
                                                          child: Text(
                                                            '검색된 루틴 목록',
                                                            style: TextStyle(
                                                                fontFamily: 'NotoSansKR',
                                                                fontWeight: FontWeight
                                                                    .w700,
                                                                fontSize: 25
                                                            ),
                                                          ),
                                                        ),
                                                        Container(
                                                          margin: EdgeInsets.only(
                                                              top: 26, left: 10),
                                                          child: Text(
                                                            title.length == 0
                                                                ? '0'
                                                                : searchPlanner.searchNum
                                                                .toString(),
                                                            style: TextStyle(
                                                                fontFamily: 'NotoSansKR',
                                                                fontWeight: FontWeight
                                                                    .w700,
                                                                fontSize: 27,
                                                                color: Color(0xff2F5DFB)
                                                            ),
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
                                                              onPressed: () {

                                                              },
                                                              shape: RoundedRectangleBorder(
                                                                  borderRadius: BorderRadius
                                                                      .circular(10)
                                                              ),
                                                              child: Text(
                                                                '검색된 루틴이 없습니다!\n 지금 루틴을 추가하세요!',
                                                                style: TextStyle(
                                                                    fontFamily: 'NotoSansKR',
                                                                    fontWeight: FontWeight.w500,
                                                                    fontSize: 16,
                                                                    color: Color(0xff9B9B9B)
                                                                ),
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
                                                      mainAxisAlignment: MainAxisAlignment.start ,
                                                      children: [
                                                        Container(
                                                          margin: EdgeInsets.only(top: 20, left: _width * 0.061, bottom: 10),
                                                          child: Text(
                                                            '검색된 루틴 목록',
                                                            style: TextStyle(
                                                                fontFamily: 'NotoSansKR',
                                                                fontWeight: FontWeight
                                                                    .w700,
                                                                fontSize: 25
                                                            ),
                                                          ),
                                                        ),
                                                        Container(
                                                          margin: EdgeInsets.only(
                                                              top: 6, left: 10),
                                                          child: Text(
                                                            searchRoutine.searchNum
                                                                .toString(),
                                                            style: TextStyle(
                                                                fontFamily: 'NotoSansKR',
                                                                fontWeight: FontWeight
                                                                    .w700,
                                                                fontSize: 27,
                                                                color: Color(0xff2F5DFB)
                                                            ),
                                                          ),
                                                        ),
                                                        Container(
                                                          margin: EdgeInsets.only(
                                                              top: 6),
                                                          child: IconButton(
                                                            onPressed: () {

                                                            },
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
                                                        for (String week in searchRoutine.routines[index]
                                                            .dayOfWeeks)
                                                          content += week + ' ';

                                                        content += '| ' +
                                                            searchRoutine.routines[index].startTime.substring(
                                                                0, 5) + ' ~ ' +
                                                            searchRoutine.routines[index].endTime.substring(
                                                                0, 5);

                                                        return Center(
                                                          child: Container(
                                                            height: 85,
                                                            width: _width * 0.87,
                                                            margin: EdgeInsets.only(top: 10),
                                                            child: SwipeActionCell(
                                                              key: ObjectKey(searchRoutine.routines[index]),
                                                              trailingActions: [
                                                                SwipeAction(
                                                                  title: '성공',
                                                                  style: TextStyle(
                                                                      fontFamily: 'NotoSansKR',
                                                                      fontWeight: FontWeight.normal,
                                                                      fontSize: 18,
                                                                      color: Colors.blue
                                                                  ),
                                                                  onTap: (handler) async {
                                                                    await handler(false);
                                                                    _showTaost(
                                                                        '축하합니다! 할일을 성공하셨습니다!');
                                                                  },
                                                                  color: Color(0xffF4F4F4),
                                                                  backgroundRadius: 10,
                                                                ),
                                                                SwipeAction(
                                                                  title: '실패',
                                                                  style: TextStyle(
                                                                      fontFamily: 'NotoSansKR',
                                                                      fontWeight: FontWeight.normal,
                                                                      fontSize: 18,
                                                                      color: Colors.red
                                                                  ),
                                                                  onTap: (handler) async {
                                                                    await handler(false);
                                                                    _showTaost('이 할일을 실패하셨습니다..ㅠㅠ');
                                                                  },
                                                                  color: Color(0xffF4F4F4),
                                                                  backgroundRadius: 10,
                                                                ),
                                                              ],
                                                              child: RaisedButton(
                                                                elevation: 0,
                                                                onPressed: () {

                                                                },
                                                                child: Column(
                                                                  mainAxisAlignment: MainAxisAlignment
                                                                      .center,
                                                                  children: [
                                                                    Row(
                                                                      mainAxisAlignment: MainAxisAlignment
                                                                          .start,
                                                                      children: [
                                                                        Container(
                                                                          margin: EdgeInsets.only(
                                                                              left: 20),
                                                                          child: Text(
                                                                            searchRoutine.routines[index]
                                                                                .title,
                                                                            style: TextStyle(
                                                                                fontFamily: 'NotoSansKR',
                                                                                fontWeight: FontWeight
                                                                                    .w700,
                                                                                fontSize: 18,
                                                                                color: Color(
                                                                                    0xff9B9B9B)
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    Row(
                                                                      mainAxisAlignment: MainAxisAlignment
                                                                          .start,
                                                                      children: [
                                                                        Container(
                                                                          margin: EdgeInsets.only(
                                                                              top: 10, left: 20),
                                                                          child: Text(
                                                                            content,
                                                                            style: TextStyle(
                                                                                fontFamily: 'NotoSansKR',
                                                                                fontWeight: FontWeight
                                                                                    .w700,
                                                                                fontSize: 12,
                                                                                color: Color(
                                                                                    0xff9B9B9B)
                                                                            ),
                                                                          ),
                                                                        )
                                                                      ],
                                                                    )
                                                                  ],
                                                                ),
                                                                shape: RoundedRectangleBorder(
                                                                  borderRadius: BorderRadius
                                                                      .circular(10),
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
                                        )
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                )
            )
          ],
        )
    );
  }
}

class Token {
  final String accessToken;
  final String refreshToken;

  Token({required this.accessToken, required this.refreshToken});

  factory Token.fromJson(Map<String, dynamic> tokenMap) {
    return Token(
        accessToken: tokenMap['accessToken'],
        refreshToken: tokenMap['refreshToken']
    );
  }
}

class Error {
  final String message;
  final int status;

  Error({required this.message, required this.status});

  factory Error.fromJson(Map<String, dynamic> errorMap) {
    return Error(
        message: errorMap['message'],
        status: errorMap['status']
    );
  }
}

class Planner {
  int plannerId;
  String title, content, startTime, endTime, startDate, endDate;
  String priority;
  String want;
  bool isPushed, isSucceed, isFailed;
  String expType;

  Planner({
    required this.plannerId,
    required this.title,
    required this.content,
    required this.startTime,
    required this.endTime,
    required this.startDate,
    required this.endDate,
    required this.want,
    required this.priority,
    required this.isPushed,
    required this.isSucceed,
    required this.expType,
    required this.isFailed
  });

  factory Planner.fromJson(Map<String, dynamic> plannerJson) {
    return Planner(
        plannerId: plannerJson['plannerId'],
        title: plannerJson['title'],
        content: plannerJson['content'],
        startTime: plannerJson['startTime'],
        endTime: plannerJson['endTime'],
        startDate: plannerJson['startDate'],
        endDate: plannerJson['endDate'],
        want: plannerJson['want'],
        priority: plannerJson['priority'],
        isPushed: plannerJson['isPushed'],
        isSucceed: plannerJson['isSuccess'],
        expType: plannerJson['expType'],
        isFailed: plannerJson['isFailed']
    );
  }
}

class Routine {
  int routineId;
  String title, content, startTime, endTime, priority;
  bool isSuccess, isPushed, isFailed;
  List<dynamic> dayOfWeeks;

  Routine({
    required this.routineId,
    required this.title,
    required this.content,
    required this.startTime,
    required this.endTime,
    required this.isSuccess,
    required this.isPushed,
    required this.priority,
    required this.dayOfWeeks,
    required this.isFailed
  });

  factory Routine.fromJson(Map<String, dynamic> routineJson) {
    return Routine(
        routineId: routineJson['routineId'],
        title: routineJson['title'],
        content: routineJson['content'],
        startTime: routineJson['startTime'],
        endTime: routineJson['endTime'],
        isSuccess: routineJson['isSuccess'],
        isPushed: routineJson['isPushed'],
        priority: routineJson['priority'],
        dayOfWeeks: routineJson['dayOfWeeks'],
        isFailed: routineJson['isFailed']
    );
  }
}

enum ExpType {
  PLANNER,
  ROUTINE,
  PLANNER_10,
  ROUTINE_10,
  PLANNER_100,
  ROUTINE_100,
  PLANNER_1000,
  ROUTINE_1000,
  SUCCEED_PLANNER,
  SUCCEED_ROUTINE,
  SUCCEED_PLANNER_10,
  SUCCEED_ROUTINE_10,
  SUCCEED_PLANNER_100,
  SUCCEED_ROUTINE_100,
  SUCCEED_PLANNER_1000,
  SUCCEED_ROUTINE_1000,
  MEMO,
  FIRST_PLANNER,
  FIRST_ROUTINE,
  FIRST_MEMO,
  FIRST_GOAL,
  GOAL
}

enum Want {
  ONE,
  TWO,
  THREE,
  FOUR,
  FIVE
}

class Statistics {
  int maxWeek;
  int weekSucceed;
  int maxMonth;
  int monthSucceed;
  List<PointResponses> pointResponses;

  Statistics({
    required this.maxWeek,
    required this.weekSucceed,
    required this.maxMonth,
    required this.monthSucceed,
    required this.pointResponses
  });

  factory Statistics.fromJson(Map<String, dynamic> json) {
    List<PointResponses> pointResponses = [];
    if (json['pointResponses'] != null) {
      pointResponses = <PointResponses>[];
      json['pointResponses'].forEach((v) {
        pointResponses.add(new PointResponses.fromJson(v));
      });
    }

    return Statistics(
        maxWeek: json['maxWeek'],
        weekSucceed: json['weekSucceed'],
        maxMonth: json['maxMonth'],
        monthSucceed: json['monthSucceed'],
        pointResponses: pointResponses
    );
  }
}

class PointResponses {
  int succeedNum;
  int date;

  PointResponses({required this.succeedNum, required this.date});

  factory PointResponses.fromJson(Map<String, dynamic> json) {
    print(json['succeedNum'].toString() + ' ' + json['date'].toString());

    return PointResponses(succeedNum: json['succeedNum'], date: json['date']);
  }
}

class PlannerState {
  int maxPlannerToday, successPlannerToday;

  PlannerState({required this.maxPlannerToday, required this.successPlannerToday});

  factory PlannerState.fromJson(Map<String, dynamic> json) {
    return PlannerState(
        maxPlannerToday: json['maxPlannerToday'],
        successPlannerToday: json['successPlannerToday']
    );
  }
}

class SearchPlanner {
  int searchNum;
  List<Planner> planners;

  SearchPlanner({required this.searchNum, required this.planners});

  factory SearchPlanner.fromJson(Map<String, dynamic> json) {
    List<Planner> planners = [];
    if (json['plannerResponses'] != null) {
      json['plannerResponses'].forEach((e) {
        planners.add(Planner.fromJson(e));
      });
    }

    return SearchPlanner(
        searchNum: json['searchNum'],
        planners: planners
    );
  }
}

class SearchRoutine {
  int searchNum;
  List<Routine> routines;

  SearchRoutine({required this.searchNum, required this.routines});

  factory SearchRoutine.fromJson(Map<String, dynamic> json) {
    List<Routine> routines = [];
    if (json['routineResponses'] != null) {
      json['routineResponses'].forEach((e) {
        routines.add(Routine.fromJson(e));
      });
    }

    return SearchRoutine(
        searchNum: json['searchNum'],
        routines: routines
    );
  }
}
