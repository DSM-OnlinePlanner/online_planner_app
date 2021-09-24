import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../login/login_page.dart';


class UpdateMemoWidget extends StatefulWidget {
  int memoId;
  String content;

  UpdateMemoWidget(this.memoId, this.content);

  @override
  _UpdateMemoWidgetState createState() => _UpdateMemoWidgetState(memoId, content);
}

class _UpdateMemoWidgetState extends State<UpdateMemoWidget> {
  int memoId;
  String content;

  _UpdateMemoWidgetState(this.memoId, this.content);

  _showTaost(String message) {
    return Fluttertoast.showToast(
        msg: message,
        textColor: Colors.black,
        backgroundColor: Colors.grey,
        gravity: ToastGravity.BOTTOM,
        fontSize: 15
    );
  }

  bool err = false;

  final String url = 'http://220.90.237.33:7070';

  TextEditingController _contentEditingController = TextEditingController();

  _updateMemo() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    try {
      Dio dio = Dio();
      final response = await dio.put(
        url + '/memo/' + memoId.toString(),
        options: Options(
          headers: {
            HttpHeaders.authorizationHeader: preferences.getString('accessToken') ?? ""
          }
        ),
        data: {
          'updateMemo' : content
        }
      );

      if(response.statusCode == 200) {
        _showTaost('수정되았습니다.');
      }
    }catch(e) {
      await _retryUpdateMemo();
    }
  }

  _retryUpdateMemo() async {
    await _refreshToken();
    SharedPreferences preferences = await SharedPreferences.getInstance();
    try {
      Dio dio = Dio();
      final response = await dio.put(
          url + '/memo/' + memoId.toString(),
          options: Options(
              headers: {
                HttpHeaders.authorizationHeader: preferences.getString('accessToken') ?? ""
              }
          ),
          data: {
            'updateMemo' : content
          }
      );

      if(response.statusCode == 200) {
        _showTaost('수정되았습니다.');
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
  void initState() {
    _contentEditingController.text = content;
    super.initState();
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
                  '메모 수정',
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

                    if(content.isEmpty) {
                      setState(() {
                        err = true;
                      });
                    }

                    _updateMemo();

                    Navigator.pop(context);
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
                placeholder: '내용을 입력하세요.',
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