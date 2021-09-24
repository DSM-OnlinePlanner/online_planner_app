import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animated_dialog/flutter_animated_dialog.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intervalprogressbar/intervalprogressbar.dart';
import 'package:online_planner_app/detail/achievement/achievement_detail.dart';
import 'package:online_planner_app/detail/login/login_detail.dart';
import 'package:online_planner_app/detail/setting/settings_details.dart';
import 'package:online_planner_app/login/login_page.dart';
import 'package:page_transition/page_transition.dart';
import 'package:progress_indicators/progress_indicators.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../SideMenuWidget.dart';

class UserInfoPage extends StatefulWidget {
  _UserInfoWidget createState() => _UserInfoWidget();
}

class _UserInfoWidget extends State<UserInfoPage> {

  late Token token;
  late UserInfo userInfo;

  String accessToken = "",
      refreshToken = "",
      deviceToken = "",
      tier = "";

  late SharedPreferences _preferences;
  late Future<UserInfo> fUserInfo;

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final String url = 'http://220.90.237.33:7070';

  String imageName = "";

  _showTaost(String message) {
    return Fluttertoast.showToast(
        msg: message,
        textColor: Colors.black,
        backgroundColor: Colors.grey,
        gravity: ToastGravity.BOTTOM,
        fontSize: 15
    );
  }

  Future<bool> _refreshToken() async {
    _preferences = await SharedPreferences.getInstance();
    Dio dio = Dio();
    try {
      final response = await dio.put(
          url + '/auth',
          options: Options(
              headers: {
                HttpHeaders.contentTypeHeader: 'application/json',
                'X-Refresh-Token': _preferences.getString('refreshToken')
              }
          )
      );

      print('refreshToken : ' + response.statusCode.toString());

      if (response.statusCode == 200) {
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

  _logout() async {
    try {
      Dio dio = Dio();
      final response = await dio.delete(
          url + '/user/logout',
          options: Options(
              headers: {
                HttpHeaders.contentTypeHeader: "application/json",
                "deviceToken": await _firebaseMessaging.getToken() ?? ""
              }
          )
      );

      if (response.statusCode == 200) {
        _preferences.remove("isAuth");
        _preferences.remove("accessToken");
        _preferences.remove("refreshToken");
        _preferences.remove("userImage");

        Navigator.pushAndRemoveUntil(
            context,
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

  _getTokens() async {
    _preferences = await SharedPreferences.getInstance();
    accessToken = _preferences.getString("accessToken") ?? "";
    refreshToken = _preferences.getString('refreshToken') ?? "";
    deviceToken = await _firebaseMessaging.getToken() ?? "";
    tier = _preferences.getString('tier') ?? "";


    if (accessToken.isEmpty || refreshToken.isEmpty || deviceToken.isEmpty) {
      _logout();
    } else {
      print("accessToken : " + accessToken);
    }
  }

  Future<UserInfo> _getUserInfo() async {
    _preferences = await SharedPreferences.getInstance();
    try {
      Dio dio = Dio();
      final response = await dio.get(
          url + '/user',
          options: Options(
              headers: {
                HttpHeaders.contentTypeHeader: "application/json",
                HttpHeaders.authorizationHeader: _preferences.getString('accessToken')
              }
          )
      );

      print(response.statusCode);

      if (response.statusCode == 200) {
        userInfo = UserInfo.fromJson(response.data);

        print('user info : ' + userInfo.tier);

        await _preferences.setString('userImage', userInfo.tier);

        if (userInfo.tier == "A4 용지") {
          setState(() {
            imageName = 'assets/images/just_paper.png';
          });
        } else if (userInfo.tier == "무료 플래너") {
          setState(() {
            imageName = 'assets/images/free_paper.png';
          });
        } else if (userInfo.tier == "스프링 노트 플래너") {
          setState(() {
            imageName = 'assets/images/spring_planner.png';
          });
        } else if (userInfo.tier == "플라스틱 커버 플래너") {
          setState(() {
            imageName = 'assets/images/plastic_planner.png';
          });
        } else if (userInfo.tier == "가죽 슬러브 플래너") {
          setState(() {
            imageName = 'assets/images/gaguck_planner.png';
          });
        } else if (userInfo.tier == "고급 가죽 슬러브 플래너") {
          setState(() {
            imageName = 'assets/images/good_gaguck_planner.png';
          });
        } else if (userInfo.tier == "맞춤 재작 플래너") {
          setState(() {
            imageName = 'assets/images/best_planner.png';
          });
        } else if (userInfo.tier == "최고의 플래너") {
          setState(() {
            imageName = 'assets/images/end_tier.png';
          });
        } else {
          _logout();
        }
      }
      return userInfo;
    }catch(e) {
      print(e.toString());

      await retryUserInfo();
      return userInfo;
    }
  }

  retryUserInfo() async {
    _preferences = await SharedPreferences.getInstance();
    await _refreshToken();
    try {
      Dio dio = Dio();
      final response = await dio.get(
          url + '/user',
          options: Options(
              headers: {
                HttpHeaders.contentTypeHeader: "application/json",
                HttpHeaders.authorizationHeader: _preferences.getString('accessToken')
              }
          )
      );

      if (response.statusCode == 200) {
        userInfo = UserInfo.fromJson(response.data);

        print('retry : ' + userInfo.tier);

        await _preferences.setString('userImage', userInfo.tier);

        if (userInfo.tier == "A4 용지") {
          setState(() {
            imageName = 'assets/images/just_paper.png';
          });
        } else if (userInfo.tier == "무료 플래너") {
          setState(() {
            imageName = 'assets/images/free_paper.png';
          });
        } else if (userInfo.tier == "스프링 노트 플래너") {
          setState(() {
            imageName = 'assets/images/spring_planner.png';
          });
        } else if (userInfo.tier == "플라스틱 커버 플래너") {
          setState(() {
            imageName = 'assets/images/plastic_planner.png';
          });
        } else if (userInfo.tier == "가죽 슬러브 플래너") {
          setState(() {
            imageName = 'assets/images/gaguck_planner.png';
          });
        } else if (userInfo.tier == "고급 가죽 슬러브 플래너") {
          setState(() {
            imageName = 'assets/images/good_gaguck_planner.png';
          });
        } else if (userInfo.tier == "맞춤 재작 플래너") {
          setState(() {
            imageName = 'assets/images/best_planner.png';
          });
        } else if (userInfo.tier == "최고의 플래너") {
          setState(() {
            imageName = 'assets/images/end_tier.png';
          });
        } else if (userInfo.tier.isEmpty) {
          _logout();
        }
      }
    }catch(e) {
      print(e.toString());

      _logout();
    }
  }

  @override
  void initState() {
    fUserInfo = _getUserInfo();
    _getTokens();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var _height = MediaQuery.of(context).size.height;
    var _width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Color(0xffFBFBFB),
      drawer: SideMenuWidget(tier: tier),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Color(0xffFBFBFB),
        toolbarHeight: 60,
        titleSpacing: 0,
        title: Text(
          "정보",
          style: TextStyle(
              fontFamily: 'NotoSansKR',
              fontWeight: FontWeight.w700,
              fontSize: 24,
              color: Color(0xff2C2C2C)
          ),
        ),
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
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            FutureBuilder(
                future: fUserInfo,
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
                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                margin: EdgeInsets.only(top: _height * 0.07),
                                child: Image.asset(imageName),
                                width: _width * 0.461,
                                height: _width * 0.461,
                              )
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                margin: EdgeInsets.only(top: 10),
                                child: Text(
                                  userInfo.tier,
                                  style: TextStyle(
                                      color: Color(0xff2C2C2C),
                                      fontFamily: 'NotoSansKR',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16
                                  ),
                                ),
                              )
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                margin: EdgeInsets.only(top: 20),
                                child: Text(
                                  'Lv. ' + userInfo.userLevel.toString(),
                                  style: TextStyle(
                                      color: Color(0xff2F5DFB),
                                      fontFamily: 'NotoSansKR',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 24
                                  ),
                                ),
                              ),
                              Container(
                                margin: EdgeInsets.only(left: 10, top: 20),
                                child: Text(
                                  userInfo.nickName,
                                  style: TextStyle(
                                      color: Color(0xff2C2C2C),
                                      fontFamily: 'NotoSansKR',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 24
                                  ),
                                ),
                              )
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                margin: EdgeInsets.only(top: 20),
                                child: IntervalProgressBar(
                                  radius: 20,
                                  direction: IntervalProgressDirection.horizontal,
                                  max: userInfo.maxExp,
                                  progress: userInfo.exp,
                                  size: Size(_width * 0.87, 12),
                                  defaultColor: Color(0xffF4F4F4),
                                  intervalSize: 30,
                                  highlightColor: Color(0xff2F5DFB),
                                  intervalHighlightColor: Colors.transparent,
                                  intervalColor: Colors.transparent,
                                ),
                                width: _width * 0.66,
                              )
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                margin: EdgeInsets.only(top: 20, left: 50),
                                child: Text(
                                  userInfo.exp.toString(),
                                  style: TextStyle(
                                      color: Color(0xff2C2C2C),
                                      fontFamily: 'NotoSansKR',
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16
                                  ),
                                ),
                              ),
                              Container(
                                margin: EdgeInsets.only(left: 10, top: 20, right: 50),
                                child: Text(
                                  userInfo.maxExp.toString(),
                                  style: TextStyle(
                                      color: Color(0xff2C2C2C),
                                      fontFamily: 'NotoSansKR',
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16
                                  ),
                                ),
                              )
                            ],
                          ),

                        ],
                      ),
                    );
                  }
                }
            ),
            Container(
              margin: EdgeInsets.only(top: 60),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    margin: EdgeInsets.only(left: 40),
                    child: RaisedButton(
                      onPressed: () {
                        showAnimatedDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) {
                              return ClassicGeneralDialogWidget(
                                titleText: '로그아웃',
                                contentText: '정말 로그아웃 하시겠습니까?',
                                onPositiveClick: () {
                                  _showTaost('로그아웃 되었습니다!');
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
                                  Navigator.pop(context);
                                },
                                onNegativeClick: () {
                                  _showTaost('취소');
                                  Navigator.of(context).pop();
                                },
                                positiveText: '네..',
                                negativeText: '아니요!',
                                negativeTextStyle: TextStyle(
                                    color: Color(0xff2F5DFB),
                                    fontFamily: 'NotoSansKR',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16
                                ),
                                positiveTextStyle: TextStyle(
                                    color: Colors.green,
                                    fontFamily: 'NotoSansKR',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16
                                ),
                              );
                            }
                        );
                      },
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)
                      ),
                      color: Color(0xffF4F4F4),
                      child: Container(
                        child: Center(
                          child: Icon(
                            Icons.logout,
                            color: Color(0xff585858),
                            size: 35,
                          ),
                        ),
                      ),
                      elevation: 0,
                    ),
                    width: 80,
                    height: 80,
                  ),
                  Container(
                    child: RaisedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                            PageTransition(
                                child: AchievementPage(),
                                type: PageTransitionType.bottomToTop
                            )
                        );
                      },
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)
                      ),
                      color: Color(0xffF4F4F4),
                      child: Container(
                        child: Center(
                          child: Icon(
                            Icons.emoji_events,
                            color: Color(0xff585858),
                            size: 35,
                          ),
                        ),
                      ),
                      elevation: 0,
                    ),
                    width: 80,
                    height: 80,
                  ),
                  Container(
                    margin: EdgeInsets.only(right: 40),
                    child: RaisedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          PageTransition(
                            child: SettingPage(userInfo.nickName),
                            type: PageTransitionType.bottomToTop
                          )
                        );
                      },
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)
                      ),
                      color: Color(0xffF4F4F4),
                      child: Container(
                        child: Center(
                          child: Icon(
                            Icons.settings,
                            color: Color(0xff585858),
                            size: 35,
                          ),
                        ),
                      ),
                      elevation: 0,
                    ),
                    width: 80,
                    height: 80,
                  ),
                ],
              ),
            )
          ],
        )
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