import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:online_planner_app/login/login_page.dart';
import 'package:online_planner_app/main/main_page.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginDetailPage extends StatefulWidget {
  _LoginDetailWidget createState() => _LoginDetailWidget();
}

class _LoginDetailWidget extends State<LoginDetailPage> {
  String nickName = "", tier = "";
  int exp = -1, maxExp = -1, userLevel = -1;

  bool _visibility = false;

  late SharedPreferences _prefs;

  final _emailTextController = TextEditingController();
  final _passwordTextController = TextEditingController();

  final String url = 'http://220.90.237.33:7070';

  final _firebaseMessaging = FirebaseMessaging.instance;

  late UserInfo userInfo;

  late Token token;

  String accessToken = "";
  String refreshToken = "";

  Future<UserInfo> _getUserInfo() async {
    try {
      Dio dio = Dio();
      final response = await dio.get(
          url + '/user',
          options: Options(
              headers: {
                HttpHeaders.contentTypeHeader: "application/json",
                HttpHeaders.authorizationHeader: accessToken
              }
          )
      );

      if (response.statusCode == 200) {
        userInfo = UserInfo.fromJson(response.data);

        print(userInfo.tier);

        _prefs.setString('tier', userInfo.tier);

        Navigator.pushAndRemoveUntil(
            context,
            PageTransition(
                type: PageTransitionType.rightToLeft,
                child: MainPage.init(userInfo.tier)
            ),
                (route) => false
        );

        return userInfo;
      }
      return userInfo;
    }catch(e) {
      print(e.toString());

      await retryUserInfo();
      return userInfo;
    }
  }

  retryUserInfo() async {
    await _refreshToken();
    try {
      Dio dio = Dio();
      final response = await dio.get(
          url + '/user',
          options: Options(
              headers: {
                HttpHeaders.contentTypeHeader: "application/json",
                HttpHeaders.authorizationHeader: accessToken
              }
          )
      );

      if (response.statusCode == 200) {
        userInfo = UserInfo.fromJson(response.data);

        print(userInfo.tier);
        Navigator.pushAndRemoveUntil(
            context,
            PageTransition(
                type: PageTransitionType.rightToLeft,
                child: MainPage.init(userInfo.tier)
            ),
                (route) => false
        );

        return userInfo;
      }
      return userInfo;
    }catch(e) {
      print(e.toString());

      _logout();
    }
  }

  _refreshToken() async {
    try{
      Dio dio = Dio();
      final response = await dio.put(
          url + '/auth',
          options: Options(
              headers: {
                HttpHeaders.contentTypeHeader: 'application/json',
                'X-Refresh-Token' : refreshToken
              }
          )
      );

      print('refreshToken : ' + response.statusCode.toString());

      if(response.statusCode == 200) {
        _prefs = await SharedPreferences.getInstance();

        token = Token.fromJson(response.data);

        _prefs.setString("accessToken", token.accessToken);
        _prefs.setString("refreshToken", token.refreshToken);
      }else {
        _logout();
      }
    }catch(e) {
      print('main page refreshToken : ' + e.toString());
      _logout();
    }
  }

  _logout() async {
    FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
    SharedPreferences _preferences = await SharedPreferences.getInstance();
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

  _getDeviceToken() async {
    deviceToken = await _firebaseMessaging.getToken() ?? "";

    print(deviceToken);
  }

  String email = "";
  String password = "";
  String deviceToken = "";

  void show() {
    setState(() {
      _visibility = true;
    });
  }

  void hide() {
    setState(() {
      _visibility = false;
    });
  }

  _saveToken(Token token) async{
    _prefs = await SharedPreferences.getInstance();
    print(token.accessToken);
    print(token.refreshToken);

    _prefs.setString("accessToken", token.accessToken);
    _prefs.setString("refreshToken", token.refreshToken);
    _prefs.setBool("isAuth", true);

    accessToken = token.accessToken;
    refreshToken = token.refreshToken;
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

  _postLogin() async {
    try {
      var dio = new Dio();
      final response = await dio.post(
          url + '/auth',
          options: Options(
              headers: {
                HttpHeaders.contentTypeHeader: "application/json"
              }
          ),
          data: jsonEncode(
              <String, String> {
                "email" : email,
                "password" : password,
                "deviceToken" : deviceToken
              }
          )
      );

      if(response.statusCode == 200) {
        await _showTaost("로그인에 성공하였습니다!");
        await _saveToken(Token.fromJson(response.data));
        await _getUserInfo();
      }else {
        show();
      }
    }catch(e) {
      show();
    }
  }

  @override
  void initState() {
    super.initState();
    _getDeviceToken();
  }

  @override
  Widget build(BuildContext context) {
    var _height = MediaQuery.of(context).size.height;
    var _width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Color(0xffF4F4F4),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Color(0xffFBFBFB),
        toolbarHeight: 0,
      ),
      body: SingleChildScrollView(
        child: Stack(
          children: <Widget> [
            Container(
              color: Color(0xffF4F4F4),
              width: _width,
              height: 25,
              child: FlatButton(
                  onPressed: () {
                    Navigator.pop(
                        context,
                        PageTransition(
                            type: PageTransitionType.topToBottom,
                            child: StartPage()
                        )
                    );
                  },
                  child: Container(
                    width: 60,
                    height: 6,
                    child: RaisedButton(
                      onPressed: () {
                        Navigator.pop(
                            context,
                            PageTransition(
                                type: PageTransitionType.topToBottom,
                                child: StartPage()
                            )
                        );
                      },
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)
                      ),
                      color: Color(0xff9B9B9B),
                    ),
                  )
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: _height * 0.17, left: _width * 0.061),
              child: Text(
                '로그인',
                style: TextStyle(
                    fontFamily: 'NotoSansKR',
                    fontWeight: FontWeight.w700,
                    fontSize: 36
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: _height * 0.30, left: _width * 0.064),
              child: Text(
                '이메일',
                style: TextStyle(
                    fontFamily: 'NotoSansKR',
                    fontWeight: FontWeight.w700,
                    fontSize: 24
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  margin: EdgeInsets.only(top: _height * 0.34),
                  width: _width * 0.876,
                  child: TextField(
                    controller: _emailTextController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                        hintText: "이메일을 입력해주세요",
                        hintStyle: TextStyle(
                            fontSize: 18,
                            fontFamily: 'NotoSansKR',
                            fontWeight: FontWeight.normal,
                            color: Color(0xffC4C4C4)
                        ),
                        contentPadding: EdgeInsets.only(left: 10, right: 10)
                    ),
                    onChanged: (value) {
                      hide();
                      print(value);
                    },

                  ),
                ),
              ],
            ),
            Container(
              margin: EdgeInsets.only(top: _height * 0.43, left: _width * 0.064),
              child: Text(
                '비밀번호',
                style: TextStyle(
                    fontFamily: 'NotoSansKR',
                    fontWeight: FontWeight.w700,
                    fontSize: 24
                ),
              ),
            ),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: _height * 0.47),
                      width: _width * 0.876,
                      child: TextFormField(
                        controller: _passwordTextController,
                        obscureText: true,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                            hintText: "비밀번호를 입력해주세요",
                            hintStyle: TextStyle(
                                fontSize: 18,
                                fontFamily: 'NotoSansKR',
                                fontWeight: FontWeight.normal,
                                color: Color(0xffC4C4C4)
                            ),
                            contentPadding: EdgeInsets.only(left: 10, right: 10)
                        ),
                        onChanged: (value) {
                          hide();
                          print(value);
                        },
                      ),
                    )
                  ],
                ),
                Stack(
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                            margin: EdgeInsets.only(top: 20, left: _width * 0.061),
                            child: Visibility(
                              visible: _visibility,
                              child: Text(
                                "존재하지 않는 계정입니다",
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'NotoSnasKR',
                                    fontSize: 16,
                                    color: Colors.red
                                ),
                              ),
                            )
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        Container(
                          margin: EdgeInsets.only(top: 5),
                          child: TextButton(
                            onPressed: () {

                            },
                            child: Text(
                              "비밀번호",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontFamily: 'NotoSnasKR',
                                fontSize: 16,
                                color: Color(0xff2F5DFB),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(top: 3, right: _width * 0.061),
                          child: Text(
                            "를 잊으셨나요?",
                            style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontFamily: 'NotoSnasKR',
                                fontSize: 16,
                                color: Colors.black
                            ),
                          ),
                        )
                      ],
                    )
                  ],
                )
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  margin: EdgeInsets.only(top: _height * 0.795),
                  height: 60,
                  width: _width * 343/390,
                  child: RaisedButton (
                    child: Text(
                      "로그인",
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontFamily: 'NotoSansKR',
                          fontSize: 20,
                          color: Colors.white
                      ),
                    ),
                    onPressed: () {
                      hide();
                      print("click");
                      email = _emailTextController.text;
                      password = _passwordTextController.text;
                      _getDeviceToken();

                      if(email.length <= 0 || password.length <= 0) {
                        _showTaost("이메일 혹은 패스워드를 입력해주세요!");
                        return;
                      }

                      if(deviceToken.length <= 0) {
                        _showTaost("로그인에 실패했습니다.");
                      }

                      _postLogin();
                    },
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)
                    ),
                    color: Color(0xff2F5DFB),
                  ),
                )
              ],
            ),
          ],
        ),
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

class UserInfo {
  final String nickName;
  final int userLevel;
  final int maxExp;
  final int exp;
  final String tier;

  UserInfo(
      {required this.nickName, required this.userLevel, required this.maxExp, required this.exp, required this.tier});

  factory UserInfo.fromJson(Map<String, dynamic> userInfoMap) {
    return UserInfo(
        nickName: userInfoMap['nickName'],
        userLevel: userInfoMap['userLevel'],
        exp: userInfoMap['exp'],
        maxExp: userInfoMap['maxExp'],
        tier: userInfoMap['tier']
    );
  }
}