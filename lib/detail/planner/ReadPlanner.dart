import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animated_dialog/flutter_animated_dialog.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:online_planner_app/login/login_page.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'UpdatePlanenrWidget.dart';

class ReadPlannerWidget extends StatefulWidget {
  int plannerId;
  String title, content, startTime, endTime, startDate, endDate;
  String priority;
  String want;
  bool isPushed, isSucceed, isFailed;

  ReadPlannerWidget(
      this.title,
      this.content,
      this.plannerId,
      this.startDate,
      this.endTime,
      this.endDate,
      this.isFailed,
      this.priority,
      this.isSucceed,
      this.startTime,
      this.isPushed,
      this.want
      );

  _ReadPlannerState createState() => _ReadPlannerState(this.title, this.content, this.plannerId, this.startDate, this.endTime, this.endDate, this.isFailed, this.priority, this.isSucceed, this.startTime, this.isPushed, this.want);
}

class _ReadPlannerState extends State<ReadPlannerWidget> {
  int plannerId;
  String title, content, startTime, endTime, startDate, endDate;
  String priority;
  String want;
  bool isPushed, isSucceed, isFailed;

  Color itemColor = Color(0xffF4F4F4);
  Color itemTextColor = Color(0xff9B9B9B);

  final String url = 'http://220.90.237.33:7070';

  _ReadPlannerState(this.title, this.content, this.plannerId, this.startDate, this.endTime, this.endDate, this.isFailed, this.priority, this.isSucceed, this.startTime, this.isPushed, this.want) {
    if (!isSucceed && !isFailed) {
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
      itemTextColor = Color(0xffFFFFFF);
    } else {
      itemColor = Color(0xffF4F4F4);
      itemTextColor = Color(0xff2C2C2C);
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

  _deletePlanner() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    try {
      Dio dio = Dio();
      final response = await dio.delete(
        url + '/planner/' + plannerId.toString(),
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
      await _retryDeletePlanner();
    }
  }

  _retryDeletePlanner() async {
    await _refreshToken();
    SharedPreferences preferences = await SharedPreferences.getInstance();
    try {
      Dio dio = Dio();
      final response = await dio.delete(
          url + '/planner/' + plannerId.toString(),
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
          title,
          style: TextStyle(
              fontFamily: 'NotoSansKR',
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: itemTextColor
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
                    color: itemTextColor,
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
                  builder: (context) => UpdatePlannerWidget(
                      title,
                      content,
                      plannerId,
                      startDate,
                      endTime,
                      endDate,
                      isFailed,
                      priority,
                      isSucceed,
                      startTime,
                      isPushed,
                      want
                  )
              );
            },
            child: Text(
              '수정',
              style: TextStyle(
                  fontFamily: 'NotoSansKR',
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: itemTextColor
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
                        startDate == endDate ? '오늘만' : startDate + ' ~ ' + endDate,
                        style: TextStyle(
                            fontFamily: 'NotoSansKR',
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: isSucceed ? itemTextColor : itemColor
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
                        startTime + ' ~ ' + endTime,
                        style: TextStyle(
                            fontFamily: 'NotoSansKR',
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: isSucceed ? itemTextColor : itemColor
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
                        isPushed ? '켜짐' : '꺼짐',
                        style: TextStyle(
                            fontFamily: 'NotoSansKR',
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: isSucceed ? itemTextColor : itemColor
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
                        isSucceed ? '완료됨' : '완료되지 않음',
                        style: TextStyle(
                            fontFamily: 'NotoSansKR',
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: isSucceed ? itemTextColor : itemColor
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
                        priority,
                        style: TextStyle(
                            fontFamily: 'NotoSansKR',
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: isSucceed ? itemTextColor : itemColor
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
                  content,
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
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  margin: EdgeInsets.only(left: 20, top: 20),
                  child: RaisedButton(
                      onPressed: () {
                        showAnimatedDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) {
                              return ClassicGeneralDialogWidget(
                                titleText: '삭제',
                                contentText: '정말 삭제 하시겠습니까?',
                                onPositiveClick: () {
                                  _showTaost('삭제 되었습니다!');
                                  _deletePlanner();

                                  Navigator.of(context).pop();
                                },
                                onNegativeClick: () {
                                  _showTaost('취소');
                                  Navigator.of(context).pop();
                                },
                                positiveText: '네!',
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
                      color: Colors.red,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)
                      ),
                      child: Center(
                        child: Text(
                          '삭제',
                          style: TextStyle(
                            fontFamily: 'NotoSansKR',
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                            color: Color(0xffffffff),
                          ),
                        ),
                      )
                  ),
                  width: 60,
                  height: 30,
                )
              ],
            ),
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