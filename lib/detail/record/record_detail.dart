import 'dart:io';

import 'package:bottom_picker/bottom_picker.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_swipe_action_cell/core/cell.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:imagebutton/imagebutton.dart';
import 'package:intl/intl.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:online_planner_app/detail/login/login_detail.dart';
import 'package:online_planner_app/detail/planner/ReadPlanner.dart';
import 'package:online_planner_app/detail/user_info/user_info_detail.dart';
import 'package:online_planner_app/login/login_page.dart';
import 'package:online_planner_app/main/main_page.dart';
import 'package:online_planner_app/main/notice_page.dart';
import 'package:outline_search_bar/outline_search_bar.dart';
import 'package:page_transition/page_transition.dart';
import 'package:progress_indicators/progress_indicators.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../SideMenuWidget.dart';
import 'ReadGoalWidget.dart';
import 'ReadMemo.dart';
import 'WriteGoalWidget.dart';
import 'WriteMemo.dart';

class RecordPage extends StatefulWidget {
  String tier = "", date = "";

  RecordPage(this.tier, this.date);

  _RecordState createState() => _RecordState(tier, date);
}

class _RecordState extends State<RecordPage> {
  String initTier = "", date = "";

  _RecordState(this.initTier, this.date);
  late Memos memos;

  String nickName = "",
      tier = "";
  int exp = -1,
      maxExp = -1,
      userLevel = -1;

  late SearchPlanner searchPlanner;
  late SearchRoutine searchRoutine;

  List<Planner> plannerItem = [];
  late Future<List<Planner>> fPlannerItem;

  String imageName = "";

  String pageName = "기록",
      title = "";

  bool successFailed = false, isSetImage = false;

  int _fragType = 0;

  Color bellColor = Color(0xff585858);
  Color searchColor = Color(0xff585858);

  bool _isBell = false;
  bool _isSearch = false;

  bool _isMemo = true, _isGoal = false;

  late UserInfo userInfo;
  late Goals goals;

  Color memoColor = Color(0xff2F5DFB), goalColor = Color(0xff9B9B9B);

  _setMemo() {
    if(_isMemo) {
      setState(() {
        _isGoal = false;
        memoColor = Color(0xff2F5DFB);
        goalColor = Color(0xff9B9B9B);

      });
    }else if(_isGoal) {
      setState(() {
        _isMemo = false;
        goalColor = Color(0xff2F5DFB);
        memoColor = Color(0xff9B9B9B);
      });
    }
  }

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
          pageName = '기록';
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
          pageName = '기록';
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

  Future<Goals> _getGoal() async {
    _preferences = await SharedPreferences.getInstance();
    try {
      Dio dio = Dio();
      final response = await dio.get(
          url + '/goal',
          options: Options(
              headers: {
                HttpHeaders.authorizationHeader: _preferences.getString('accessToken') ?? ""
              }
          ),
          queryParameters: {
            'date' : date
          }
      );

      if(response.statusCode == 200) {
        goals = Goals.fromJson(response.data);

        goals.weekGoals.add(
            Goal(
                goalId: goals.weekGoals.length,
                goal: '선택하여 목표 작성',
                goalType: 'TODAY',
                goalDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                isAchieve: true
            )
        );

        goals.monthGoals.add(
            Goal(
                goalId: goals.monthGoals.length,
                goal: '선택하여 목표 작성',
                goalType: 'WEEK',
                goalDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                isAchieve: true
            )
        );

        goals.yearGoals.add(
            Goal(
                goalId: goals.yearGoals.length,
                goal: '선택하여 목표 작성',
                goalType: 'YEAR',
                goalDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                isAchieve: true
            )
        );

        return goals;
      }

      return goals;
    }catch(e) {
      await _retryGetGoal();

      return goals;
    }
  }

  _retryGetGoal() async {
    await _refreshToken();
    _preferences = await SharedPreferences.getInstance();
    try {
      Dio dio = Dio();
      final response = await dio.get(
          url + '/goal',
          options: Options(
              headers: {
                HttpHeaders.authorizationHeader: _preferences.getString('accessToken') ?? ""
              }
          ),
          queryParameters: {
            'date' : date
          }
      );

      if(response.statusCode == 200) {
        goals = Goals.fromJson(response.data);

        goals.weekGoals.add(
            Goal(
                goalId: goals.weekGoals.length,
                goal: '선택하여 목표 작성',
                goalType: 'TODAY',
                goalDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                isAchieve: true
            )
        );

        goals.monthGoals.add(
            Goal(
                goalId: goals.monthGoals.length,
                goal: '선택하여 목표 작성',
                goalType: 'WEEK',
                goalDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                isAchieve: true
            )
        );

        goals.yearGoals.add(
            Goal(
                goalId: goals.yearGoals.length,
                goal: '선택하여 목표 작성',
                goalType: 'YEAR',
                goalDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                isAchieve: true
            )
        );

        return goals;
      }

      return goals;
    }catch(e) {
      await _logout();
    }
  }

  _deleteGoal(int goalId) async {
    _preferences = await SharedPreferences.getInstance();
    try {
      Dio dio = Dio();
      final response = await dio.delete(
        url + '/goal/' + goalId.toString(),
        options: Options(
            headers: {
              HttpHeaders.authorizationHeader: _preferences.getString('accessToken') ?? ""
            }
        ),
      );

      if(response.statusCode == 200) {
        _showTaost('삭제성공하셨습니다.');
      }
    }catch(e) {
      await _retryDeleteGoal(goalId);
    }
  }

  _retryDeleteGoal(int goalId) async {
    _preferences = await SharedPreferences.getInstance();
    try {
      Dio dio = Dio();
      final response = await dio.delete(
        url + '/goal/' + goalId.toString(),
        options: Options(
            headers: {
              HttpHeaders.authorizationHeader: _preferences.getString('accessToken') ?? ""
            }
        ),
      );

      if(response.statusCode == 200) {
        _showTaost('삭제하셨습니다.');
      }
    }catch(e) {
      await _logout();
    }
  }

  _achieveGoal(int goalId) async {
    _preferences = await SharedPreferences.getInstance();
    try {
      Dio dio = Dio();
      final response = await dio.put(
          url + '/goal/achieve/' + goalId.toString(),
          options: Options(
              headers: {
                HttpHeaders.authorizationHeader: _preferences.getString('accessToken') ?? ""
              }
          )
      );

      if(response.statusCode == 200) {
        _showTaost('달성하셨습니다.');
      }
    }catch(e) {
      await _retryAchieveGoal(goalId);
    }
  }

  _retryAchieveGoal(int goalId) async {
    await _refreshToken();
    _preferences = await SharedPreferences.getInstance();
    try {
      Dio dio = Dio();
      final response = await dio.put(
          url + '/goal/achieve/' + goalId.toString(),
          options: Options(
              headers: {
                HttpHeaders.authorizationHeader: _preferences.getString('accessToken') ?? ""
              }
          )
      );

      if(response.statusCode == 200) {
        _showTaost('달성하셨습니다.');
      }
    }catch(e) {
      await _logout();
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

  _showTaost(String message) {
    return Fluttertoast.showToast(
        msg: message,
        textColor: Colors.black,
        backgroundColor: Colors.grey,
        gravity: ToastGravity.BOTTOM,
        fontSize: 15
    );
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

  _deleteMemo(int memoId) async {
    _preferences = await SharedPreferences.getInstance();
    try {
      Dio dio = Dio();
      final response = await dio.delete(
          url + '/memo/' + memoId.toString(),
          options: Options(
              headers: {
                HttpHeaders.authorizationHeader: _preferences.getString('accessToken') ?? ""
              }
          )
      );

      if(response.statusCode == 200) {
        _showTaost('삭제되었습니다.');
      }
    }catch(e) {
      await _retryDeleteMemo(memoId);
    }
  }

  _retryDeleteMemo(int memoId) async {
    _preferences = await SharedPreferences.getInstance();
    await _refreshToken();
    try {
      Dio dio = Dio();
      final response = await dio.delete(
          url + '/memo/' + memoId.toString(),
          options: Options(
              headers: {
                HttpHeaders.authorizationHeader: _preferences.getString('accessToken') ?? ""
              }
          )
      );

      if(response.statusCode == 200) {
        _showTaost('삭제되었습니다.');
      }
    }catch(e) {
      await _logout();
    }
  }

  Future<Memos> _getMemos() async {
    _preferences = await SharedPreferences.getInstance();
    try {
      Dio dio = Dio();
      final response = await dio.get(
          url + '/memo',
          options: Options(
              headers: {
                HttpHeaders.authorizationHeader: _preferences.getString('accessToken')
              }
          ),
          queryParameters: {
            'date' : date
          }
      );

      if(response.statusCode == 200) {
        memos = Memos.fromJson(response.data);

        memos.todayMemo.add(
            Memo(
                memoId: memos.todayMemo.length,
                content: '선택하여 메모 작성',
                memoType: 'TODAY',
                memoAt: DateFormat('yyyy-MM-dd').format(DateTime.now())
            )
        );

        memos.weekMemo.add(
            Memo(
                memoId: memos.weekMemo.length,
                content: '선택하여 메모 작성',
                memoType: 'WEEK',
                memoAt: DateFormat('yyyy-MM-dd').format(DateTime.now())
            )
        );

        memos.monthMemo.add(
            Memo(
                memoId: memos.monthMemo.length,
                content: '선택하여 메모 작성',
                memoType: 'MONTH',
                memoAt: DateFormat('yyyy-MM-dd').format(DateTime.now())
            )
        );
      }
      return memos;
    }catch(e) {
      await _retryGetMemos();

      return memos;
    }
  }

  _retryGetMemos() async {
    await _refreshToken();
    _preferences = await SharedPreferences.getInstance();
    try {
      Dio dio = Dio();
      final response = await dio.get(
          url + '/memo',
          options: Options(
              headers: {
                HttpHeaders.authorizationHeader: _preferences.getString('accessToken')
              }
          ),
          queryParameters: {
            'date' : date
          }
      );

      if(response.statusCode == 200) {
        memos = Memos.fromJson(response.data);

        memos.todayMemo.add(
            Memo(
                memoId: memos.todayMemo.length,
                content: '선택하여 메모 작성',
                memoType: 'TODAY',
                memoAt: DateFormat('yyyy-MM-dd').format(DateTime.now())
            )
        );

        memos.weekMemo.add(
            Memo(
                memoId: memos.weekMemo.length,
                content: '선택하여 메모 작성',
                memoType: 'WEEK',
                memoAt: DateFormat('yyyy-MM-dd').format(DateTime.now())
            )
        );

        memos.monthMemo.add(
            Memo(
                memoId: memos.monthMemo.length,
                content: '선택하여 메모 작성',
                memoType: 'MONTH',
                memoAt: DateFormat('yyyy-MM-dd').format(DateTime.now())
            )
        );
      }
    }catch(e) {
      await _logout();
    }
  }

  Future<bool> _refreshToken() async {
    Dio dio = Dio();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    try {
      final response = await dio.put(
          url + '/auth',
          options: Options(
              headers: {
                HttpHeaders.contentTypeHeader: 'application/json',
                'X-Refresh-Token': sharedPreferences.getString('refreshToken')
              }
          )
      );

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
    if(initTier.isNotEmpty) {
      _setUserImage();
      isSetImage = true;
    }
  }

  @override
  void initState() {
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
        physics: NeverScrollableScrollPhysics(),
        controller: _mainPageController,
        children: [
          Container(
            child: ListView(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                            margin: EdgeInsets.only(top: 10, left: _width * 0.061),
                            width: 162,
                            child: TextButton(
                              onPressed: () {
                                BottomPicker.date(
                                  title: '날짜를 선택해주세요!',
                                  titleStyle: TextStyle(
                                      fontFamily: 'NotoSansKR',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 20,
                                      color: Color(0xff2C2C2C)
                                  ),
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
                                style: TextStyle(
                                    fontFamily: 'NotoSansKR',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 28,
                                    color: Color(0xff2C2C2C)
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            margin: EdgeInsets.only(top: 15),
                            width: 50,
                            child: TextButton(
                              onPressed: () {
                                _isMemo = true;
                                _isGoal = false;
                                _setMemo();
                              },
                              child: Text(
                                '메모',
                                style: TextStyle(
                                    fontFamily: 'NotoSansKR',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 18,
                                    color: memoColor
                                ),
                              ),
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.only(top: 15, right: _width * 0.061),
                            width: 50,
                            child: TextButton(
                              onPressed: () {
                                _isGoal = true;
                                _isMemo = false;
                                _setMemo();
                              },
                              child: Text(
                                '목표',
                                style: TextStyle(
                                    fontFamily: 'NotoSansKR',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 18,
                                    color: goalColor
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ),
                Visibility(
                  visible: _isMemo,
                  child: Container(
                    margin: EdgeInsets.only(top: 20),
                    child: FutureBuilder<Memos>(
                      future: _getMemos(),
                      builder: (context, snapshot) {
                        if(snapshot.hasData == false) {
                          return Center(
                            child: FadingText(
                              'Loading..',
                              style: TextStyle(
                                  fontFamily: 'NotoSansKR',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16
                              ),
                            ),
                          );
                        }else if(snapshot.hasError) {
                          return _logout();
                        }else {
                          return Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: EdgeInsets.only(bottom: 20, left: _width * 0.061),
                                    child: Text(
                                      '오늘 메모',
                                      style: TextStyle(
                                          fontFamily: 'NotoSansKR',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 28,
                                          color: Color(0xff2C2C2C)
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              ListView.builder(
                                  physics: NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  itemCount: memos.todayMemo.isEmpty? 1 : memos.todayMemo.length,
                                  itemBuilder: (context, index) {
                                    if(memos.todayMemo.isEmpty) {
                                      return Center(
                                        child: Container(
                                          child: RaisedButton(
                                            onPressed: () {
                                              showCupertinoModalBottomSheet(
                                                  context: this.context,
                                                  builder: (context) => WriteMemoWidget()
                                              );
                                            },
                                            shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius
                                                    .circular(10)
                                            ),
                                            child: Text(
                                              '선택해서 메모 작성',
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
                                          height: 60,
                                        ),
                                      );
                                    }else {
                                      String title = memos.todayMemo[index]
                                          .content.length > 10
                                          ? memos.todayMemo[index]
                                          .content.substring(0, 10) + '... 더보기'
                                          : memos.todayMemo[index].content;

                                      print(memos.todayMemo[index].memoAt);

                                      if (memos.todayMemo[index].content == '선택하여 메모 작성') {
                                        return Center(
                                          child: Container(
                                            child: RaisedButton(
                                              onPressed: () {
                                                showCupertinoModalBottomSheet(
                                                    context: this.context,
                                                    builder: (context) => WriteMemoWidget()
                                                );
                                              },
                                              shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius
                                                      .circular(10)
                                              ),
                                              child: Text(
                                                '선택해서 메모 작성',
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
                                            height: 60,
                                          ),
                                        );
                                      } else {
                                        return Center(
                                          child: Container(
                                            width: _width * 0.87,
                                            height: 60,
                                            margin: EdgeInsets.only(bottom: 10),
                                            child: SwipeActionCell(
                                              key: ObjectKey(
                                                  memos.todayMemo[index]),
                                              performsFirstActionWithFullSwipe: true,
                                              trailingActions: <SwipeAction>[
                                                SwipeAction(
                                                  title: "삭제",
                                                  onTap: (handler) async {
                                                    handler(false);
                                                    await _deleteMemo(memos.todayMemo[index].memoId);
                                                    memos.todayMemo.removeAt(index);
                                                  },
                                                  color: Colors.red,
                                                  style: TextStyle(
                                                      fontFamily: 'NotoSansKR',
                                                      fontWeight: FontWeight
                                                          .normal,
                                                      fontSize: 16,
                                                      color: Colors.white
                                                  ),
                                                  backgroundRadius: 10,
                                                  widthSpace: 65,
                                                ),
                                              ],
                                              child: RaisedButton(
                                                elevation: 0,
                                                onPressed: () {
                                                  Navigator.push(
                                                      context,
                                                      PageTransition(
                                                          child: ReadMemoWidget(
                                                              memos.todayMemo[index].memoId,
                                                              memos.todayMemo[index].content,
                                                              memos.todayMemo[index].memoAt,
                                                              memos.todayMemo[index].memoType
                                                          ),
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
                                                          margin: EdgeInsets
                                                              .only(left: 5),
                                                          child: Text(
                                                            title,
                                                            style: TextStyle(
                                                                fontFamily: 'NotoSansKR',
                                                                fontWeight: FontWeight
                                                                    .normal,
                                                                fontSize: 16,
                                                                color: Color(
                                                                    0xff9B9B9B)
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment
                                                          .end,
                                                      children: [
                                                        Container(
                                                          margin: EdgeInsets
                                                              .only(right: 5),
                                                          child: Text(
                                                            memos
                                                                .todayMemo[index]
                                                                .memoAt,
                                                            style: TextStyle(
                                                                fontFamily: 'NotoSansKR',
                                                                fontWeight: FontWeight
                                                                    .normal,
                                                                fontSize: 12,
                                                                color: Color(
                                                                    0xff9B9B9B)
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    )
                                                  ],
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius
                                                      .circular(10),
                                                ),
                                                color: Color(0xffF4F4F4),
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  }
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: EdgeInsets.only(bottom: 20, top: 10, left: _width * 0.061),
                                    child: Text(
                                      '이번주 메모',
                                      style: TextStyle(
                                          fontFamily: 'NotoSansKR',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 28,
                                          color: Color(0xff2C2C2C)
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              ListView.builder(
                                  physics: NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  itemCount: memos.weekMemo.isEmpty? 1 : memos.weekMemo.length,
                                  itemBuilder: (context, index) {
                                    if(memos.weekMemo.isEmpty) {
                                      return Center(
                                        child: Container(
                                          child: RaisedButton(
                                            onPressed: () {
                                              showCupertinoModalBottomSheet(
                                                  context: this.context,
                                                  builder: (context) => WriteMemoWidget()
                                              );
                                            },
                                            shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius
                                                    .circular(10)
                                            ),
                                            child: Text(
                                              '선택해서 메모 작성',
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
                                          height: 60,
                                        ),
                                      );
                                    }else {
                                      String title = memos.weekMemo[index].content.length > 10 ? memos.weekMemo[index].content.substring(0, 10) + '... 더보기' : memos.weekMemo[index].content;

                                      if(memos.weekMemo[index].content == '선택하여 메모 작성') {
                                        return Center(
                                          child: Container(
                                            child: RaisedButton(
                                              onPressed: () {
                                                showCupertinoModalBottomSheet(
                                                    context: this.context,
                                                    builder: (context) => WriteMemoWidget()
                                                );
                                              },
                                              shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius
                                                      .circular(10)
                                              ),
                                              child: Text(
                                                '선택해서 메모 작성',
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
                                            height: 60,
                                          ),
                                        );
                                      }else {
                                        return Center(
                                          child: Container(
                                            width: _width * 0.87,
                                            height: 60,
                                            margin: EdgeInsets.only(bottom: 10),
                                            child: SwipeActionCell(
                                              key: ObjectKey(
                                                  memos.weekMemo[index]),
                                              performsFirstActionWithFullSwipe: true,
                                              trailingActions: <SwipeAction>[
                                                SwipeAction(
                                                  title: "삭제",
                                                  onTap: (handler) async {
                                                    handler(false);
                                                    await _deleteMemo(memos.weekMemo[index].memoId);
                                                    memos.weekMemo.removeAt(index);
                                                  },
                                                  color: Colors.red,
                                                  style: TextStyle(
                                                      fontFamily: 'NotoSansKR',
                                                      fontWeight: FontWeight
                                                          .normal,
                                                      fontSize: 16,
                                                      color: Colors.white
                                                  ),
                                                  backgroundRadius: 10,
                                                  widthSpace: 65,
                                                ),
                                              ],
                                              child: RaisedButton(
                                                elevation: 0,
                                                onPressed: () {
                                                  Navigator.push(
                                                      context,
                                                      PageTransition(
                                                          child: ReadMemoWidget(
                                                              memos.weekMemo[index].memoId,
                                                              memos.weekMemo[index].content,
                                                              memos.weekMemo[index].memoAt,
                                                              memos.weekMemo[index].memoType
                                                          ),
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
                                                          margin: EdgeInsets
                                                              .only(left: 5),
                                                          child: Text(
                                                            title,
                                                            style: TextStyle(
                                                                fontFamily: 'NotoSansKR',
                                                                fontWeight: FontWeight
                                                                    .normal,
                                                                fontSize: 16,
                                                                color: Color(
                                                                    0xff9B9B9B)
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment
                                                          .end,
                                                      children: [
                                                        Container(
                                                          margin: EdgeInsets
                                                              .only(right: 5),
                                                          child: Text(
                                                            memos
                                                                .weekMemo[index]
                                                                .memoAt,
                                                            style: TextStyle(
                                                                fontFamily: 'NotoSansKR',
                                                                fontWeight: FontWeight
                                                                    .normal,
                                                                fontSize: 12,
                                                                color: Color(
                                                                    0xff9B9B9B)
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    )
                                                  ],
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius
                                                      .circular(10),
                                                ),
                                                color: Color(0xffF4F4F4),
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  }
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: EdgeInsets.only(bottom: 20, top: 10, left: _width * 0.061),
                                    child: Text(
                                      '이번달 메모',
                                      style: TextStyle(
                                          fontFamily: 'NotoSansKR',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 28,
                                          color: Color(0xff2C2C2C)
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              ListView.builder(
                                  physics: NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  itemCount: memos.monthMemo.isEmpty? 1 : memos.monthMemo.length,
                                  itemBuilder: (context, index) {
                                    if(memos.monthMemo.isEmpty) {
                                      return Center(
                                        child: Container(
                                          child: RaisedButton(
                                            onPressed: () {
                                              showCupertinoModalBottomSheet(
                                                  context: this.context,
                                                  builder: (context) => WriteMemoWidget()
                                              );
                                            },
                                            shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius
                                                    .circular(10)
                                            ),
                                            child: Text(
                                              '선택해서 메모 작성',
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
                                          height: 60,
                                        ),
                                      );
                                    }else {
                                      String title = memos.monthMemo[index].content.length > 10 ? memos.monthMemo[index].content.substring(0, 10) + '... 더보기' : memos.monthMemo[index].content;

                                      if(memos.monthMemo[index].content == '선택하여 메모 작성') {
                                        return Center(
                                          child: Container(
                                            child: RaisedButton(
                                              onPressed: () {
                                                showCupertinoModalBottomSheet(
                                                    context: this.context,
                                                    builder: (context) => WriteMemoWidget()
                                                );
                                              },
                                              shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius
                                                      .circular(10)
                                              ),
                                              child: Text(
                                                '선택해서 메모 작성',
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
                                            height: 60,
                                          ),
                                        );
                                      }else {
                                        return Center(
                                          child: Container(
                                            width: _width * 0.87,
                                            height: 60,
                                            margin: EdgeInsets.only(bottom: 10),
                                            child: SwipeActionCell(
                                              key: ObjectKey(memos.monthMemo[index]),
                                              performsFirstActionWithFullSwipe: true,
                                              trailingActions: <SwipeAction>[
                                                SwipeAction(
                                                  title: "삭제",
                                                  onTap: (handler) async {
                                                    handler(false);
                                                    await _deleteMemo(memos.monthMemo[index].memoId);
                                                    memos.monthMemo.removeAt(index);
                                                  },
                                                  color: Colors.red,
                                                  style: TextStyle(
                                                      fontFamily: 'NotoSansKR',
                                                      fontWeight: FontWeight
                                                          .normal,
                                                      fontSize: 16,
                                                      color: Colors.white
                                                  ),
                                                  backgroundRadius: 10,
                                                  widthSpace: 65,
                                                ),
                                              ],
                                              child: RaisedButton(
                                                elevation: 0,
                                                onPressed: () {
                                                  Navigator.push(
                                                      context,
                                                      PageTransition(
                                                          child: ReadMemoWidget(
                                                              memos.monthMemo[index].memoId,
                                                              memos.monthMemo[index].content,
                                                              memos.monthMemo[index].memoAt,
                                                              memos.monthMemo[index].memoType
                                                          ),
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
                                                          margin: EdgeInsets
                                                              .only(left: 5),
                                                          child: Text(
                                                            title,
                                                            style: TextStyle(
                                                                fontFamily: 'NotoSansKR',
                                                                fontWeight: FontWeight
                                                                    .normal,
                                                                fontSize: 16,
                                                                color: Color(
                                                                    0xff9B9B9B)
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment
                                                          .end,
                                                      children: [
                                                        Container(
                                                          margin: EdgeInsets
                                                              .only(right: 5),
                                                          child: Text(
                                                            memos.monthMemo[index].memoAt,
                                                            style: TextStyle(
                                                                fontFamily: 'NotoSansKR',
                                                                fontWeight: FontWeight
                                                                    .normal,
                                                                fontSize: 12,
                                                                color: Color(
                                                                    0xff9B9B9B)
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    )
                                                  ],
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius
                                                      .circular(10),
                                                ),
                                                color: Color(0xffF4F4F4),
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  }
                              ),
                              SizedBox(
                                height: 40,
                              )
                            ],
                          );
                        }
                      },
                    ),
                  )
                ),
                Visibility(
                  visible: _isGoal,
                  child: Container(
                    margin: EdgeInsets.only(top: 20),
                    child: FutureBuilder<Goals>(
                      future: _getGoal(),
                      builder: (context, snapshot) {
                        if(snapshot.hasData == false) {
                          return Center(
                            child: FadingText(
                              'Loading..',
                              style: TextStyle(
                                  fontFamily: 'NotoSansKR',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16
                              ),
                            ),
                          );
                        }else if(snapshot.hasError) {
                          return _logout();
                        }else {
                          return Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: EdgeInsets.only(bottom: 20, top: 10, left: _width * 0.061),
                                    child: Text(
                                      '이번주 목표',
                                      style: TextStyle(
                                          fontFamily: 'NotoSansKR',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 28,
                                          color: Color(0xff2C2C2C)
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              ListView.builder(
                                  physics: NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  itemCount: goals.weekGoals.isEmpty? 1 : goals.weekGoals.length,
                                  itemBuilder: (context, index) {
                                    if(goals.weekGoals.isEmpty) {
                                      return Center(
                                        child: Container(
                                          child: RaisedButton(
                                            onPressed: () {
                                              showCupertinoModalBottomSheet(
                                                  context: context,
                                                  builder: (context) => WriteGoalWidget()
                                              );
                                            },
                                            shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius
                                                    .circular(10)
                                            ),
                                            child: Text(
                                              '선택해서 목표 작성',
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
                                          height: 60,
                                        ),
                                      );
                                    }else {
                                      String title = goals.weekGoals[index]
                                          .goal.length > 10
                                          ? goals.weekGoals[index]
                                          .goal.substring(0, 10) + '... 더보기'
                                          : goals.weekGoals[index].goal;

                                      print(goals.weekGoals[index].goalDate);

                                      String achieve = goals.weekGoals[index].isAchieve ? '달성함' : '미달성';
                                      String detail = goals.weekGoals[index].goalDate + ' | ' + achieve;

                                      if (goals.weekGoals[index].goal == '선택하여 목표 작성') {
                                        return Center(
                                          child: Container(
                                            child: RaisedButton(
                                              onPressed: () {
                                                showCupertinoModalBottomSheet(
                                                    context: context,
                                                    builder: (context) => WriteGoalWidget()
                                                );
                                              },
                                              shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius
                                                      .circular(10)
                                              ),
                                              child: Text(
                                                '선택해서 목표 작성',
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
                                            height: 60,
                                          ),
                                        );
                                      } else {
                                        return Center(
                                          child: Container(
                                            width: _width * 0.87,
                                            height: 60,
                                            margin: EdgeInsets.only(bottom: 10),
                                            child: SwipeActionCell(
                                              key: ObjectKey(
                                                  goals.weekGoals[index]),
                                              performsFirstActionWithFullSwipe: true,
                                              trailingActions: <SwipeAction>[
                                                SwipeAction(
                                                  title: '달성',
                                                  onTap: (handler) async {
                                                    handler(false);
                                                    if(!goals.weekGoals[index].isAchieve) {
                                                      await _achieveGoal(goals.weekGoals[index].goalId);
                                                    }else {
                                                      _showTaost('이미 달성되었습니다.');
                                                    }
                                                  },
                                                  color: Color(0xffF4F4F4),
                                                  style: TextStyle(
                                                      fontFamily: 'NotoSansKR',
                                                      fontWeight: FontWeight.normal,
                                                      fontSize: 16,
                                                      color: Colors.blueAccent
                                                  ),
                                                  backgroundRadius: 10,
                                                  widthSpace: 65,
                                                ),
                                                SwipeAction(
                                                  title: "삭제",
                                                  onTap: (handler) async {
                                                    handler(true);
                                                    await _deleteGoal(goals.weekGoals[index].goalId);
                                                    goals.weekGoals.removeAt(index);
                                                  },
                                                  color: Color(0xffF4F4F4),
                                                  style: TextStyle(
                                                      fontFamily: 'NotoSansKR',
                                                      fontWeight: FontWeight
                                                          .normal,
                                                      fontSize: 16,
                                                      color: Colors.red
                                                  ),
                                                  backgroundRadius: 10,
                                                  widthSpace: 65,
                                                ),
                                              ],
                                              child: RaisedButton(
                                                elevation: 0,
                                                onPressed: () {
                                                  Navigator.push(
                                                      context,
                                                      PageTransition(
                                                          child: ReadGoalWidget(
                                                              goals.weekGoals[index].goalId,
                                                              goals.weekGoals[index].goal,
                                                              goals.weekGoals[index].goalType,
                                                              goals.weekGoals[index].goalDate,
                                                              goals.weekGoals[index].isAchieve
                                                          ),
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
                                                          margin: EdgeInsets
                                                              .only(left: 5),
                                                          child: Text(
                                                            title,
                                                            style: TextStyle(
                                                                fontFamily: 'NotoSansKR',
                                                                fontWeight: FontWeight
                                                                    .normal,
                                                                fontSize: 16,
                                                                color: Color(
                                                                    0xff9B9B9B)
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment
                                                          .end,
                                                      children: [
                                                        Container(
                                                          margin: EdgeInsets
                                                              .only(right: 5),
                                                          child: Text(
                                                            detail,
                                                            style: TextStyle(
                                                                fontFamily: 'NotoSansKR',
                                                                fontWeight: FontWeight
                                                                    .normal,
                                                                fontSize: 12,
                                                                color: Color(
                                                                    0xff9B9B9B)
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    )
                                                  ],
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius
                                                      .circular(10),
                                                ),
                                                color: Color(0xffF4F4F4),
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  }
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: EdgeInsets.only(bottom: 20, top: 10, left: _width * 0.061),
                                    child: Text(
                                      '이번달 목표',
                                      style: TextStyle(
                                          fontFamily: 'NotoSansKR',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 28,
                                          color: Color(0xff2C2C2C)
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              ListView.builder(
                                  physics: NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  itemCount: goals.monthGoals.isEmpty? 1 : goals.monthGoals.length,
                                  itemBuilder: (context, index) {
                                    if(goals.monthGoals.isEmpty) {
                                      return Center(
                                        child: Container(
                                          child: RaisedButton(
                                            onPressed: () {
                                              showCupertinoModalBottomSheet(
                                                  context: context,
                                                  builder: (context) => WriteGoalWidget()
                                              );
                                            },
                                            shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius
                                                    .circular(10)
                                            ),
                                            child: Text(
                                              '선택해서 목표 작성',
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
                                          height: 60,
                                        ),
                                      );
                                    }else {
                                      String title = goals.monthGoals[index]
                                          .goal.length > 10
                                          ? goals.monthGoals[index]
                                          .goal.substring(0, 10) + '... 더보기'
                                          : goals.monthGoals[index].goal;

                                      print(goals.monthGoals[index].goalDate);

                                      String achieve = goals.monthGoals[index].isAchieve ? '달성함' : '미달성';
                                      String detail = goals.monthGoals[index].goalDate + ' | ' + achieve;

                                      if (goals.monthGoals[index].goal == '선택하여 목표 작성') {
                                        return Center(
                                          child: Container(
                                            child: RaisedButton(
                                              onPressed: () {
                                                showCupertinoModalBottomSheet(
                                                    context: context,
                                                    builder: (context) => WriteGoalWidget()
                                                );
                                              },
                                              shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius
                                                      .circular(10)
                                              ),
                                              child: Text(
                                                '선택해서 목표 작성',
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
                                            height: 60,
                                          ),
                                        );
                                      } else {
                                        return Center(
                                          child: Container(
                                            width: _width * 0.87,
                                            height: 60,
                                            margin: EdgeInsets.only(bottom: 10),
                                            child: SwipeActionCell(
                                              key: ObjectKey(
                                                  goals.monthGoals[index]),
                                              performsFirstActionWithFullSwipe: true,
                                              trailingActions: <SwipeAction>[
                                                SwipeAction(
                                                  title: '달성',
                                                  onTap: (handler) async {
                                                    handler(false);
                                                    if(!goals.monthGoals[index].isAchieve) {
                                                      await _achieveGoal(goals.monthGoals[index].goalId);
                                                    }else {
                                                      _showTaost('이미 달성하였습니다.');
                                                    }
                                                  },
                                                  color: Color(0xffF4F4F4),
                                                  style: TextStyle(
                                                      fontFamily: 'NotoSansKR',
                                                      fontWeight: FontWeight.normal,
                                                      fontSize: 16,
                                                      color: Colors.blueAccent
                                                  ),
                                                  backgroundRadius: 10,
                                                  widthSpace: 65,
                                                ),
                                                SwipeAction(
                                                  title: "삭제",
                                                  onTap: (handler) async {
                                                    handler(true);
                                                    await _deleteGoal(goals.monthGoals[index].goalId);
                                                    goals.monthGoals.removeAt(index);
                                                  },
                                                  color: Color(0xffF4F4F4),
                                                  style: TextStyle(
                                                      fontFamily: 'NotoSansKR',
                                                      fontWeight: FontWeight
                                                          .normal,
                                                      fontSize: 16,
                                                      color: Colors.red
                                                  ),
                                                  backgroundRadius: 10,
                                                  widthSpace: 65,
                                                ),
                                              ],
                                              child: RaisedButton(
                                                elevation: 0,
                                                onPressed: () {
                                                  Navigator.push(
                                                      context,
                                                      PageTransition(
                                                          child: ReadGoalWidget(
                                                              goals.monthGoals[index].goalId,
                                                              goals.monthGoals[index].goal,
                                                              goals.monthGoals[index].goalType,
                                                              goals.monthGoals[index].goalDate,
                                                              goals.monthGoals[index].isAchieve
                                                          ),
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
                                                          margin: EdgeInsets
                                                              .only(left: 5),
                                                          child: Text(
                                                            title,
                                                            style: TextStyle(
                                                                fontFamily: 'NotoSansKR',
                                                                fontWeight: FontWeight
                                                                    .normal,
                                                                fontSize: 16,
                                                                color: Color(
                                                                    0xff9B9B9B)
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment
                                                          .end,
                                                      children: [
                                                        Container(
                                                          margin: EdgeInsets
                                                              .only(right: 5),
                                                          child: Text(
                                                            detail,
                                                            style: TextStyle(
                                                                fontFamily: 'NotoSansKR',
                                                                fontWeight: FontWeight
                                                                    .normal,
                                                                fontSize: 12,
                                                                color: Color(
                                                                    0xff9B9B9B)
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    )
                                                  ],
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius
                                                      .circular(10),
                                                ),
                                                color: Color(0xffF4F4F4),
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  }
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: EdgeInsets.only(bottom: 20, top: 10, left: _width * 0.061),
                                    child: Text(
                                      date.substring(0, 4) + '년 목표',
                                      style: TextStyle(
                                          fontFamily: 'NotoSansKR',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 28,
                                          color: Color(0xff2C2C2C)
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              ListView.builder(
                                  physics: NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  itemCount: goals.yearGoals.isEmpty? 1 : goals.yearGoals.length,
                                  itemBuilder: (context, index) {
                                    if(goals.yearGoals.isEmpty) {
                                      return Center(
                                        child: Container(
                                          child: RaisedButton(
                                            onPressed: () {
                                              showCupertinoModalBottomSheet(
                                                  context: context,
                                                  builder: (context) => WriteGoalWidget()
                                              );
                                            },
                                            shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius
                                                    .circular(10)
                                            ),
                                            child: Text(
                                              '선택해서 목표 작성',
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
                                          height: 60,
                                        ),
                                      );
                                    }else {
                                      String title = goals.yearGoals[index]
                                          .goal.length > 10
                                          ? goals.yearGoals[index]
                                          .goal.substring(0, 10) + '... 더보기'
                                          : goals.yearGoals[index].goal;

                                      print(goals.yearGoals[index].goalDate);

                                      String achieve = goals.yearGoals[index].isAchieve ? '달성함' : '미달성';
                                      String detail = goals.yearGoals[index].goalDate + ' | ' + achieve;

                                      if (goals.yearGoals[index].goal == '선택하여 목표 작성') {
                                        return Center(
                                          child: Container(
                                            child: RaisedButton(
                                              onPressed: () {
                                                showCupertinoModalBottomSheet(
                                                    context: context,
                                                    builder: (context) => WriteGoalWidget()
                                                );
                                              },
                                              shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius
                                                      .circular(10)
                                              ),
                                              child: Text(
                                                '선택해서 목표 작성',
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
                                            height: 60,
                                          ),
                                        );
                                      } else {
                                        return Center(
                                          child: Container(
                                            width: _width * 0.87,
                                            height: 60,
                                            margin: EdgeInsets.only(bottom: 10),
                                            child: SwipeActionCell(
                                              key: ObjectKey(
                                                  goals.yearGoals[index]),
                                              performsFirstActionWithFullSwipe: true,
                                              trailingActions: <SwipeAction>[
                                                SwipeAction(
                                                  title: '달성',
                                                  onTap: (handler) async {
                                                    handler(false);
                                                    if(!goals.yearGoals[index].isAchieve)
                                                      await _achieveGoal(goals.yearGoals[index].goalId);
                                                    else
                                                      _showTaost('이미 달성하셨습니다');
                                                  },
                                                  color: Color(0xffF4F4F4),
                                                  style: TextStyle(
                                                      fontFamily: 'NotoSansKR',
                                                      fontWeight: FontWeight.normal,
                                                      fontSize: 16,
                                                      color: Colors.blueAccent
                                                  ),
                                                  backgroundRadius: 10,
                                                  widthSpace: 65,
                                                ),
                                                SwipeAction(
                                                  title: "삭제",
                                                  onTap: (handler) async {
                                                    handler(true);
                                                    await _deleteGoal(goals.yearGoals[index].goalId);
                                                    goals.yearGoals.removeAt(index);
                                                  },
                                                  color: Color(0xffF4F4F4),
                                                  style: TextStyle(
                                                      fontFamily: 'NotoSansKR',
                                                      fontWeight: FontWeight
                                                          .normal,
                                                      fontSize: 16,
                                                      color: Colors.red
                                                  ),
                                                  backgroundRadius: 10,
                                                  widthSpace: 65,
                                                ),
                                              ],
                                              child: RaisedButton(
                                                elevation: 0,
                                                onPressed: () {
                                                  Navigator.push(
                                                      context,
                                                      PageTransition(
                                                          child: ReadGoalWidget(
                                                              goals.yearGoals[index].goalId,
                                                              goals.yearGoals[index].goal,
                                                              goals.yearGoals[index].goalType,
                                                              goals.yearGoals[index].goalDate,
                                                              goals.yearGoals[index].isAchieve
                                                          ),
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
                                                          margin: EdgeInsets
                                                              .only(left: 5),
                                                          child: Text(
                                                            title,
                                                            style: TextStyle(
                                                                fontFamily: 'NotoSansKR',
                                                                fontWeight: FontWeight
                                                                    .normal,
                                                                fontSize: 16,
                                                                color: Color(
                                                                    0xff9B9B9B)
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment
                                                          .end,
                                                      children: [
                                                        Container(
                                                          margin: EdgeInsets
                                                              .only(right: 5),
                                                          child: Text(
                                                            detail,
                                                            style: TextStyle(
                                                                fontFamily: 'NotoSansKR',
                                                                fontWeight: FontWeight
                                                                    .normal,
                                                                fontSize: 12,
                                                                color: Color(
                                                                    0xff9B9B9B)
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    )
                                                  ],
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius
                                                      .circular(10),
                                                ),
                                                color: Color(0xffF4F4F4),
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  }
                              ),
                              SizedBox(
                                height: 40,
                              )
                            ],
                          );
                        }
                      },
                    ),
                  )
                )
              ],
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
      ),
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

class Memo {
  String content, memoType, memoAt;
  int memoId;

  Memo({required this.memoId, required this.content, required this.memoType, required this.memoAt});

  factory Memo.fromJson(Map<String, dynamic> json) {
    return Memo(
        memoId: json['memoId'],
        content: json['content'],
        memoType: json['memoType'],
        memoAt: json['memoAt']
    );
  }
}

class Memos {
  List<Memo> todayMemo, weekMemo, monthMemo;

  Memos({required this.todayMemo, required this.weekMemo, required this.monthMemo});

  factory Memos.fromJson(Map<String, dynamic> json) {
    List<Memo> today, week, month;
    today = (json['todayMemo'] as List).map((e) => Memo.fromJson(e)).toList();
    week = (json['weekMemo'] as List).map((e) => Memo.fromJson(e)).toList();
    month = (json['monthMemo'] as List).map((e) => Memo.fromJson(e)).toList();

    return Memos(
        todayMemo: today,
        weekMemo: week,
        monthMemo: month
    );
  }
}
class Goal {
  String goal, goalType, goalDate;
  int goalId;
  bool isAchieve;

  Goal({required this.goalId, required this.goalType, required this.goal, required this.goalDate, required this.isAchieve});

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
        goalId: json['goalId'],
        goal: json['goal'],
        goalDate: json['goalDate'],
        goalType: json['goalType'],
        isAchieve: json['achieve']
    );
  }
}

class Goals {
  List<Goal> weekGoals;
  List<Goal> monthGoals;
  List<Goal> yearGoals;

  Goals({required this.weekGoals, required this.monthGoals, required this.yearGoals});

  factory Goals.fromJson(Map<String, dynamic> json) {
    List<Goal> week = [];
    List<Goal> month = [];
    List<Goal> year = [];

    week = (json['weekGoals'] as List).map((e) => Goal.fromJson(e)).toList();
    month = (json['monthGoals'] as List).map((e) => Goal.fromJson(e)).toList();
    year = (json['yearGoals'] as List).map((e) => Goal.fromJson(e)).toList();

    return Goals(
        weekGoals: week,
        monthGoals: month,
        yearGoals: year
    );
  }
}