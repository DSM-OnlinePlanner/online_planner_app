import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:online_planner_app/detail/record/UpdateMemoWidget.dart';
import 'package:online_planner_app/login/login_page.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReadMemoWidget extends StatefulWidget {
  int memoId;
  String content, memoAt, memoType;

  ReadMemoWidget(
      this.memoId,
      this.content,
      this.memoAt,
      this.memoType
      );

  _ReadMemoState createState() => _ReadMemoState(this.memoId, this.content, this.memoAt, this.memoType);
}

class _ReadMemoState extends State<ReadMemoWidget> {
  int memoId;
  String content, memoAt, memoType;

  Color itemColor = Color(0xffF4F4F4);
  Color itemTextColor = Color(0xff9B9B9B);

  final String url = 'http://220.90.237.33:7070';

  _ReadMemoState(
      this.memoId,
      this.content,
      this.memoAt,
      this.memoType
      );

  _showTaost(String message) {
    return Fluttertoast.showToast(
        msg: message,
        textColor: Colors.black,
        backgroundColor: Colors.grey,
        gravity: ToastGravity.BOTTOM,
        fontSize: 15
    );
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
          '메모',
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
                builder: (context) => UpdateMemoWidget(
                  memoId,
                  content
                ),
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
                          '작성 날짜',
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
                        memoAt,
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
                          '메모타입',
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
                        memoType,
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