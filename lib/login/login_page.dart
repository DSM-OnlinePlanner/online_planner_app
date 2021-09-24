import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:online_planner_app/detail/login/login_detail.dart';
import 'package:online_planner_app/detail/sign_up/sign_up_detail.dart';
import 'package:online_planner_app/main/main_page.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StartPage extends StatefulWidget {
  @override
  _StartWidget createState() => _StartWidget();
}

class _StartWidget extends State<StartPage> {

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          image: DecorationImage(
              image: AssetImage('assets/images/backround.png'),
              fit: BoxFit.cover
          )
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: ButtonAndTextWidget(),
      ),
    );
  }
}

class ButtonAndTextWidget extends StatefulWidget {
  _ButtonAndTextState createState() => _ButtonAndTextState();
}

class _ButtonAndTextState extends State<ButtonAndTextWidget> {
  String nickName = "", tier = "";
  int exp = -1, maxExp = -1, userLevel = -1;

  String deviceToken = "";

  late Token token;

  final _firebaseMessaging = FirebaseMessaging.instance;

  late SharedPreferences _preferences;
  late bool isAuth;
  late String accessToken;
  late String refreshToken;

  Image? userImage;
  UserInfo? userInfo;

  final String url = 'http://220.90.237.33:7070';

  _checkIsAuthed() async{
    _preferences = await SharedPreferences.getInstance();

     isAuth = _preferences.getBool("isAuth") ?? false;

     print(isAuth);

     print("name : " + nickName);

    if(isAuth) {
      Navigator.of(context).pop();

      Navigator.of(context).push(
          PageTransition(
              type: PageTransitionType.rightToLeft,
              child: MainPage.init(userInfo!.tier)
          )
      );
    }
  }

  _refreshToken() async {
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

    if(response.statusCode == 200) {
      _preferences = await SharedPreferences.getInstance();

      token = Token.fromJson(response.data);

      _preferences.setString("accessToken", token.accessToken);
      _preferences.setString("refreshToken", token.refreshToken);
    }else {
      _logout();
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

    }
  }

  _getTokens() async {
    _preferences = await SharedPreferences.getInstance();
    accessToken = _preferences.getString("accessToken") ?? "";
    refreshToken = _preferences.getString('refreshToken') ?? "";
    deviceToken = await _firebaseMessaging.getToken() ?? "";

    if(accessToken.isEmpty || refreshToken.isEmpty || deviceToken.isEmpty) {
      _logout();
    }else {
      print("accessToken : " + accessToken);

      await _getUserInfo();
    }
  }

  _getUserInfo() async {
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

    if(response.statusCode == 200) {
      userInfo = UserInfo.fromJson(response.data);

      print(userInfo!.tier);

      nickName = userInfo!.nickName;
      tier = userInfo!.tier;
      exp = userInfo!.exp;
      maxExp = userInfo!.maxExp;
      userLevel = userInfo!.userLevel;

      _checkIsAuthed();
    }else {
      _refreshToken();
      _getTokens();
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
    _getTokens();

    return Container(
      child: Stack(
        children: <Widget> [
          Container(
            child: Text(
              "온라인 플래너로\n하루를 계획하세요!",
              style: TextStyle(
                  fontFamily: 'NotoSansKR',
                  fontWeight: FontWeight.w700,
                  fontSize: 36
              ),
            ),
            margin: EdgeInsets.only(
                top: _height * 0.291,
                left: _width * 0.04
            ),
          ),
          Column(
            children: <Widget>[
              Container(
                margin: EdgeInsets.only(top: _height * 0.73, left: _width * 0.061),
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
                  onPressed: () async => {
                    Navigator.push(
                      context,
                      PageTransition(
                        type: PageTransitionType.bottomToTop,
                        child: LoginDetailPage()
                      ),
                    ),
                  },
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)
                  ),
                  color: Color(0xff2F5DFB),
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 20, left: _width * 0.061),
                height: 60,
                width: _width * 343/390,
                child: RaisedButton(
                  child: Text(
                    "회원가입",
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontFamily: 'NotoSansKR',
                        fontSize: 20,
                        color: Colors.black
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      PageTransition(
                        type: PageTransitionType.bottomToTop,
                        child: SignUpDetailPage()
                      )
                    );
                  },
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)
                  ),
                  color: Color(0xCCF2F2F2),
                ),
              ),
            ],
          ),
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



