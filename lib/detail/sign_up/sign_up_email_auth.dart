import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:online_planner_app/detail/sign_up/sign_up_detail.dart';
import 'package:online_planner_app/login/login_page.dart';
import 'package:page_transition/page_transition.dart';
import 'package:timer_count_down/timer_controller.dart';
import 'package:timer_count_down/timer_count_down.dart';

class SignUpEmailAuthPage extends StatefulWidget {
  late String email, password, nickName;

  SignUpEmailAuthPage();
  SignUpEmailAuthPage.init(this.email, this.password, this.nickName);

  _SignUpEmailAuthWidget createState() => _SignUpEmailAuthWidget(email, password, nickName);
}

class _SignUpEmailAuthWidget extends State<SignUpEmailAuthPage> {
  _SignUpEmailAuthWidget(this.email, this.password, this.nickName) {
    _countdownController.start();
  }

  String email, password, nickName;

  String code = "";

  TextEditingController _authCodeController = TextEditingController();

  CountdownController _countdownController = CountdownController();

  bool _isSignUp = false;
  bool _isAuthed = false;

  bool _authCodeVisible = false;

  void _showAuthVisible() {
    setState(() {
      _authCodeVisible = true;
    });
  }

  void _hideAuthVisible() {
    setState(() {
      _authCodeVisible = false;
    });
  }

  _showTaost(String message) {
    return Fluttertoast.showToast(
        msg: message,
        textColor: Colors.black54,
        backgroundColor: Colors.grey,
        gravity: ToastGravity.BOTTOM,
        fontSize: 15
    );
  }

  final String url = 'http://220.90.237.33:7070';

  _putEmail() async {
    var dio = Dio();
    final response = await dio.put(
      url + "/mail",
      queryParameters: {
        "email" : email,
        "name" : nickName
      }
    );

    if(response.statusCode == 200) {
      _showTaost("이메일 다시을 보냈습니다!");
      _countdownController.restart();
    }
    else {
      _showTaost("이메일을 보내지 못했습니다.");
    }
  }

  _postAuth() async {
    var dio = Dio();
    final response = await dio.post(
      url + "/mail/auth",
      options: Options(
            headers: {
              HttpHeaders.contentTypeHeader : "application/json"
            }
        ),
      data: jsonEncode(
        <String, String> {
          "email" : email,
          "code" : code
        }
      )
    );

    if(response.statusCode == 200) {
      _postSignUp();
    }else {
      _showAuthVisible();
      _authCodeController.clear();
    }
  }

  _postSignUp() async {
    var dio = Dio();
    final response = await dio.post(
        url + "/user",
        options: Options(
            headers: {
              HttpHeaders.contentTypeHeader: "application/json"
            }
        ),
        data: jsonEncode(
            <String, String> {
              "email" : email,
              "password" : password,
              "nickName" : nickName
            }
        )
    );

    if(response.statusCode == 200) {
      _showTaost("회원가입이 완료되었습니다!");

      Navigator.pop(
          context,
          PageTransition(
              type: PageTransitionType.topToBottom,
              child: StartPage()
          )
      );
    }else {
      _showTaost("회원가입을 실패했습니다.");

      Navigator.of(context).pop();

      Navigator.of(context).push(
          PageTransition(
              type: PageTransitionType.bottomToTop,
              child: SignUpDetailPage()
          )
      );
    }
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
          children: [
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
                      ),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.only(top: 15, left: 20),
                  child: IconButton(
                      icon: Icon(Icons.arrow_back_ios),
                      onPressed: () {
                        print(email + password + nickName);

                        Navigator.of(context).pop();

                        Navigator.push(
                            context,
                            PageTransition(
                                child: SignUpDetailPage.init(email, password, nickName),
                                type: PageTransitionType.bottomToTop
                            )
                        );
                      },
                      iconSize: 40,
                      color: Color(0xff9B9B9B)
                  ),
                )
              ],
            ),
            Container(
              margin: EdgeInsets.only(top: _height * 0.17, left: _width * 0.061),
              child: Text(
                '이메일 인증',
                style: TextStyle(
                    fontFamily: 'NotoSansKR',
                    fontWeight: FontWeight.w700,
                    fontSize: 36
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                    margin: EdgeInsets.only(top: _height * 0.33, left: _width * 0.064),
                    child: Visibility(
                      visible: _authCodeVisible,
                      child: Text(
                        '인증번호를 입력해주세요!',
                        style: TextStyle(
                            fontFamily: 'NotoSansKR',
                            fontWeight: FontWeight.w700,
                            color: Colors.red,
                            fontSize: 15
                        ),
                      ),
                    )
                )
              ],
            ),
            Stack(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      margin: EdgeInsets.only(top: _height * 0.263),
                      width: _width * 0.876,
                      child: TextField(
                        controller: _authCodeController,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                            hintText: "인증번호를 입력해주세요",
                            hintStyle: TextStyle(
                                fontSize: 18,
                                fontFamily: 'NotoSansKR',
                                fontWeight: FontWeight.normal,
                                color: Color(0xffC4C4C4)
                            ),
                            contentPadding: EdgeInsets.only(left: 10, right: 10)
                        ),
                        onChanged: (value) {
                          _hideAuthVisible();
                        },
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: _height * 0.315, right: _width * 0.064),
                      child: TextButton(
                        onPressed: () {
                          _putEmail();
                        },
                        child: Text(
                          "다시 보내기",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontFamily: 'NotoSnasKR',
                            fontSize: 16,
                            color: Color(0xff2F5DFB),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                        margin: EdgeInsets.only(top: _height * 0.28, right: _width * 0.09),
                        child: Countdown(
                          controller: _countdownController,
                          seconds: 180,
                          build: (_, timer) {
                            _countdownController.start();
                            int minute = 0;
                            if(timer > 60)
                              minute = timer ~/ 60;
                            int second = (timer - minute * 60).toInt();
                            String zeroToSecFormat;
                            if(second == 0) {
                              zeroToSecFormat = "00";
                            }else if(second < 10) {
                              zeroToSecFormat = "0" + second.toString();
                            }else {
                              zeroToSecFormat = second.toString();
                            }
                            return Text(
                              minute.toString() + ":" + zeroToSecFormat,
                              style: TextStyle(
                                  fontSize: 15,
                                  fontFamily: 'NotoSansKR',
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xffC4C4C4)
                              ),
                            );
                          },
                          onFinished: () {
                            print("finished count down");

                            _putEmail();
                          },
                        )
                    ),
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
                          "확인",
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontFamily: 'NotoSansKR',
                              fontSize: 20,
                              color: Colors.white
                          ),
                        ),
                        onPressed: () {
                          code = _authCodeController.text;
                          if(code.isEmpty)
                            _showTaost("인증코드를 입력하세요!");

                          _postAuth();
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
            )
          ],
        ),
      )
    );
  }

}