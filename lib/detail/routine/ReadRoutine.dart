import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animated_dialog/flutter_animated_dialog.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:online_planner_app/detail/routine/UpdateRoutineWidget.dart';
import 'package:online_planner_app/login/login_page.dart';
import 'package:online_planner_app/main/main_page.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReadRoutineWidget extends StatefulWidget {
  Routine routine;

  ReadRoutineWidget(
      this.routine
      );

  _ReadRoutineState createState() => _ReadRoutineState(routine);
}

class _ReadRoutineState extends State<ReadRoutineWidget> {
  Routine routine;

  Color itemColor = Color(0xffF4F4F4);
  Color itemTextColor = Color(0xff9B9B9B);

  final String url = 'http://220.90.237.33:7070';

  _ReadRoutineState(this.routine);

  _showTaost(String message) {
    return Fluttertoast.showToast(
        msg: message,
        textColor: Colors.black,
        backgroundColor: Colors.grey,
        gravity: ToastGravity.BOTTOM,
        fontSize: 15
    );
  }

  _refreshToken() async {
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
        sharedPreferences = await SharedPreferences.getInstance();

        var token = Token.fromJson(response.data);

        sharedPreferences.setString("accessToken", token.accessToken);
        sharedPreferences.setString("refreshToken", token.refreshToken);

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

  String content = "|";

  @override
  void initState() {
    routine.dayOfWeeks.forEach((element) {
      content += ' ' + element + ' |';
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var _height = MediaQuery.of(context).size.height;
    var _width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: itemColor,
        toolbarHeight: 60,
        centerTitle: true,
        title: Text(
          routine.title,
          style: TextStyle(
              fontFamily: 'NotoSansKR',
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: Color(0xff2C2C2C)
          ),
        ),
        titleSpacing: 0,
        leading: Container(
            child: Builder(
                builder: (context) => Container(
                  margin: EdgeInsets.only(left: 10),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_ios_rounded),
                    onPressed: () => Navigator.pop(context),
                    color: Color(0xff2C2C2C),
                    iconSize: 35,
                  ),
                )
            )
        ),
        actions: [
          TextButton(
            onPressed: () {
              showCupertinoModalBottomSheet(
                context: context,
                builder: (BuildContext context) => UpdateRoutine(routine),
              );
            },
            child: Text(
              '수정',
              style: TextStyle(
                  fontFamily: 'NotoSansKR',
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: Color(0xff2C2C2C)
              ),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        margin: EdgeInsets.only(top: 30, left: 20),
                        child: Text(
                          '날짜',
                          style: TextStyle(
                              fontFamily: 'NotoSansKR',
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: Color(0xff2C2C2C)
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 30, right: 20),
                      child: Text(
                        content,
                        style: TextStyle(
                            fontFamily: 'NotoSansKR',
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: Color(0xff2C2C2C)
                        ),
                      ),
                    )
                  ],
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        margin: EdgeInsets.only(top: 30, left: 20),
                        child: Text(
                          '시간',
                          style: TextStyle(
                              fontFamily: 'NotoSansKR',
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: Color(0xff2C2C2C)
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 30, right: 20),
                      child: Text(
                        routine.startTime + ' ~ ' + routine.endTime,
                        style: TextStyle(
                            fontFamily: 'NotoSansKR',
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: Color(0xff2c2c2c)
                        ),
                      ),
                    )
                  ],
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        margin: EdgeInsets.only(top: 30, left: 20),
                        child: Text(
                          '알림',
                          style: TextStyle(
                              fontFamily: 'NotoSansKR',
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: Color(0xff2C2C2C)
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 30, right: 20),
                      child: Text(
                        routine.isPushed ? '켜짐' : '꺼짐',
                        style: TextStyle(
                            fontFamily: 'NotoSansKR',
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: Color(0xff2C2C2C)
                        ),
                      ),
                    )
                  ],
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        margin: EdgeInsets.only(top: 30, left: 20),
                        child: Text(
                          '완료',
                          style: TextStyle(
                              fontFamily: 'NotoSansKR',
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: Color(0xff2C2C2C)
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 30, right: 20),
                      child: Text(
                        routine.isSuccess ? '완료됨' : '완료되지 않음',
                        style: TextStyle(
                            fontFamily: 'NotoSansKR',
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: Color(0xff2C2C2C)
                        ),
                      ),
                    )
                  ],
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        margin: EdgeInsets.only(top: 30, left: 20),
                        child: Text(
                          '중요도',
                          style: TextStyle(
                              fontFamily: 'NotoSansKR',
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: Color(0xff2C2C2C)
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 30, right: 20),
                      child: Text(
                        routine.priority,
                        style: TextStyle(
                            fontFamily: 'NotoSansKR',
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: Color(0xff2C2C2C)
                        ),
                      ),
                    )
                  ],
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        margin: EdgeInsets.only(top: 30, left: 20),
                        child: Text(
                          '내용',
                          style: TextStyle(
                              fontFamily: 'NotoSansKR',
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: Color(0xff2C2C2C)
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
            Center(
              child: Container(
                margin: EdgeInsets.only(top: 10),
                width: _width * 0.871,
                padding: EdgeInsets.all(10),
                child: Text(
                  routine.content,
                  style: TextStyle(
                      fontFamily: 'NotoSansKR',
                      fontWeight: FontWeight.normal,
                      fontSize: 18,
                      color: Color(0xff2C2C2C)
                  ),
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  color: Color(0xffF4F4F4),
                ),
              ),
            )
          ],
        ),
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