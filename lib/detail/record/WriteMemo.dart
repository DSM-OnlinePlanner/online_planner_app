import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../login/login_page.dart';


class WriteMemoWidget extends StatefulWidget {
  @override
  _WriteMemoWidgetState createState() => _WriteMemoWidgetState();
}

class _WriteMemoWidgetState extends State<WriteMemoWidget> {
  _showTaost(String message) {
    return Fluttertoast.showToast(
        msg: message,
        textColor: Colors.black,
        backgroundColor: Colors.grey,
        gravity: ToastGravity.BOTTOM,
        fontSize: 15
    );
  }

  Color today = Color(0xff2C2C2C), week = Color(0xff2C2C2C), month = Color(0xff2C2C2C);

  _checkMemoType() {
    if(memoType == 'TODAY') {
      setState(() {
        today = Color(0xff2F5DFB);
        week = Color(0xff2C2C2C);
        month = Color(0xff2C2C2C);
      });
    }else if(memoType == 'WEEK') {
      setState(() {
        week = Color(0xff2F5DFB);
        today = Color(0xff2C2C2C);
        month = Color(0xff2C2C2C);
      });
    }else if(memoType == 'MONTH'){
      setState(() {
        month = Color(0xff2F5DFB);
        week = Color(0xff2C2C2C);
        today = Color(0xff2C2C2C);
      });
    }
  }

  String memoType = "", content = "";
  bool err = false;

  final String url = 'http://220.90.237.33:7070';

  TextEditingController _contentEditingController = TextEditingController();

  _postMemo() async {
    SharedPreferences _preference = await SharedPreferences.getInstance();
    try {
      Dio dio = Dio();
      final response = await dio.post(
        url + '/memo',
        options: Options(
          headers: {
            HttpHeaders.authorizationHeader: _preference.getString('accessToken') ?? ""
          }
        ),
        data: <String, dynamic> {
          'memoType' : memoType,
          'memo' : content
        }
      );

      if(response.statusCode == 200) {
        _showTaost('메모를 작성하였습니다!');

        Navigator.pop(context);
      }
    }catch(e) {
      print(e);

      await _retryPostMemo();
    }
  }

  _retryPostMemo() async {
    await _refreshToken();
    SharedPreferences _preference = await SharedPreferences.getInstance();
    try {
      Dio dio = Dio();
      final response = await dio.post(
          url + '/memo',
          options: Options(
              headers: {
                HttpHeaders.authorizationHeader: _preference.getString('accessToken') ?? ""
              }
          ),
          data: <String, dynamic> {
            'memoType' : memoType,
            'memo' : content
          }
      );

      if(response.statusCode == 200) {
        _showTaost('메모를 작성하였습니다!');

        Navigator.pop(context);
      }
    }catch(e) {
      print(e);
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
    final String url = 'http://220.90.237.33:7070';
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

    }
  }

  @override
  Widget build(BuildContext context) {
    var _height = MediaQuery.of(context).size.height;
    var _width = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      physics: NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                margin: EdgeInsets.only(top: 10, left: 10),
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop("hello");
                  },
                  child: Text(
                    '< 취소',
                    style: TextStyle(
                        fontFamily: 'NotoSansKR',
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        color: Color(0xff2F5DFB)
                    ),
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 10),
                child: Text(
                  '메모 작성',
                  style: TextStyle(
                      fontFamily: 'NotoSansKR',
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: Color(0xff000000)
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 10, right: 10),
                child: TextButton(
                  onPressed: () {
                    content = _contentEditingController.text;

                    if(content.isEmpty || memoType.isEmpty) {
                      setState(() {
                        err = true;
                      });
                      return;
                    }

                    _postMemo();
                  },
                  child: Text(
                    '추가',
                    style: TextStyle(
                        fontFamily: 'NotoSansKR',
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        color: Color(0xff2F5DFB)
                    ),
                  ),
                ),
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
                      margin: EdgeInsets.only(top: 5, left: 20),
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
                    width: 75,
                    margin: EdgeInsets.only(top: 5, right: 10),
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          memoType = 'TODAY';
                        });
                        _checkMemoType();
                      },
                      child: Text(
                        'TODAY',
                        style: TextStyle(
                            fontFamily: 'NotoSansKR',
                            fontWeight: FontWeight.w500,
                            fontSize: 18,
                            color: today
                        ),
                      ),
                    )
                  ),
                  Container(
                      width: 75,
                      margin: EdgeInsets.only(top: 5, right: 10),
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            memoType = 'WEEK';
                          });
                          _checkMemoType();
                        },
                        child: Text(
                          'WEEK',
                          style: TextStyle(
                              fontFamily: 'NotoSansKR',
                              fontWeight: FontWeight.w500,
                              fontSize: 18,
                              color: week
                          ),
                        ),
                      )
                  ),
                  Container(
                      width: 85,
                      margin: EdgeInsets.only(top: 5, right: 10),
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            memoType = 'MONTH';
                          });
                          _checkMemoType();
                        },
                        child: Text(
                          'MONTH',
                          style: TextStyle(
                              fontFamily: 'NotoSansKR',
                              fontWeight: FontWeight.w500,
                              fontSize: 18,
                              color: month
                          ),
                        ),
                      )
                  )
                ],
              )
            ],
          ),
          Container(
              width: _width * 0.871,
              height: _height * 0.19,
              margin: EdgeInsets.only(top: 20),
              child: CupertinoTextField(
                textAlignVertical: TextAlignVertical.top,
                textInputAction: TextInputAction.newline,
                maxLines: 20,
                textAlign: TextAlign.start,
                controller: _contentEditingController,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  color: Color(0xffF4F4F4),
                ),
                onChanged: (val) {
                  setState(() {
                    err = false;
                  });
                },
                placeholder: '내용을 입력하세요',
                placeholderStyle: TextStyle(
                    fontFamily: 'NotoSansKR',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color(0xffD1D1D1)
                ),
                padding: EdgeInsets.only(left: 20, top: 20),
              )
          ),
          Visibility(
              visible: err,
              child: Container(
                alignment: Alignment.centerLeft,
                margin: EdgeInsets.only(left: 20, top: 20),
                child: Text(
                  '입력을 확인해주세요!',
                  style: TextStyle(
                      fontFamily: 'NotoSansKR',
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: Colors.red
                  ),
                ),
              )
          ),
          SizedBox(
            height: _height * 0.25,
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