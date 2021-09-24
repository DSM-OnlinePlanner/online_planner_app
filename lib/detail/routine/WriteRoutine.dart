import 'dart:convert';
import 'dart:io';

import 'package:bottom_picker/bottom_picker.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import '../../../../login/login_page.dart';

class WriteRoutine extends StatefulWidget {
  _WriteRoutineWidget createState() => _WriteRoutineWidget();
}

class _WriteRoutineWidget extends State<WriteRoutine> {
  bool sun = false, mon = false, tue = false, wed = false, thu = false, fri = false, sat = false,
  initSun = false, initMon = false, initTue = false, initWed = false, initThu = false, initFri = false, initSat = false;

  List<String> weeks = [];

  bool isPushed = false, err = false;

  String priority = "", title = '', content = '';

  String startDate = DateFormat("HH:mm:ss").format(DateTime.now()).toString();
  String endDate = DateFormat("HH:mm:ss").format(DateTime.now()).toString();

  TextEditingController _titleEditingController = TextEditingController();
  TextEditingController _contentEditingController = TextEditingController();

  final String url = 'http://220.90.237.33:7070';

  bool a = false, b = false, c = false, d = false, e = false;

  Color ac = Color(0xff585858),
      bc = Color(0xff585858),
      cc = Color(0xff585858),
      dc = Color(0xff585858),
      ec = Color(0xff585858);
  
  Color sunC = Color(0xff585858),
      monC = Color(0xff585858),
      tueC = Color(0xff585858),
      wedC = Color(0xff585858),
      thuC = Color(0xff585858),
      friC = Color(0xff585858),
      satC = Color(0xff585858);

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

  _setColor() {
    if(sun) {
      if(!initSun)
        weeks.add('일');

      setState(() {
        sunC = Color(0xff2F5DFB);
      });
      initSun = true;
    }else {
      initSun = false;
      weeks.remove('일');
      setState(() {
        sunC = Color(0xff585858);
      });
    }
    if(mon) {
      if(!initMon)
        weeks.add('월');

      setState(() {
        monC = Color(0xff2F5DFB);
      });
      initMon = true;
    }else {
      weeks.remove('월');
      setState(() {
        monC = Color(0xff585858);
      });
      initMon = false;
    }
    if(tue) {
      if(!initTue)
        weeks.add('화');

      setState(() {
        tueC = Color(0xff2F5DFB);
      });
      initTue = true;
    }else {
      weeks.remove('화');
      setState(() {
        tueC = Color(0xff585858);
      });
      initTue = false;
    }
    if(wed) {
      if(!initWed)
        weeks.add('수');

      setState(() {
        wedC = Color(0xff2F5DFB);
      });
      initWed = true;
    }else {
      weeks.remove('수');
      setState(() {
        wedC = Color(0xff585858);
      });
      initWed = false;
    }
    if(thu) {
      if(!initThu)
        weeks.add('목');

      setState(() {
        thuC = Color(0xff2F5DFB);
      });
      initThu = true;
    }else {
      weeks.remove('목');
      setState(() {
        thuC = Color(0xff585858);
      });
      initThu = false;
    }
    if(fri) {
      if(!initFri)
        weeks.add('금');
      setState(() {
        friC = Color(0xff2F5DFB);
      });
      initFri = true;
    }else {
      weeks.remove('금');
      setState(() {
        friC = Color(0xff585858);
      });
    }
    if(sat) {
      if(!initSat)
        weeks.add('토');
      setState(() {
        satC = Color(0xff2F5DFB);
      });
      initSat = true;
    }else {
      weeks.remove('토');
      setState(() {
        satC = Color(0xff585858);
      });
      initSat = false;
    }
  }

  _postRoutine() async {
    SharedPreferences _preference = await SharedPreferences.getInstance();
    print(jsonEncode(weeks));

    print(startDate + ' ' + endDate);

    try {
      Dio dio = Dio();
      final response = await dio.post(
        url + '/routine',
        options: Options(
          headers: {
            HttpHeaders.authorizationHeader: _preference.getString('accessToken') ?? ""
          }
        ),
        data: jsonEncode(
          <String, dynamic> {
            'title' : title,
            'content' : content,
            'weeks' : weeks,
            'startTime' : startDate,
            'endTime' : endDate,
            'priority' : priority,
            'pushed' : isPushed
          }
        )
      );

      if(response.statusCode == 200) {
        _showTaost('루틴 작성이 완료되었습니다');

        Navigator.pop(context);
      }
    }catch(e) {
      await _retryPostRoutine();
    }
  }

  _retryPostRoutine() async {
    SharedPreferences _preference = await SharedPreferences.getInstance();
    print(jsonEncode(weeks));

    await _refreshToken();
    try {
      Dio dio = Dio();
      final response = await dio.post(
          url + '/routine',
          options: Options(
              headers: {
                HttpHeaders.authorizationHeader: _preference.getString('accessToken') ?? ""
              }
          ),
          data: jsonEncode(
              <String, dynamic> {
                'title' : title,
                'content' : content,
                'weeks' : jsonEncode(weeks),
                'startTime' : startDate,
                'endTime' : endDate,
                'priority' : priority,
                'pushed' : isPushed
              }
          )
      );

      if(response.statusCode == 200) {
        _showTaost('루틴 작성이 완료되었습니다');

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

  _showTaost(String message) {
    return Fluttertoast.showToast(
        msg: message,
        textColor: Colors.black,
        backgroundColor: Colors.grey,
        gravity: ToastGravity.BOTTOM,
        fontSize: 15
    );
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

    }
  }

  @override
  Widget build(BuildContext context) {
    var _height = MediaQuery.of(context).size.height;
    var _width = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
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
                  '루틴 추가',
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

                    if(title.isEmpty || priority.isEmpty || weeks.isEmpty) {
                      setState(() {
                        err = true;
                      });
                      return;
                    }

                    _postRoutine();
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
                        '요일',
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
                    child: TextButton(
                      onPressed: () {
                        mon = !mon;
                        _setColor();
                      },
                      child: Text(
                        '월',
                        style: TextStyle(
                            fontFamily: 'NotoSansKR',
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: monC
                        ),
                      ),
                    ),
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 30,
                    child: TextButton(
                      onPressed: () {
                        tue = !tue;
                        _setColor();
                      },
                      child: Text(
                        '화',
                        style: TextStyle(
                            fontFamily: 'NotoSansKR',
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: tueC
                        ),
                      ),
                    ),
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 30,
                    child: TextButton(
                      onPressed: () {
                        wed = !wed;
                        _setColor();
                      },
                      child: Text(
                        '수',
                        style: TextStyle(
                            fontFamily: 'NotoSansKR',
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: wedC
                        ),
                      ),
                    ),
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 30,
                    child: TextButton(
                      onPressed: () {
                        thu = !thu;
                        _setColor();
                      },
                      child: Text(
                        '목',
                        style: TextStyle(
                            fontFamily: 'NotoSansKR',
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: thuC
                        ),
                      ),
                    ),
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 30,
                    child: TextButton(
                      onPressed: () {
                        fri = !fri;
                        _setColor();
                      },
                      child: Text(
                        '금',
                        style: TextStyle(
                            fontFamily: 'NotoSansKR',
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: friC
                        ),
                      ),
                    ),
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 30,
                    child: TextButton(
                      onPressed: () {
                        sat = !sat;
                        _setColor();
                      },
                      child: Text(
                        '토',
                        style: TextStyle(
                            fontFamily: 'NotoSansKR',
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: satC
                        ),
                      ),
                    ),
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    margin: EdgeInsets.only(right: 20),
                    width: 30,
                    child: TextButton(
                      onPressed: () {
                        sun = !sun;
                        _setColor();
                      },
                      child: Text(
                        '일',
                        style: TextStyle(
                            fontFamily: 'NotoSansKR',
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: sunC
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
                        '시작시간',
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
                      height: 40,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          color: Color(0xffF4F4F4)),
                      child: TextButton(
                        onPressed: () {
                          BottomPicker.time(
                            title: '시작시간 선택',
                            titleStyle: TextStyle(
                                fontFamily: 'NotoSansKR',
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                color: Color(0xff2C2C2C)),
                            onSubmit: (val) {
                              setState(() {
                                startDate = DateFormat("HH:mm:ss").format(val);
                              });
                            },
                            onClose: () {},
                            initialDateTime: DateTime.now(),
                            use24hFormat: true,
                          ).show(context);
                        },
                        child: Text(
                          startDate,
                          style: TextStyle(
                              fontFamily: 'NotoSansKR',
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: Color(0xff2C2C2C)),
                        ),
                      ))
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
                        '끝낼시간',
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
                    height: 40,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          color: Color(0xffF4F4F4)
                      ),
                      child: TextButton(
                        onPressed: () {
                          BottomPicker.time(
                            title: '끝낼시간 선택',
                            titleStyle: TextStyle(
                                fontFamily: 'NotoSansKR',
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                color: Color(0xff2C2C2C)),
                            onSubmit: (val) {
                              setState(() {
                                endDate = DateFormat("HH:mm:ss").format(val);
                              });
                            },
                            onClose: () {},
                            initialDateTime: DateTime.now(),
                            use24hFormat: true,
                          ).show(context);
                        },
                        child: Text(
                          endDate,
                          style: TextStyle(
                              fontFamily: 'NotoSansKR',
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: Color(0xff2C2C2C)
                          ),
                        ),
                      )
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