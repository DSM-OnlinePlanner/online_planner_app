import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:online_planner_app/detail/setting/LogInDialog.dart';
import 'package:online_planner_app/detail/user_info/user_info_detail.dart';
import 'package:online_planner_app/login/login_page.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingPage extends StatefulWidget {
  String name = '';

  SettingPage(this.name);
  _SettingsWidget createState() => _SettingsWidget(name);
}

class _SettingsWidget extends State<SettingPage> {
  String name = '';
  _SettingsWidget(this.name);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffFBFBFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Color(0xffFBFBFB),
        toolbarHeight: 60,
        titleSpacing: 0,
        title: Text(
          "설정",
          style: TextStyle(
              fontFamily: 'NotoSansKR',
              fontWeight: FontWeight.w700,
              fontSize: 24,
              color: Color(0xff2C2C2C)
          ),
        ),
        leading: Container(
          margin: EdgeInsets.only(left: 10),
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios),
            onPressed: () {
              Navigator.pop(
                  context,
                  PageTransition(
                      child: UserInfoPage(),
                      type: PageTransitionType.topToBottom
                  )
              );
            },
            color: Color(0xff2C2C2C),
            iconSize: 35,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.only(left: 20, top: 15),
                  child: Text(
                    "계정 설정",
                    style: TextStyle(
                        fontFamily: 'NotoSansKR',
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        color: Color(0xff9B9B9B)
                    ),
                  ),
                )
              ],
            ),
            //나중에 구현될 예정
            /*Container(
              margin: EdgeInsets.only(top: 15),
              child: ListView(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                          top: BorderSide(
                              color: Color(0xffD1D1D1),
                              width: 1
                          ),
                      ),
                      color: Colors.transparent,
                    ),
                    child: FlatButton(
                      onPressed: () { 
                        
                      }, 
                      child: Row(
                        children: [
                          Expanded(
                              child: Row(
                                children:[
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    child: Image.asset('assets/images/change_nick.png'),
                                    margin: EdgeInsets.only(left: 10),
                                  ),
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    margin: EdgeInsets.only(left: 15),
                                    child: Text(
                                      '닉네임 변경',
                                      style: TextStyle(
                                          fontFamily: 'NotoSansKR',
                                          fontWeight: FontWeight.normal,
                                          fontSize: 16,
                                          color: Color(0xff2C2C2C)
                                      ),
                                    ),
                                  )
                                ],
                              ),
                          ),
                          Expanded(
                            child: Container(
                              alignment: Alignment.centerRight ,
                              margin: EdgeInsets.only(right: 10),
                              child: Text(
                                name,
                                style: TextStyle(
                                    fontFamily: 'NotoSansKR',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: Color(0xff2C2C2C)
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                            color: Color(0xffD1D1D1),
                            width: 1
                        ),
                      ),
                      color: Colors.transparent,
                    ),
                    child: FlatButton(
                      onPressed: () {

                      },
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children:[
                                Container(
                                  child: Image.asset('assets/images/change_pw.png'),
                                  margin: EdgeInsets.only(left: 10),
                                ),
                                Container(
                                  margin: EdgeInsets.only(left: 15),
                                  child: Text(
                                    '비밀번호 변경',
                                    style: TextStyle(
                                        fontFamily: 'NotoSansKR',
                                        fontWeight: FontWeight.normal,
                                        fontSize: 16,
                                        color: Color(0xff2C2C2C)
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  margin: EdgeInsets.only(right: 10),
                                  child: Text(
                                    '변경 >',
                                    style: TextStyle(
                                        fontFamily: 'NotoSansKR',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                        color: Color(0xff2C2C2C)
                                    ),
                                  ),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            */
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                      color: Color(0xffD1D1D1),
                      width: 1
                  ),
                  bottom: BorderSide(
                      color: Color(0xffD1D1D1),
                      width: 1
                  ),
                ),
                color: Colors.transparent,
              ),
              child: FlatButton(
                onPressed: () {
                  showCupertinoModalBottomSheet(
                      context: context,
                      builder: (context) => LoginWidget()
                  );
                },
                child: Row(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children:[
                        Container(
                          child: Image.asset('assets/images/delete_account.png'),
                          margin: EdgeInsets.only(left: 10),
                        ),
                        Container(
                          margin: EdgeInsets.only(left: 15),
                          child: Text(
                            '계정 탈퇴',
                            style: TextStyle(
                                fontFamily: 'NotoSansKR',
                                fontWeight: FontWeight.normal,
                                fontSize: 16,
                                color: Color(0xff2C2C2C)
                            ),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
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