import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:online_planner_app/detail/achievement/achievement_list.dart';
import 'package:online_planner_app/detail/user_info/user_info_detail.dart';
import 'package:page_transition/page_transition.dart';

class AchievementPage extends StatefulWidget {
  _AchievementWidget createState() => _AchievementWidget();
}

class _AchievementWidget extends State<AchievementPage> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: Color(0xffFBFBFB),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Color(0xffFBFBFB),
            toolbarHeight: 100,
            titleSpacing: 0,
            title: Text(
              "업적",
              style: TextStyle(
                  fontFamily: 'NotoSansKR',
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                  color: Color(0xff2C2C2C)
              ),
            ),
            leading: Container(
              margin: EdgeInsets.only(left: 10),
              child: IconButton(
                icon: Icon(Icons.arrow_back_ios),
                onPressed: () {
                  Navigator.pop(
                      context,
                      PageTransition(
                          child: UserInfoPage(),
                          type: PageTransitionType.topToBottom
                      )
                  );
                },
                color: Color(0xff2C2C2C),
                iconSize: 35,
              ),
            ),
            centerTitle: false,
            bottom: const TabBar(
              tabs: [
                Tab(
                  child: Text(
                    '완료한 업적',
                    style: TextStyle(
                        fontFamily: 'NotoSansKR',
                        fontWeight: FontWeight.normal,
                        fontSize: 18,
                    ),
                  ),
                ),
                Tab(
                  child: Text(
                    '남은 업적',
                    style: TextStyle(
                        fontFamily: 'NotoSansKR',
                        fontWeight: FontWeight.normal,
                        fontSize: 18,
                    ),
                  ),
                ),
              ],
              unselectedLabelColor: Color(0xff9B9B9B),
              indicatorColor: Color(0xff2F5DFB),
              labelColor: Color(0xff2F5DFB),
            ),
          ),
          body: TabBarView(
            children: [
              AchievementListPage(true),
              AchievementListPage(false)
            ],
          ),
        )
    );
  }

}