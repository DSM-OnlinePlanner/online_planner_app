import 'package:flutter/material.dart';
import 'package:nav/enum/enum_nav_ani.dart';
import 'package:nav/nav.dart';
import 'package:online_planner_app/ui/detail/login/login_detail.dart';
import 'package:page_transition/page_transition.dart';

class StartPage extends StatefulWidget {
  @override
  _StartWidget createState() => _StartWidget();
}

class _StartWidget extends State<StartPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          image: DecorationImage(
              image: AssetImage('assets/images/backround.png'),
              fit: BoxFit.cover
          )
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: ButtonAndTextWidget(),
      ),
    );
  }
}

class ButtonAndTextWidget extends StatefulWidget {
  _ButtonAndTextState createState() => _ButtonAndTextState();
}

class _ButtonAndTextState extends State<ButtonAndTextWidget> {
  @override
  Widget build(BuildContext context) {
    var _height = MediaQuery.of(context).size.height;
    var _width = MediaQuery.of(context).size.width;

    return Container(
      child: Stack(
        children: <Widget> [
          Container(
            child: Text(
              "온라인 플래너로\n하루를 계획하세요!",
              style: TextStyle(
                  fontFamily: 'NotoSansKR',
                  fontWeight: FontWeight.w700,
                  fontSize: 36
              ),
            ),
            margin: EdgeInsets.only(
                top: _height * 0.291,
                left: _width * 0.04
            ),
          ),
          Column(
            children: <Widget>[
              Container(
                margin: EdgeInsets.only(top: _height * 0.73, left: _width * 0.061),
                height: 60,
                width: _width * 343/390,
                child: RaisedButton (
                  child: Text(
                    "로그인",
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontFamily: 'NotoSansKR',
                        fontSize: 20,
                        color: Colors.white
                    ),
                  ),
                  onPressed: () async => {
                    Navigator.push(
                      context,
                      PageTransition(
                        type: PageTransitionType.bottomToTop,
                        child: LoginDetailPage()
                      ),
                    ),
                  },
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)
                  ),
                  color: Color(0xff2F5DFB),
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 20, left: _width * 0.061),
                height: 60,
                width: _width * 343/390,
                child: RaisedButton(
                  child: Text(
                    "회원가입",
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontFamily: 'NotoSansKR',
                        fontSize: 20,
                        color: Colors.black
                    ),
                  ),
                  onPressed: () {},
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)
                  ),
                  color: Color(0xCCF2F2F2),
                ),
              ),
            ],
          ),
        ],
      )
    );
  }
}



