import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:online_planner_app/detail/sign_up/sign_up_email_auth.dart';
import 'package:online_planner_app/login/login_page.dart';
import 'package:page_transition/page_transition.dart';
import 'package:future_progress_dialog/future_progress_dialog.dart';
import 'package:progress_indicators/progress_indicators.dart';

class SignUpDetailPage extends StatefulWidget {
  String email = "", password = "", checkPassword = "", nickName = "";

  SignUpDetailPage();
  SignUpDetailPage.init(this.email, this.password, this.nickName);

  _SignUpDetailWidget createState() {
    if(email.isEmpty || password.isEmpty || nickName.isEmpty) {
      return _SignUpDetailWidget();
    }else {
      return _SignUpDetailWidget.init(email, password, nickName);
    }
  }
}

class _SignUpDetailWidget extends State<SignUpDetailPage> {
  _SignUpDetailWidget();
  _SignUpDetailWidget.init(this.initEmail, this.initPassword, this.initNickName);

  TextEditingController _emailEditingController = TextEditingController();
  TextEditingController _passwordEditingController = TextEditingController();
  TextEditingController _nickNameEditingController = TextEditingController();
  TextEditingController _passwordCheckController = TextEditingController();

  String email = "", password = "", nickName = "", chkPassword = "";
  String initEmail = "", initPassword = "", initNickName = "";

  final String url = 'http://220.90.237.33:7070';

  bool _passwordVisible = false;

  bool _passwordGreenVisible = false;
  bool _passwordCheckRedVisible = false;

  bool _passwordValidationVisible = false;

  bool _emailValidationVisible = false;
  bool _emailCheckVisible = false;

  void showEmail() {
    setState(() {
      _emailValidationVisible = true;
    });
  }

  void hideEmail() {
    setState(() {
      _emailValidationVisible = false;
    });
  }

  void showPasswordVisible() {
    setState(() {
      _passwordVisible = true;
    });
  }

  void hidePasswordVisible() {
    setState(() {
      _passwordVisible = false;
    });
  }

  void showPasswordCheckVisible() {
    setState(() {
      _passwordCheckRedVisible = true;
    });

  }

  void showPasswordCheckGreen() {
    setState(() {
      _passwordGreenVisible = true;
    });
  }

  void hidePasswordCheckVisible() {
    setState(() {
      _passwordCheckRedVisible = false;
    });
  }

  void hidePasswordCheckGreen() {
    setState(() {
      _passwordGreenVisible = false;
    });
  }

  void showPasswordVaildationVisible() {
    setState(() {
      _passwordValidationVisible = true;
    });
  }

  void hidePasswordVailationVisible() {
    setState(() {
      _passwordValidationVisible = false;
    });
  }

  void showEmailCheck() {
    setState(() {
      _emailCheckVisible = true;
    });
  }

  void hideEmailCehck() {
    setState(() {
      _emailCheckVisible = false;
    });
  }

  Future<bool> _postEmail() async {
    try {
      var dio = Dio();
      print(url + "/mail?email=" + email + "&name=" + nickName);
      final response = await dio.post(
          url + "/mail",
          queryParameters: {
            "email" : email,
            "name" : nickName
          }
      );

      if(response.statusCode == 200) {
        Navigator.pop(context);

        Navigator.push(
          context,
          PageTransition(
              child: SignUpEmailAuthPage.init(email, password, nickName),
              type: PageTransitionType.rightToLeft
          )
        );

        return true;
      }else {
        _showTaost("???????????? ????????? ???????????????");

        return false;
      }
    }catch(e) {
      return false;
    }
  }

  _showTaost(String message) {
    return Fluttertoast.showToast(
        msg: message,
        textColor: Colors.black,
        backgroundColor: Colors.white10,
        gravity: ToastGravity.BOTTOM,
        fontSize: 15
    );
  }

  bool _passwordValidDate(String value) {
    RegExp regExp = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[$@$!%*#?~^<>,.&+=])[A-Za-z\d$@$!%*#?~^<>,.&+=]{8,20}$');
    print(regExp.hasMatch(value));
    return regExp.hasMatch(value);
  }

  bool _emailValidate(String email) {
    RegExp regExp = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
    print(regExp.hasMatch(email));
    return regExp.hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    var _height = MediaQuery.of(context).size.height;
    var _width = MediaQuery.of(context).size.width;

    if(initEmail.isNotEmpty && initNickName.isNotEmpty && initPassword.isNotEmpty) {
        _emailEditingController.text = initEmail;
        _passwordEditingController.text = initPassword;
        _nickNameEditingController.text = initNickName;

        initEmail = "";
        initNickName = "";
        initPassword = "";
    }

    return Scaffold(
      backgroundColor: Color(0xffF4F4F4),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Color(0xffFBFBFB),
        toolbarHeight: 0,
      ),
      body: SingleChildScrollView(
        child: Stack(
          children: <Widget> [
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
                        )
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
            Container(
              margin: EdgeInsets.only(top: _height * 0.17, left: _width * 0.061),
              child: Text(
                '????????????',
                style: TextStyle(
                    fontFamily: 'NotoSansKR',
                    fontWeight: FontWeight.w700,
                    fontSize: 36
                ),
              ),
            ),
            Stack(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: _height * 0.30, left: _width * 0.064),
                      child: Text(
                        '?????????',
                        style: TextStyle(
                            fontFamily: 'NotoSansKR',
                            fontWeight: FontWeight.w700,
                            fontSize: 24
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                        margin: EdgeInsets.only(top: _height * 0.31, right: _width * 0.064),
                        child: Visibility(
                          visible: _emailValidationVisible,
                          child: Text(
                            '???????????? ????????????. ?????? ????????? ?????????.',
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
                )
              ],
            ),
            Stack(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      margin: EdgeInsets.only(top: _height * 0.34),
                      width: _width * 0.876,
                      child: TextField(
                        controller: _emailEditingController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                            hintText: "???????????? ??????????????????",
                            hintStyle: TextStyle(
                                fontSize: 18,
                                fontFamily: 'NotoSansKR',
                                fontWeight: FontWeight.normal,
                                color: Color(0xffC4C4C4)
                            ),
                            contentPadding: EdgeInsets.only(left: 10, right: 10)
                        ),
                        onChanged: (value) {
                          if(value.isEmpty) {
                            hideEmail();
                            hideEmailCehck();
                            return;
                          }

                          if(_emailValidate(value)) {
                            hideEmail();
                            showEmailCheck();
                          }else {
                            hideEmailCehck();
                            showEmail();
                          }
                        },
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                        margin: EdgeInsets.only(top: _height * 0.354, right: _width * 0.08),
                        child: Visibility(
                          visible: _emailCheckVisible,
                          child: Image(
                              image: AssetImage('assets/images/check_green.png')
                          ),
                        )
                    )
                  ],
                )
              ],
            ),
            Stack(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: _height * 0.43, left: _width * 0.064),
                      child: Text(
                        '????????????',
                        style: TextStyle(
                            fontFamily: 'NotoSansKR',
                            fontWeight: FontWeight.w700,
                            fontSize: 24
                        ),
                      ),
                    )
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                        margin: EdgeInsets.only(top: _height * 0.44, right: _width * 0.064),
                        child: Visibility(
                          visible: _passwordValidationVisible,
                          child: Text(
                            '??????????????? ???????????? ?????????????????????.',
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
                )
              ],
            ),
            Column(
              children: <Widget>[
                Stack(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          margin: EdgeInsets.only(top: _height * 0.47),
                          width: _width * 0.876,
                          child: TextFormField(
                            controller: _passwordEditingController,
                            obscureText: true,
                            keyboardType: TextInputType.text,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                                hintText: "??????????????? ??????????????????",
                                hintStyle: TextStyle(
                                    fontSize: 18,
                                    fontFamily: 'NotoSansKR',
                                    fontWeight: FontWeight.normal,
                                    color: Color(0xffC4C4C4)
                                ),
                                contentPadding: EdgeInsets.only(left: 10, right: 10)
                            ),
                            onChanged: (value) {
                              if(value.isEmpty) {
                                hidePasswordVisible();
                                hidePasswordVailationVisible();
                                return;
                              }

                              print(value);
                              if(_passwordValidDate(value)) {
                                hidePasswordVailationVisible();
                                showPasswordVisible();
                              } else {
                                hidePasswordVisible();
                                showPasswordVaildationVisible();
                              }
                            },
                          ),
                        )
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                            margin: EdgeInsets.only(top: _height * 0.483, right: _width * 0.08),
                            child: Visibility(
                              visible: _passwordVisible,
                              child: Image(
                                  image: AssetImage('assets/images/check_green.png')
                              ),
                            )
                        )
                      ],
                    )
                  ],
                ),
                Stack(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          margin: EdgeInsets.only(top: 5),
                          width: _width * 0.876,
                          child: TextFormField(
                            controller: _passwordCheckController,
                            obscureText: true,
                            keyboardType: TextInputType.text,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                                hintText: "???????????? ??????",
                                hintStyle: TextStyle(
                                    fontSize: 18,
                                    fontFamily: 'NotoSansKR',
                                    fontWeight: FontWeight.normal,
                                    color: Color(0xffC4C4C4)
                                ),
                                contentPadding: EdgeInsets.only(left: 10, right: 10)
                            ),
                            onChanged: (value) {
                              if(value.isEmpty) {
                                hidePasswordCheckVisible();
                                hidePasswordCheckGreen();
                                return;
                              }

                              String inputPassword = _passwordEditingController.text;
                              if(inputPassword.isEmpty || inputPassword != value) {
                                hidePasswordCheckGreen();
                                showPasswordCheckVisible();
                              }else {
                                hidePasswordCheckVisible();
                                showPasswordCheckGreen();
                              }
                            },
                          ),
                        )
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                            margin: EdgeInsets.only(top: 18, right: _width * 0.08),
                            child: Visibility(
                              visible: _passwordCheckRedVisible,
                              child: Image(
                                  image: AssetImage('assets/images/check_red.png')
                              ),
                            )
                        )
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          margin: EdgeInsets.only(top: 18, right: _width * 0.08),
                          child: Visibility(
                            visible: _passwordGreenVisible,
                            child: Image(
                                image: AssetImage('assets/images/check_green.png')
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: _height * 0.615, left: _width * 0.064),
                      child: Text(
                        '?????????',
                        style: TextStyle(
                            fontFamily: 'NotoSansKR',
                            fontWeight: FontWeight.w700,
                            fontSize: 24
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 5),
                      width: _width * 0.876,
                      child: TextFormField(
                        controller: _nickNameEditingController,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                            hintText: "???????????? ??????????????????!",
                            hintStyle: TextStyle(
                                fontSize: 18,
                                fontFamily: 'NotoSansKR',
                                fontWeight: FontWeight.normal,
                                color: Color(0xffC4C4C4)
                            ),
                            contentPadding: EdgeInsets.only(left: 10, right: 10)
                        ),
                        onChanged: (value) {
                        },
                      ),
                    )
                  ],
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
                      "??????",
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontFamily: 'NotoSansKR',
                          fontSize: 20,
                          color: Colors.white
                      ),
                    ),
                    onPressed: () async {
                      email = _emailEditingController.text;
                      password = _passwordEditingController.text;
                      nickName = _nickNameEditingController.text;
                      chkPassword = _passwordCheckController.text;

                      print(email);

                      if(_passwordCheckRedVisible || _passwordValidationVisible || _emailValidationVisible) {
                        _showTaost("?????? ????????? ??????????????????!");
                        return;
                      }else if(email.isEmpty || password.isEmpty || nickName.isEmpty || chkPassword.isEmpty) {
                        _showTaost("?????? ?????? ??????????????????!");
                        return;
                      }

                      await _postEmail();
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
        ),
      )
    );
  }
}