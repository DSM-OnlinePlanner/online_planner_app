import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:online_planner_app/login/login_page.dart';
import 'package:page_transition/page_transition.dart';
import 'package:progress_indicators/progress_indicators.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AchievementListPage extends StatefulWidget {
  bool isSuccess;
  AchievementListPage(this.isSuccess);
  
  _AchievementListWidget createState() => _AchievementListWidget(isSuccess);
}

class _AchievementListWidget extends State<AchievementListPage> {
  bool isSuccess;
  late Token token;

  _AchievementListWidget(this.isSuccess);

  FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  late List<Achieve> achieves;
  late Future<List<Achieve>> fAchieve;

  late SharedPreferences _preferences;

  final String url = 'http://220.90.237.33:7070';

  String _getAchieve(String achieve) {
    if(achieve == 'FIRST_PLANNER')
      return '첫 할일 작성하기!';
    else if(achieve == 'FIRST_ROUTINE')
      return '첫 루틴 작성하기!';
    else if(achieve == 'FIRST_MEMO')
      return '첫 메모 작성하기!';
    else if(achieve == 'FIRST_GOAL')
      return '첫 목표 작성하기!';
    else if(achieve == 'PLANNER_10')
      return '할일 10개 작성하기!';
    else if(achieve == 'ROUTINE_10')
      return '루틴 10개 작성하기!';
    else if(achieve == 'SUCCEED_PLANNER')
      return '할일 1개 완료하기!';
    else if(achieve == 'SUCCEED_ROUTINE')
      return '루틴 1개 완료하기!';
    else if(achieve == 'PLANNER_100')
      return '할일 100개 작성하기!';
    else if(achieve == 'ROUTINE_100')
      return '루틴 100개 작성하기!';
    else if(achieve == 'PLANNER_1000')
      return '할일 1000개 작성하기!';
    else if(achieve == 'ROUTINE_1000')
      return '루틴 1000개 작성하기!';
    else if(achieve == 'SUCCEED_PLANNER_10')
      return '할일 10개 완료하기!';
    else if(achieve == 'SUCCEED_ROUTINE_10')
      return '루틴 10개 완료하기!';
    else if(achieve == 'SUCCEED_PLANNER_100')
      return '할일 100개 완료하기!';
    else if(achieve == 'SUCCEED_ROUTINE_100')
      return '루틴 100개 완료하기!';
    else if(achieve == 'SUCCEED_PLANNER_1000')
      return '할일 1000개 완료하기!';
    else if(achieve == 'SUCCEED_ROUTINE_1000')
      return '루틴 1000개 완료하기';
    else if(achieve == 'LV_10')
      return '10LV 달성하기!';
    else if(achieve == 'LV_50')
      return '50LV 달성하기!';
    else if(achieve == 'LV_100')
      return '100LV 달성하기!';
    else
      return '';
  }

  _refreshToken() async {
    _preferences = await SharedPreferences.getInstance();
    Dio dio = Dio();
    try {
      final response = await dio.put(
          url + '/auth',
          options: Options(
              headers: {
                HttpHeaders.contentTypeHeader: 'application/json',
                'X-Refresh-Token': _preferences.getString('refreshToken')
              }
          )
      );

      if (response.statusCode == 200) {
        _preferences = await SharedPreferences.getInstance();

        token = Token.fromJson(response.data);

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

  Future<List<Achieve>> _getAchievement() async {
    _preferences = await SharedPreferences.getInstance();
    try {
      Dio dio = Dio();
      final response = await dio.get(
        url + '/achieve',
        options: Options(
            headers: {
              HttpHeaders.contentTypeHeader: "application/json",
              HttpHeaders.authorizationHeader: _preferences.getString('accessToken') ?? ""
            }
        ),
        queryParameters: {
          'isSucceed' : isSuccess
        }
      );

      print(response.statusCode);

      if(response.statusCode == 200)
        achieves = (response.data as List).map((e) => Achieve.fromJson(e)).toList();

      return achieves;
    }catch(e) {
      print('achieve : ' + e.toString());
      await _retryAchievement();
      
      return achieves;
    }
  }

  _retryAchievement() async {
    await _refreshToken();
    _preferences = await SharedPreferences.getInstance();
    try {
      Dio dio = Dio();
      final response = await dio.get(
          url + '/achievement',
          options: Options(
              headers: {
                HttpHeaders.contentTypeHeader: "application/json",
                "deviceToken": _preferences.getString('deviceToken')
              }
          ),
          queryParameters: {
            'isSucceed' : isSuccess
          }
      );

      print(response.statusCode);

      if(response.statusCode == 200)
        achieves = (response.data as List).map((e) => Achieve.fromJson(e)).toList();
    }catch(e) {
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

  @override
  void initState() {
    fAchieve = _getAchievement();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: FutureBuilder(
        future: fAchieve,
        builder: (context, snapshot) {
          if(snapshot.hasData == false) {
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
          }else if(snapshot.hasError) {
            return _logout();
          }else {
            if(achieves.length == 0) {
              return ListView(
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 100),
                    child: Text(
                      isSuccess ? '완료된 업적이 없습니다.' : '모든 업적이 완료되었습니다.',
                      style: TextStyle(
                          fontFamily: 'NotoSansKR',
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: Color(0xffD1D1D1)
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                ],
              );
            }else {
              return ListView.builder(
                itemCount: achieves.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    key: ObjectKey(achieves[index]),
                    title: Text(
                      _getAchieve(achieves[index].achieve),
                      style: TextStyle(
                          fontFamily: 'NotoSansKR',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xff2C2C2C)
                      ),
                      textAlign: TextAlign.left,
                    ),
                      leading: !achieves[index].achieve.contains('LV')
                          ? Container(
                              child: Image.asset(
                                'assets/images/achieve_check.png',
                                width: 30,
                                height: 30,
                              ),
                            )
                          : Container(
                              child: Image.asset(
                                'assets/images/achieve_level.png',
                                width: 30,
                                height: 30,
                              ),
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

class Achieve {
  int achieveId;
  String achieve, achieveDate, achieveAt;
  bool isSuccess;

  Achieve({required this.achieveId, required this.achieve, required this.achieveDate, required this.achieveAt, required this.isSuccess});

  factory Achieve.fromJson(Map<String, dynamic> json) {
   return Achieve(
     achieveId: json['achieveId'],
     achieve: json['achieve'],
     achieveDate: json['achieveDate'],
     achieveAt: json['achieveAt'],
     isSuccess: json['succeed']
   );
  }
}