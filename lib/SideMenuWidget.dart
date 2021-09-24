import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animated_dialog/flutter_animated_dialog.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:online_planner_app/detail/calender/calender_page.dart';
import 'package:online_planner_app/detail/planner/planner_detail.dart';
import 'package:online_planner_app/detail/routine/routine_detail.dart';
import 'package:online_planner_app/main/main_page.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'detail/record/record_detail.dart';
import 'login/login_page.dart';

class SideMenuWidget extends StatelessWidget {
  final String tier;
  const SideMenuWidget({required this.tier});

  _showTaost(String message) {
    return Fluttertoast.showToast(
        msg: message,
        textColor: Colors.black,
        backgroundColor: Colors.grey,
        gravity: ToastGravity.BOTTOM,
        fontSize: 15
    );
  }

  _logout(BuildContext context) async {
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
  }

  @override
  Widget build(BuildContext context) {
    var _height = MediaQuery
        .of(context)
        .size
        .height;
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.only(top: 10),
                  child: Image.asset('assets/images/splash.png'),
                  width: 75,
                ),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(top: 20),
                    child: Text(
                      '온라인 플래너',
                      style: TextStyle(
                        fontFamily: 'NotoSansKR',
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                        color: Color(0xff2C2C2C),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              ],
            ),
          ),
          ListTile(
            title: Text(
              '메인 메뉴',
              style: TextStyle(
                  fontFamily: 'NotoSansKR',
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  color: Color(0xff2F5DFB)
              ),
            ),
            leading: Icon(
              Icons.home,
              size: 20,
              color: Color(0xff2F5DFB),
            ),
            onTap: () {
              Navigator.of(context).pushAndRemoveUntil(
                  PageTransition(
                      child: MainPage.init(tier),
                      type: PageTransitionType.bottomToTop
                  ),
                      (route) => false
              );
            },
          ),
          ListTile(
            title: Text(
              '달력',
              style: TextStyle(
                  fontFamily: 'NotoSansKR',
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  color: Color(0xff2C2C2C)
              ),
            ),
            leading: Icon(
              Icons.event_note_rounded,
              size: 20,
              color: Color(0xff2C2C2C),
            ),
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                PageTransition(
                  child: CalenderPage(tier),
                  type: PageTransitionType.bottomToTop
                ),
                 (route) => false
              );
            },
          ),
          ListTile(
            title: Text(
              '할 일',
              style: TextStyle(
                fontFamily: 'NotoSansKR',
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: Color(0xff2C2C2C),
              ),
            ),
            leading: Icon(
              Icons.check,
              size: 20,
              color: Color(0xff2C2C2C),
            ),
            onTap: () {
              Navigator.pushAndRemoveUntil(
                  context,
                  PageTransition(
                      child: PlannerPage(tier, DateFormat("yyyy-MM-dd").format(DateTime.now())),
                      type: PageTransitionType.bottomToTop
                  ),
                  (route) => false
              );
            },
          ),
          ListTile(
            title: Text(
              '기록',
              style: TextStyle(
                fontFamily: 'NotoSansKR',
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: Color(0xff2C2C2C),
              ),
            ),
            leading: Icon(
              Icons.sticky_note_2,
              size: 20,
              color: Color(0xff2C2C2C),
            ),
            onTap: () {
              Navigator.pushAndRemoveUntil(
                  context,
                  PageTransition(
                      child: RecordPage(tier, DateFormat("yyyy-MM-dd").format(DateTime.now())),
                      type: PageTransitionType.bottomToTop
                  ),
                      (route) => false
              );
            },
          ),
          ListTile(
            title: Text(
              '루틴',
              style: TextStyle(
                fontFamily: 'NotoSansKR',
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: Color(0xff2C2C2C),
              ),
            ),
            leading: Icon(
              Icons.replay,
              size: 20,
              color: Color(0xff2C2C2C),
            ),
            onTap: () {
              Navigator.pushAndRemoveUntil(
                  context,
                  PageTransition(
                      child: RoutinePage(tier),
                      type: PageTransitionType.bottomToTop
                  ),
                      (route) => false
              );
            },
          ),
          SizedBox(
            height: _height * 0.38,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                margin: EdgeInsets.only(right: 20, bottom: 10),
                child: RaisedButton(
                  onPressed: () {
                    showAnimatedDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) {
                          return ClassicGeneralDialogWidget(
                            titleText: '로그아웃',
                            contentText: '정말 로그아웃 하시겠습니까?',
                            onPositiveClick: () {
                              _showTaost('로그아웃 되었습니다!');
                              _logout(context);
                              Navigator.of(context).pop();
                            },
                            onNegativeClick: () {
                              _showTaost('취소');
                              Navigator.of(context).pop();
                            },
                            positiveText: '네..',
                            negativeText: '아니요!',
                            negativeTextStyle: TextStyle(
                                color: Colors.red,
                                fontFamily: 'NotoSansKR',
                                fontWeight: FontWeight.w500,
                                fontSize: 16
                            ),
                            positiveTextStyle: TextStyle(
                                color: Color(0xff2F5DFB),
                                fontFamily: 'NotoSansKR',
                                fontWeight: FontWeight.w500,
                                fontSize: 16
                            ),
                          );
                        }
                    );
                  },
                  color: Color(0xff2F5DFB),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)
                  ),
                  child: Center(
                    child: Text(
                      '로그아웃',
                      style: TextStyle(
                        fontFamily: 'NotoSansKR',
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                        color: Color(0xffffffff),
                      ),
                    ),
                  )
                ),
                width: 80,
                height: 30,
              )
            ],
          ),
        ],
      ),
    );
  }
}