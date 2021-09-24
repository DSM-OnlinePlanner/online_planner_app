import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:f_datetimerangepicker/f_datetimerangepicker.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:page_transition/page_transition.dart';
import 'package:roundcheckbox/roundcheckbox.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../login/login_page.dart';


class WritePlannerWidget extends StatefulWidget {

  @override
  _WritePlannerWidgetState createState() => _WritePlannerWidgetState();
}

String format = "yyyy년 MM월 dd일 HH:mm";


String postStart = "";
String postEnd = "";

class _WritePlannerWidgetState extends State<WritePlannerWidget> {
  String startDate = DateFormat("yyyy.MM.dd HH:mm").format(DateTime.now()).toString();
  String endDate = DateFormat("yyyy.MM.dd HH:mm").format(DateTime.now()).toString();

  _showTaost(String message) {
    return Fluttertoast.showToast(
        msg: message,
        textColor: Colors.black,
        backgroundColor: Colors.grey,
        gravity: ToastGravity.BOTTOM,
        fontSize: 15
    );
  }

  String title = "", content = "", priority = "", want = "";

  bool a = false, b = false, c = false, d = false, e = false,
  one = false, two = false, three = false, four = false, five = false,
  isPushed = false, err = false;

  final String url = 'http://220.90.237.33:7070';

  TextEditingController _titleEditingController = TextEditingController();
  TextEditingController _contentEditingController = TextEditingController();

  Color ac = Color(0xff585858),
      bc = Color(0xff585858), 
      cc = Color(0xff585858), 
      dc = Color(0xff585858), 
      ec = Color(0xff585858);

  _setCheckPrority() {
    if(a) {
      setState(() {
        ac = Color(0xff2F5DFB);
        bc = Color(0xff585858);
        cc = Color(0xff585858);
        dc = Color(0xff585858);
        ec = Color(0xff585858);
      });
    }else if(b) {
      setState(() {
        bc = Color(0xff2F5DFB);
        ac = Color(0xff585858);
        cc = Color(0xff585858);
        dc = Color(0xff585858);
        ec = Color(0xff585858);
      });
    }else if(c) {
      setState(() {
        cc = Color(0xff2F5DFB);
        bc = Color(0xff585858);
        ac = Color(0xff585858);
        dc = Color(0xff585858);
        ec = Color(0xff585858);
      });
    }else if(d) {
      setState(() {
        dc = Color(0xff2F5DFB);
        bc = Color(0xff585858);
        cc = Color(0xff585858);
        ac = Color(0xff585858);
        ec = Color(0xff585858);
      });
    }else if(e) {
      setState(() {
        ec = Color(0xff2F5DFB);
        bc = Color(0xff585858);
        cc = Color(0xff585858);
        dc = Color(0xff585858);
        ac = Color(0xff585858);
      });
    }
  }

  _postPlanner() async {
    SharedPreferences _preference = await SharedPreferences.getInstance();
    String start = _preference.getString('startDate') ?? DateFormat('yyyy.MM.dd HH:mm:ss').format(DateTime.now());
    String end = _preference.getString('endDate') ?? DateFormat('yyyy.MM.dd HH:mm:ss').format(DateTime.now());

    print(start.substring(0, 4) + '-' + start.substring(5, 7) + '-' + start.substring(8, 10));
    print(end.substring(0, 4) + '-' + end.substring(5, 7) + '-' + end.substring(8, 10));

    print(isPushed);

    try {
      Dio dio = Dio();
      final response = await dio.post(
        url + '/planner',
        options: Options(
          headers: {
            HttpHeaders.authorizationHeader: _preference.getString('accessToken') ?? ""
          }
        ),
        data: jsonEncode(
          <String, dynamic> {
            'title' : title,
            'content' : content,
            'priority' : priority,
            'want' : want,
            'startDate' : start.substring(0, 4) + '-' + start.substring(5, 7) + '-' + start.substring(8, 10),
            'endDate' : end.substring(0, 4) + '-' + end.substring(5, 7) + '-' + end.substring(8, 10),
            'startTime' : start.substring(11),
            'endTime' : end.substring(11),
            'isPushed' : isPushed
          }
        )
      );

      _preference.remove('startDate');
      _preference.remove('endDate');

      if(response.statusCode == 200) {
        _showTaost('할 일이 작성되었습니다!');
        Navigator.pop(context);
      }
    }catch(e) {
      await _retryPostPlanner();
    }
  }

  _retryPostPlanner() async {
    SharedPreferences _preference = await SharedPreferences.getInstance();
    print(startDate.substring(0, 4) + '-' + startDate.substring(5, 7) + '-' + startDate.substring(8, 10));
    print(endDate.substring(0, 4) + '-' + startDate.substring(5, 7) + '-' + startDate.substring(8, 10));
    await _refreshToken();

    try {
      Dio dio = Dio();
      final response = await dio.post(
          url + '/planner',
          options: Options(
              headers: {
                HttpHeaders.authorizationHeader: _preference.getString('accessToken') ?? ""
              }
          ),
          data: jsonEncode(
              <String, dynamic> {
                'title' : title,
                'content' : content,
                'priority' : priority,
                'want' : want,
                'startDate' : startDate.substring(0, 4) + '-' + startDate.substring(5, 7) + '-' + startDate.substring(8, 10),
                'endDate' : endDate.substring(0, 4) + '-' + startDate.substring(5, 7) + '-' + startDate.substring(8, 10),
                'startTime' : startDate.substring(11) + ":00",
                'endTime' : endDate.substring(11) + ':00',
                'isPushed' : isPushed
              }
          )
      );

      if(response.statusCode == 200) {
        _showTaost('할 일이 작성되었습니다!');
        Navigator.pop(context);
      }
    }catch(e) {
      _preference.remove("isAuth");
      _preference.remove("accessToken");
      _preference.remove("refreshToken");
      _preference.remove("userImage");

      Navigator.of(context).pushAndRemoveUntil(
          PageTransition(
              child: StartPage(),
              type: PageTransitionType.bottomToTop
          ),
              (route) => false
      );
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
                  '힐 일 추가',
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
                    title = _titleEditingController.text;
                    content = _contentEditingController.text;

                    print(isPushed);

                    if(title.isEmpty || priority.isEmpty || want.isEmpty || startDate.isEmpty || endDate.isEmpty) {
                      setState(() {
                        err = true;
                      });
                      return;
                    }

                    _postPlanner();
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
                    margin: EdgeInsets.only(top: 5, right: 20),
                    child: TextButton(
                      onPressed: () {
                        DateTimeRangePicker(
                            startText: "시작시간",
                            endText: "끝낼시간",
                            doneText: "확인",
                            cancelText: "취소",
                            interval: 5,
                            initialStartTime: DateTime.now(),
                            initialEndTime: DateTime.now(),
                            mode: DateTimeRangePickerMode.dateAndTime,
                            minimumTime: DateTime(2000),
                            maximumTime: DateTime(2100),
                            use24hFormat: true,
                            onConfirm: (start, end) async {
                              print('$start ~ $end');

                              SharedPreferences _preferences = await SharedPreferences.getInstance();

                              setState(() {
                                postStart = DateFormat("yyyy.MM.dd HH:mm").format(start).toString();
                                postEnd = DateFormat("yyyy.MM.dd HH:mm").format(end).toString();
                                startDate = DateFormat("yyyy.MM.dd HH:mm").format(start).toString();
                                endDate = DateFormat("yyyy.MM.dd HH:mm").format(end).toString();
                              });

                              _preferences.setString("startDate", DateFormat("yyyy.MM.dd HH:mm").format(start).toString());
                              _preferences.setString("endDate", DateFormat("yyyy.MM.dd HH:mm").format(end).toString());
                            },
                        ).showPicker(context);
                      },
                      child: Text(
                        '$startDate ~ $endDate',
                        style: TextStyle(
                            fontFamily: 'NotoSansKR',
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Color(0xff585858)
                        ),
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
                      margin: EdgeInsets.only(left: 20),
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
              Container(
                width: 30,
                margin: EdgeInsets.only(),
                child: TextButton(
                  onPressed: () {
                    priority = 'A';
                    a = true;
                    b = false;
                    c = false;
                    d = false;
                    e = false;
                    setState(() {
                      err = false;
                    });
                    _setCheckPrority();
                  },
                  child: Text(
                    'A',
                    style: TextStyle(
                        fontFamily: 'NotoSansKR',
                        fontWeight: FontWeight.normal,
                        fontSize: 18,
                        color: ac
                    ),
                  ),
                ),
              ),
              Container(
                width: 30,
                margin: EdgeInsets.only(),
                child: TextButton(
                  onPressed: () {
                    priority = 'B';
                    b = true;
                    a = false;
                    c = false;
                    d = false;
                    e = false;
                    setState(() {
                      err = false;
                    });
                    _setCheckPrority();
                  },
                  child: Text(
                    'B',
                    style: TextStyle(
                        fontFamily: 'NotoSansKR',
                        fontWeight: FontWeight.normal,
                        fontSize: 18,
                        color: bc
                    ),
                  ),
                ),
              ),
              Container(
                width: 30,
                margin: EdgeInsets.only(),
                child: TextButton(
                  onPressed: () {
                    priority = 'C';
                    c = true;
                    b = false;
                    a = false;
                    d = false;
                    e = false;
                    setState(() {
                      err = false;
                    });
                    _setCheckPrority();
                  },
                  child: Text(
                    'C',
                    style: TextStyle(
                        fontFamily: 'NotoSansKR',
                        fontWeight: FontWeight.normal,
                        fontSize: 18,
                        color: cc
                    ),
                  ),
                ),
              ),
              Container(
                width: 30,
                margin: EdgeInsets.only(),
                child: TextButton(
                  onPressed: () {
                    priority = 'D';
                    d = true;
                    b = false;
                    c = false;
                    a = false;
                    e = false;
                    setState(() {
                      err = false;
                    });
                    _setCheckPrority();
                  },
                  child: Text(
                    'D',
                    style: TextStyle(
                        fontFamily: 'NotoSansKR',
                        fontWeight: FontWeight.normal,
                        fontSize: 18,
                        color: dc
                    ),
                  ),
                ),
              ),
              Container(
                width: 30,
                margin: EdgeInsets.only(right: 20),
                child: TextButton(
                  onPressed: () {
                    priority = 'E';
                    e = true;
                    b = false;
                    c = false;
                    d = false;
                    a = false;
                    setState(() {
                      err = false;
                    });
                    _setCheckPrority();
                  },
                  child: Text(
                    'E',
                    style: TextStyle(
                        fontFamily: 'NotoSansKR',
                        fontWeight: FontWeight.normal,
                        fontSize: 18,
                        color: ec
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
                      margin: EdgeInsets.only(top: 10, left: 20),
                      child: Text(
                        '선호도',
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
                    width: 30,
                    height: 30,
                    margin: EdgeInsets.only(top: 7, right: 10),
                    child: RoundCheckBox(
                      isChecked: one,
                      onTap: (value) {
                        one = value!;
                        if(value) {
                          want = 'ONE';
                          setState(() {
                            one = value;
                            two = !value;
                            three = !value;
                            four = !value;
                            five = !value;
                            err = false;
                          });
                        }else {
                          want = '';
                        }
                      },
                      uncheckedColor: Color(0xffFF4631),
                      borderColor: Color(0xffFFFFFF),
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                      color: Color(0xffFF4631),
                    ),
                  ),
                  Container(
                    width: 30,
                    height: 30,
                    margin: EdgeInsets.only(top: 7, right: 10),
                    child: RoundCheckBox(
                      isChecked: two,
                      onTap: (value) {
                        two = value!;
                        if(value) {
                          want = 'TWO';
                          setState(() {
                            one = !value;
                            three = !value;
                            four = !value;
                            five = !value;
                            err = false;
                          });
                        }else {
                          want = '';
                        }
                      },
                      uncheckedColor: Color(0xffFF974B),
                      borderColor: Color(0xffFFFFFF),
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                      color: Color(0xffFF974B),
                    ),
                  ),
                  Container(
                    width: 30,
                    height: 30,
                    margin: EdgeInsets.only(top: 7, right: 10),
                    child: RoundCheckBox(
                      isChecked: three,
                      onTap: (value) {
                        three = value!;
                        if(value) {
                          want = 'THREE';
                          setState(() {
                            two = !value;
                            one = !value;
                            four = !value;
                            five = !value;
                            err = false;
                          });
                        }else {
                          want = '';
                        }
                      },
                      uncheckedColor: Color(0xffFEBA2B),
                      borderColor: Color(0xffFFFFFF),
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                      color: Color(0xffFEBA2B),
                    ),
                  ),
                  Container(
                    width: 30,
                    height: 30,
                    margin: EdgeInsets.only(top: 7, right: 10),
                    child: RoundCheckBox(
                      isChecked: four,
                      onTap: (value) {
                        four = value!;
                        if(value) {
                          want = 'FOUR';
                          setState(() {
                            two = !value;
                            three = !value;
                            one = !value;
                            five = !value;
                            err = false;
                          });
                        }else {
                          want = '';
                        }
                      },
                      uncheckedColor: Color(0xff1BB778),
                      borderColor: Color(0xffFFFFFF),
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                      color: Color(0xff1BB778),
                    ),
                  ),
                  Container(
                    width: 30,
                    height: 30,
                    margin: EdgeInsets.only(top: 7, right: 20),
                    child: RoundCheckBox(
                      isChecked: five,
                      onTap: (value) {
                        five = value!;
                        if(value) {
                          want = 'FIVE';
                          setState(() {
                            two = !value;
                            three = !value;
                            four = !value;
                            one = !value;
                            err = false;
                          });
                        }else {
                          want = '';
                        }
                      },
                      uncheckedColor: Color(0xff2F5DFB),
                      borderColor: Color(0xffFFFFFF),
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                      color: Color(0xff2F5DFB),
                    ),
                  ),
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
                      margin: EdgeInsets.only(top: 10, left: 20),
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
                    margin: EdgeInsets.only(top: 10, right: 20),
                    child: CupertinoSwitch(
                      value: isPushed,
                      onChanged: (bool value) {
                        setState(() {
                          err = false;
                          isPushed = value;
                        });
                      },
                    ),
                  )
                ],
              ),
            ],
          ),
          Container(
              width: _width * 0.871,
              height: 45,
              margin: EdgeInsets.only(top: 20),
              child: CupertinoTextField(
                textInputAction: TextInputAction.next,
                textAlign: TextAlign.start,
                controller: _titleEditingController,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  color: Color(0xffF4F4F4),
                ),
                maxLength: 20,
                maxLines: 1,
                onChanged: (val) {
                  setState(() {
                    err = false;
                  });
                },
                placeholder: '제목을 입력하세요',
                placeholderStyle: TextStyle(
                    fontFamily: 'NotoSansKR',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color(0xffD1D1D1)
                ),
                padding: EdgeInsets.only(left: 20),
              )
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
                placeholder: '내용을 입력하세요(선택)',
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