import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_swipe_action_cell/core/cell.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:imagebutton/imagebutton.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:online_planner_app/detail/login/login_detail.dart';
import 'package:online_planner_app/detail/planner/ReadPlanner.dart';
import 'package:online_planner_app/detail/planner/WritePlanner.dart';
import 'package:online_planner_app/detail/routine/ReadRoutine.dart';
import 'package:online_planner_app/detail/user_info/user_info_detail.dart';
import 'package:online_planner_app/login/login_page.dart';
import 'package:online_planner_app/main/main_page.dart';
import 'package:online_planner_app/main/notice_page.dart';
import 'package:outline_search_bar/outline_search_bar.dart';
import 'package:page_transition/page_transition.dart';
import 'package:progress_indicators/progress_indicators.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../SideMenuWidget.dart';
import 'WriteRoutine.dart';

class RoutinePage extends StatefulWidget {
  String tier = "";

  RoutinePage(this.tier);

  _RoutineWidget createState() => _RoutineWidget(tier);
}

class _RoutineWidget extends State<RoutinePage> {
  _RoutineWidget(this.initTier);

  int pageNum = 0;

  String initTier = "";
  String nickName = "", tier = "";
  int exp = -1, maxExp = -1, userLevel = -1;

  ScrollController _scrollController = ScrollController();
  late UserInfo userInfo;

  late SearchPlanner searchPlanner;
  late SearchRoutine searchRoutine;

  late List<Routine> routineItem;

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

  _deletePlanner(int routineId) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    try {
      Dio dio = Dio();
      final response = await dio.delete(
          url + '/routine/' + routineId.toString(),
          options: Options(
              headers: {
                HttpHeaders.authorizationHeader: preferences.getString('accessToken') ?? ""
              }
          )
      );

      if(response.statusCode == 200) {
        _showTaost('삭제되었습니다!');
      }
    }catch(e) {
      await _retryDeletePlanner(routineId);
    }
  }

  _retryDeletePlanner(int routineId) async {
    await _refreshToken();
    SharedPreferences preferences = await SharedPreferences.getInstance();
    try {
      Dio dio = Dio();
      final response = await dio.delete(
          url + '/routine/' + routineId.toString(),
          options: Options(
              headers: {
                HttpHeaders.authorizationHeader: preferences.getString('accessToken') ?? ""
              }
          )
      );

      if(response.statusCode == 200) {
        _showTaost('삭제되었습니다!');
      }
    }catch(e) {
      await _logout();
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

  Future<List<Routine>> _getRoutine() async {
    _preferences = await SharedPreferences.getInstance();
    try {
      Dio dio = Dio();
      final response = await dio.get(url + '/routine/' + pageNum.toString(), options: Options(headers: {HttpHeaders.authorizationHeader: _preferences.getString('accessToken') ?? ""}));

      if (response.statusCode == 200) {
        routineItem = (response.data as List).map((e) => Routine.fromJson(e)).toList();
      }

      return routineItem;
    } catch (e) {
      await _retryGetRoutines();
      return routineItem;
    }
  }

  _retryGetRoutines() async {
    await _refreshToken();
    _preferences = await SharedPreferences.getInstance();
    try {
      Dio dio = Dio();
      final response = await dio.get(url + '/routine/' + pageNum.toString(), options: Options(headers: {HttpHeaders.authorizationHeader: _preferences.getString('accessToken') ?? ""}));

      if (response.statusCode == 200) {
        routineItem = (response.data as List).map((e) => Routine.fromJson(e)).toList();
      }
    } catch (e) {
      await _logout();
    }
  }

  Future<List<Routine>> _pagingRoutine() async {
    _preferences = await SharedPreferences.getInstance();
    try {
      Dio dio = Dio();
      final response = await dio.get(url + '/routine/' + pageNum.toString(), options: Options(headers: {HttpHeaders.authorizationHeader: _preferences.getString('accessToken') ?? ""}));

      if (response.statusCode == 200) {
        routineItem.addAll((response.data as List).map((e) => Routine.fromJson(e)).toList());
      }

      return routineItem;
    } catch (e) {
      await _retryPagingRoutine();
      return routineItem;
    }
  }

  _retryPagingRoutine() async {
    await _refreshToken();
    _preferences = await SharedPreferences.getInstance();
    try {
      Dio dio = Dio();
      final response = await dio.get(url + '/routine/' + pageNum.toString(), options: Options(headers: {HttpHeaders.authorizationHeader: _preferences.getString('accessToken') ?? ""}));

      if (response.statusCode == 200) {
        routineItem.addAll((response.data as List).map((e) => Routine.fromJson(e)).toList());
      }

      return routineItem;
    } catch (e) {
      await _retryGetRoutines();
      return routineItem;
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
            _retryPagingRoutine();
          });
        }
      }
    });
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
                                '루틴 관리',
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
                                showCupertinoModalBottomSheet(context: context, builder: (context) => WriteRoutine());
                              },
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                  Center(
                    child: Container(
                      margin: EdgeInsets.only(top: 10),
                      child: FutureBuilder<List<Routine>>(
                        future: _getRoutine(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData == false) {
                            return FadingText(
                              'Loading..',
                              style: TextStyle(fontFamily: 'NotoSansKR', fontWeight: FontWeight.w700, fontSize: 16),
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
                                          showCupertinoModalBottomSheet(context: this.context, builder: (BuildContext context) => WriteRoutine());
                                        },
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        child: Text(
                                          '오늘 루틴이 없습니다!\n 지금 루틴을 추가하세요!',
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
                              return ListView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: routineItem.length,
                                itemBuilder: (context, index) {
                                  String content = '';
                                  for (String week in routineItem[index].dayOfWeeks) content += week + ' ';

                                  content += '| ' + routineItem[index].startTime.substring(0, 5) + ' ~ ' + routineItem[index].endTime.substring(0, 5);

                                  return Center(
                                    child: Container(
                                      height: 85,
                                      width: _width * 0.87,
                                      margin: EdgeInsets.only(top: 10),
                                      child: SwipeActionCell(
                                        key: ObjectKey(routineItem[index]),
                                        trailingActions: [
                                          SwipeAction(
                                            title: '삭제',
                                            style: TextStyle(fontFamily: 'NotoSansKR', fontWeight: FontWeight.normal, fontSize: 18, color: Colors.white),
                                            onTap: (handler) async {
                                              await handler(false);
                                              await _deletePlanner(routineItem[index].routineId);
                                              routineItem.removeAt(index);
                                            },
                                            color: Colors.red,
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
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    margin: EdgeInsets.only(left: 20),
                                                    child: Text(
                                                      routineItem[index].title,
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
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 40,
                  )
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
                                                      onPressed: () {},
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
                                                      showCupertinoModalBottomSheet(context: context, builder: (context) => WritePlannerWidget());
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
                                                            title: '성공',
                                                            style: TextStyle(fontFamily: 'NotoSansKR', fontWeight: FontWeight.normal, fontSize: 18, color: Colors.blue),
                                                            onTap: (handler) async {
                                                              await handler(false);
                                                              _showTaost('축하합니다! 할일을 성공하셨습니다!');
                                                            },
                                                            color: Color(0xffF4F4F4),
                                                            backgroundRadius: 10,
                                                          ),
                                                          SwipeAction(
                                                            title: '실패',
                                                            style: TextStyle(fontFamily: 'NotoSansKR', fontWeight: FontWeight.normal, fontSize: 18, color: Colors.red),
                                                            onTap: (handler) async {
                                                              await handler(false);
                                                              _showTaost('이 할일을 실패하셨습니다..ㅠㅠ');
                                                            },
                                                            color: Color(0xffF4F4F4),
                                                            backgroundRadius: 10,
                                                          ),
                                                          SwipeAction(
                                                            title: '미루기',
                                                            style: TextStyle(fontFamily: 'NotoSansKR', fontWeight: FontWeight.normal, fontSize: 18, color: Color(0xff9B9B9B)),
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
                                                        trailingActions: [
                                                          SwipeAction(
                                                            title: '성공',
                                                            style: TextStyle(fontFamily: 'NotoSansKR', fontWeight: FontWeight.normal, fontSize: 18, color: Colors.blue),
                                                            onTap: (handler) async {
                                                              await handler(false);
                                                              _showTaost('축하합니다! 할일을 성공하셨습니다!');
                                                            },
                                                            color: Color(0xffF4F4F4),
                                                            backgroundRadius: 10,
                                                          ),
                                                          SwipeAction(
                                                            title: '실패',
                                                            style: TextStyle(fontFamily: 'NotoSansKR', fontWeight: FontWeight.normal, fontSize: 18, color: Colors.red),
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
