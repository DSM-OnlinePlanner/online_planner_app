import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_swipe_action_cell/core/cell.dart';
import 'package:online_planner_app/login/login_page.dart';
import 'package:page_transition/page_transition.dart';
import 'package:progress_indicators/progress_indicators.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NoticePage extends StatefulWidget {
  _NoticeWidget createState() => _NoticeWidget();
}

class _NoticeWidget extends State<NoticePage> {
  List<Notice> noticeItem = [];

  String accessToken = "",
      refreshToken = "",
      deviceToken = "";

  int pageNum = 0;

  late Token token;

  final String url = 'http://220.90.237.33:7070';

  late SharedPreferences _preferences;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<List<Notice>> _getNotice() async {
    try {
      Dio dio = Dio();
      final response = await dio.get(
        url + '/notice/' + pageNum.toString(),
        options: Options(
            headers: {
              HttpHeaders.authorizationHeader: accessToken
            }
        ),
      );

      if (response.statusCode == 200) {
        noticeItem =
            (response.data as List).map((e) => Notice.fromJson(e)).toList();

        return noticeItem;
      } else {
        await _retryNotice();

        return noticeItem;
      }
    } catch (e) {
      print('notice : ' + e.toString());

      await _retryNotice();
      return noticeItem;
    }
  }

  _retryNotice() async {
    await _refreshToken();
    try {
      Dio dio = Dio();
      var accessToken;
      final response = await dio.get(
        url + '/notice/' + pageNum.toString(),
        options: Options(
            headers: {
              HttpHeaders.authorizationHeader: accessToken
            }
        ),
      );

      if (response.statusCode == 200) {
        noticeItem =
            (response.data as List).map((e) => Notice.fromJson(e)).toList();
      }else {
        _logout();
      }
    } catch (e) {
      _logout();
    }
  }

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

  Future<bool> _refreshToken() async {
    Dio dio = Dio();
    try {
      final response = await dio.put(
          url + '/auth',
          options: Options(
              headers: {
                HttpHeaders.contentTypeHeader: 'application/json',
                'X-Refresh-Token': refreshToken
              }
          )
      );

      if (response.statusCode == 200) {
        _preferences = await SharedPreferences.getInstance();

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

  _getTokens() async {
    _preferences = await SharedPreferences.getInstance();
    accessToken = _preferences.getString("accessToken") ?? "";
    refreshToken = _preferences.getString('refreshToken') ?? "";
    deviceToken = await _firebaseMessaging.getToken() ?? "";

    if (accessToken.isEmpty || refreshToken.isEmpty || deviceToken.isEmpty) {
      _logout();
    } else {
      print("accessToken : " + accessToken);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: FutureBuilder <List<Notice>>(
        future: _getNotice(),
        builder: (context, snapshot) {
          if (snapshot.hasData == false) {
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
          } else if (snapshot.hasError) {
            return _logout();
          } else {
            if (noticeItem.length == 0) {
              return ListView(
                shrinkWrap: true,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        margin: EdgeInsets.only(top: 50, bottom: 10),
                        child: Text(
                          '현재 알림이 없습니다.',
                          style: TextStyle(
                              fontFamily: 'NotoSansKR',
                              fontWeight: FontWeight.w500,
                              fontSize: 18,
                              color: Color(0xff9B9B9B)
                          ),
                        ),
                      )
                    ],
                  )
                ],
              );
            } else {
              return ListView.builder(
                shrinkWrap: true,
                itemCount: noticeItem.length,
                itemBuilder: (context, index) {
                  return SwipeActionCell(
                      key: ObjectKey(noticeItem[index]),
                      trailingActions: <SwipeAction>[
                        SwipeAction(
                            title: "삭제",
                            onTap: (CompletionHandler handler) async {
                              handler(false);
                              noticeItem.removeAt(index);
                            },
                            color: Colors.red
                        ),
                      ],
                      child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                                top: BorderSide(
                                    color: Color(0xffD1D1D1),
                                    width: 1
                                ),
                                bottom: BorderSide(
                                    color: Color(0xffD1D1D1),
                                    width: 1
                                )
                            ),
                            color: Color(0xffFBFBFB),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment
                                    .start,
                                children: [
                                  Container(
                                    margin: EdgeInsets.only(left: 10),
                                    child: Image.asset(
                                        'assets/images/notice_check.png'),
                                  ),
                                  Container(
                                    margin: EdgeInsets.only(left: 10),
                                    child: Text(
                                      noticeItem[index].title,
                                      style: TextStyle(
                                          fontFamily: 'NotoSansKR',
                                          fontWeight: FontWeight.w500,
                                          fontSize: 18,
                                          color: Color(0xff2C2C2C)
                                      ),
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment
                                        .end,
                                    children: [
                                      Container(
                                        margin: EdgeInsets.only(
                                            right: 10),
                                        child: Text(
                                          noticeItem[index].noticeAt
                                              .substring(0, 5),
                                          style: TextStyle(
                                              fontFamily: 'NotoSansKR',
                                              fontWeight: FontWeight
                                                  .w500,
                                              fontSize: 16,
                                              color: Color(0xffD1D1D1)
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              )
                            ],
                          )
                      )
                  );
                },
              );
            }
          }
        },
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

class Notice {
  int noticeId;
  String title, noticeAt, noticeDate;

  Notice(
      {required this.noticeId, required this.title, required this.noticeAt, required this.noticeDate});

  factory Notice.fromJson(Map<String, dynamic> json) {
    return Notice(
        noticeId: json['noticeId'],
        title: json['title'],
        noticeAt: json['noticeAt'],
        noticeDate: json['noticeDate']
    );
  }
}