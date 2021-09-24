import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:online_planner_app/login/login_page.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginWidget extends StatefulWidget {
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<LoginWidget> {
  final String url = 'http://220.90.237.33:7070';

  String email = "", password = "";

  final _emailTextController = TextEditingController();
  final _passwordTextController = TextEditingController();

  _deleteAccount() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    try {
      Dio dio = Dio();
      final response = await dio.delete(
          url + '/user/account',
          options: Options(
              headers: {
                HttpHeaders.authorizationHeader: preferences.getString('accessToken') ?? ""
              }
          ),
          data: {
            'email' : email,
            'password' : password
          }
      );

      if(response.statusCode == 200) {
        print(response.data);
      }
    }catch(e) {
      await _retryDeleteAccount();
    }
  }

  _retryDeleteAccount() async {
    await _refreshToken();
    SharedPreferences preferences = await SharedPreferences.getInstance();
    try {
      Dio dio = Dio();
      final response = await dio.delete(
          url + '/user/account',
          options: Options(
              headers: {
                HttpHeaders.authorizationHeader: preferences.getString('accessToken') ?? ""
              }
          ),
          data: {
            'email' : email,
            'password' : password
          }
      );

      if(response.statusCode == 200) {
        print(response.data);
      }
    }catch(e) {
      await _logout();
    }
  }

  Future<bool> _refreshToken() async {
    SharedPreferences _preferences = await SharedPreferences.getInstance();
    Dio dio = Dio();
    try {
      final response = await dio.put(
          url + '/auth',
          options: Options(
              headers: {
                HttpHeaders.contentTypeHeader: 'application/json',
                'X-Refresh-Token': _preferences.getString('refreshToken') ?? ""
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

  _logout() async {
    SharedPreferences _preferences = await SharedPreferences.getInstance();
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

  _showTaost(String message) {
    return Fluttertoast.showToast(
        msg: message,
        textColor: Colors.black,
        backgroundColor: Colors.grey,
        gravity: ToastGravity.BOTTOM,
        fontSize: 15
    );
  }

  @override
  Widget build(BuildContext context) {
    var _height = MediaQuery.of(context).size.height;
    var _width = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: 20, left: _width * 0.061),
            child: Text(
              '로그인',
              style: TextStyle(
                  fontFamily: 'NotoSansKR',
                  fontWeight: FontWeight.w700,
                  fontSize: 36,
                  color: Color(0xff2C2C2C)
              ),
            ),
          ),
          Row(
            children: [
              Container(
                margin: EdgeInsets.only(top: 20, left: 40),
                child: Text(
                  '이메일',
                  style: TextStyle(
                      fontFamily: 'NotoSansKR',
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                      color: Color(0xff2C2C2C)
                  ),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                  width: _width * 0.871,
                  height: 45,
                  margin: EdgeInsets.only(top: 20),
                  child: CupertinoTextField(
                    textInputAction: TextInputAction.next,
                    textAlign: TextAlign.start,
                    controller: _emailTextController,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      color: Color(0xffF4F4F4),
                    ),
                    maxLength: 20,
                    maxLines: 1,
                    placeholder: '이메일을 입력하세요',
                    placeholderStyle: TextStyle(
                        fontFamily: 'NotoSansKR',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Color(0xffD1D1D1)
                    ),
                    padding: EdgeInsets.only(left: 20),
                  )
              ),
            ],
          ),
          Row(
            children: [
              Container(
                margin: EdgeInsets.only(top: 40, left: 40),
                child: Text(
                  '비밀번호',
                  style: TextStyle(
                      fontFamily: 'NotoSansKR',
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                      color: Color(0xff2C2C2C)
                  ),
                ),
              ),
            ],
          ),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                      width: _width * 0.871,
                      height: 45,
                      margin: EdgeInsets.only(top: 20),
                      child: CupertinoTextField(
                        textInputAction: TextInputAction.next,
                        textAlign: TextAlign.start,
                        controller: _passwordTextController,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                          color: Color(0xffF4F4F4),
                        ),
                        maxLength: 20,
                        maxLines: 1,
                        placeholder: '비밀번호을 입력하세요',
                        placeholderStyle: TextStyle(
                            fontFamily: 'NotoSansKR',
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Color(0xffD1D1D1)
                        ),
                        padding: EdgeInsets.only(left: 20),
                      )
                  ),
                ],
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: EdgeInsets.only(top: 80, bottom: 40),
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
                    print("click");
                    email = _emailTextController.text;
                    password = _passwordTextController.text;

                    if(email.length <= 0 || password.length <= 0) {
                      _showTaost("이메일 혹은 패스워드를 입력해주세요!");
                      return;
                    }

                    _deleteAccount();
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
    );
  }
}