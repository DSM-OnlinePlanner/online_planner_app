import 'dart:convert';
import 'dart:io';

import 'package:bottom_picker/bottom_picker.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:online_planner_app/main/main_page.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import '../../../../login/login_page.dart';

class UpdateRoutine extends StatefulWidget {
  Routine routine;

  UpdateRoutine(this.routine);

  _UpdateRoutineWidget createState() => _UpdateRoutineWidget(routine);
}

class _UpdateRoutineWidget extends State<UpdateRoutine> {
  bool sun = false, mon = false, tue = false, wed = false, thu = false, fri = false, sat = false,
      initSun = false, initMon = false, initTue = false, initWed = false, initThu = false, initFri = false, initSat = false;

  Routine routine;

  _UpdateRoutineWidget(this.routine);

  List<String> weeks = [];

  bool isPushed = false, err = false;

  String startDate = DateFormat("HH:mm:ss").format(DateTime.now()).toString();
  String endDate = DateFormat("HH:mm:ss").format(DateTime.now()).toString();

  TextEditingController _titleEditingController = TextEditingController();
  TextEditingController _contentEditingController = TextEditingController();

  final String url = 'http://220.90.237.33:7070';

  bool a = false, b = false, c = false, d = false, e = false;

  _updateRoutine() async {
    SharedPreferences _preference = await SharedPreferences.getInstance();
    try {
      Dio dio = Dio();
      final response = await dio.put(
          url + '/routine/' + routine.routineId.toString(),
          options: Options(
              headers: {
                HttpHeaders.authorizationHeader: _preference.getString('accessToken') ?? ""
              }
          ),
          data: <String, dynamic> {
            'title' : routine.title,
            'content' : routine.content
          }
      );

      if(response.statusCode == 200) {
        print(response.data);

        return true;
      }

      return false;
    }catch(e) {
      print('planner ' + e.toString());
      await _retryPlanner();
    }
  }

  _retryPlanner() async {
    await _refreshToken();
    SharedPreferences _preference = await SharedPreferences.getInstance();
    try {
      Dio dio = Dio();
      final response = await dio.put(
          url + '/routine/' + routine.routineId.toString(),
          options: Options(
              headers: {
                HttpHeaders.authorizationHeader: _preference.getString('accessToken') ?? ""
              }
          ),
          data: <String, String> {
            'title' : routine.title,
            'content' : routine.content
          }
      );

      if(response.statusCode == 200) {
        print(response.data);

        return true;
      }

      return false;
    }catch(e) {
      print(e);
      await _logout();
      return false;
    }
  }

  _updatePriority() async {
    SharedPreferences _preference = await SharedPreferences.getInstance();
    try {
      Dio dio = Dio();
      final response = await dio.put(
          url + '/routine/priority/' + routine.routineId.toString(),
          options: Options(
              headers: {
                HttpHeaders.authorizationHeader: _preference.getString('accessToken') ?? ""
              }
          ),
          data: <String, dynamic> {
            'priority' : routine.priority
          }
      );

      if(response.statusCode == 200) {
        print(response.data);
        return true;
      }

      return false;
    }catch(e) {
      print('planner pri' + e.toString());

      await _retryPriority();
    }
  }

  _retryPriority() async {
    await _refreshToken();
    SharedPreferences _preference = await SharedPreferences.getInstance();
    try {
      Dio dio = Dio();
      final response = await dio.put(
          url + '/routine/priority/' + routine.routineId.toString(),
          options: Options(
              headers: {
                HttpHeaders.authorizationHeader: _preference.getString('accessToken') ?? ""
              }
          ),
          data: <String, dynamic> {
            'priority' : routine.priority
          }
      );

      if(response.statusCode == 200) {
        print(response.data);
        return true;
      }
      return false;
    }catch(e) {
      print(e);
      await _logout();
      return false;
    }
  }

  _updateWeek() async {
    SharedPreferences _preference = await SharedPreferences.getInstance();
    try {
      Dio dio = Dio();
      final response = await dio.put(
          url + '/routine/week/' + routine.routineId.toString(),
          options: Options(
              headers: {
                HttpHeaders.authorizationHeader: _preference.getString('accessToken') ?? ""
              }
          ),
          data: <String, dynamic> {
            'dayOfWeeks' : weeks
          }
      );

      if(response.statusCode == 200) {
        print(response.data);
        return true;
      }

      return false;
    }catch(e) {
      print('date ' + e.toString());

      await _retryWeek();
    }
  }

  _retryWeek() async {
    await _refreshToken();
    SharedPreferences _preference = await SharedPreferences.getInstance();
    try {
      Dio dio = Dio();
      final response = await dio.put(
          url + '/routine/week/' + routine.routineId.toString(),
          options: Options(
              headers: {
                HttpHeaders.authorizationHeader: _preference.getString('accessToken') ?? ""
              }
          ),
          data: <String, dynamic> {
            'dayOfWeeks' : weeks
          }
      );

      if(response.statusCode == 200) {
        print(response.data);
      }
    }catch(e) {
      print(e);
      await _logout();
    }
  }

  _updateTime() async {
    SharedPreferences _preference = await SharedPreferences.getInstance();
    try {
      Dio dio = Dio();
      final response = await dio.put(
          url + '/routine/time/' + routine.routineId.toString(),
          options: Options(
              headers: {
                HttpHeaders.authorizationHeader: _preference.getString('accessToken') ?? ""
              }
          ),
          data: <String, dynamic> {
            'startTime' : routine.startTime,
            'endTime' : routine.endTime
          }
      );

      if(response.statusCode == 200) {
        print(response.data);
        return true;
      }

      return false;
    }catch(e) {
      print('time ' + e.toString());

      await _retryTime();
    }
  }

  _retryTime() async {
    await _refreshToken();
    SharedPreferences _preference = await SharedPreferences.getInstance();
    try {
      Dio dio = Dio();
      final response = await dio.put(
          url + '/routine/time/' + routine.routineId.toString(),
          options: Options(
              headers: {
                HttpHeaders.authorizationHeader: _preference.getString('accessToken') ?? ""
              }
          ),
          data: <String, dynamic> {
            'startTime' : routine.startTime,
            'endTime' : routine.endTime
          }
      );

      if(response.statusCode == 200) {
        print(response.data);
        return true;
      }

      return false;
    }catch(e) {
      print(e);

      await _logout();
    }
  }

  _updatePush() async {
    SharedPreferences _preference = await SharedPreferences.getInstance();
    try {
      Dio dio = Dio();
      final response = await dio.put(
          url + '/routine/pushed/' + routine.routineId.toString(),
          options: Options(
              headers: {
                HttpHeaders.authorizationHeader: _preference.getString('accessToken') ?? ""
              }
          ),
      );

      if(response.statusCode == 200) {
        print(response.data);
        return true;
      }

      return false;
    }catch(e) {
      print('push ' + e.toString());

      await _retryPush();
    }
  }

  _retryPush() async {
    await _refreshToken();
    SharedPreferences _preference = await SharedPreferences.getInstance();
    try {
      Dio dio = Dio();
      final response = await dio.put(
        url + '/routine/pushed/' + routine.routineId.toString(),
        options: Options(
            headers: {
              HttpHeaders.authorizationHeader: _preference.getString('accessToken') ?? ""
            }
        ),
      );

      if(response.statusCode == 200) {
        print(response.data);
        return true;
      }

      return false;
    }catch(e) {
      print(e);
      await _logout();
    }
  }

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
  void initState() {
    _titleEditingController.text = routine.title;
    _contentEditingController.text = routine.content;

    routine.dayOfWeeks.forEach((element) {
      if(element == '월') {
        mon = true;
      }else if(element == '화') {
        tue = true;
      }else if(element == '수') {
        wed = true;
      }else if(element == '목') {
        thu = true;
      }else if(element == '금') {
        fri = true;
      }else if(element == '토') {
        sat = true;
      }else {
        sun = true;
      }

      _setColor();
    });

    if(routine.priority == 'A') {
      a = true;
    }else if(routine.priority == 'B') {
      b = true;
    }else if(routine.priority == 'C') {
      c = true;
    }else if(routine.priority == 'D') {
      d = true;
    }else if(routine.priority == 'E') {
      e = true;
    }

    _setCheckPrority();

    super.initState();
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
                  '루틴 수정',
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
                  onPressed: () async {
                    if(routine.title != _titleEditingController.text || routine.content != _contentEditingController.text) {
                      routine.title = _titleEditingController.text;
                      routine.content = _contentEditingController.text;

                      await _updateRoutine();
                    }

                    if(isPushed != routine.isPushed) {
                      _updatePush();
                    }

                    _updateTime();
                    _updatePriority();
                    _updateWeek();

                    _showTaost('수정이 완료되었습니다.');
                    Navigator.pop(context);
                  },
                  child: Text(
                    '수정',
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
                    routine.priority = 'A';
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
                    routine.priority = 'B';
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
                    routine.priority = 'C';
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
                    routine.priority = 'D';
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
                    routine.priority = 'E';
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