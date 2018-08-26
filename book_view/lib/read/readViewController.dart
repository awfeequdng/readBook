import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:book_view/tools/XRegexObject.dart';
import 'package:book_view/Global/XContants.dart';
import 'package:book_view/read/V/ReadBottomView.dart';
import 'package:book_view/Global/dataHelper.dart';
import 'package:book_view/Global/cacehHelper.dart';
import 'package:book_view/read/V/ReadHtmlParser.dart';

class ReadViewController extends StatefulWidget {
  final String title;
  final String bookName;
  final String url;

  ReadViewController({Key key, this.title, this.bookName, this.url})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => new ReadViewControllerState(
      title: this.title, bookName: this.bookName, url: this.url);
}

class ReadViewControllerState extends State<ReadViewController> {
  String url;
  String title;
  String bookName;
  String content = '';
  Map chapter;
  ScrollController scroll = ScrollController();
  ReadHtmlParser contentObject;
  double maxOffset=0.0;
  double minOffSet=0.0;
  ReadViewControllerState({Key key, this.url, this.title, this.bookName}) {
    contentObject = ReadHtmlParser();
    getDataFromHttp();
  }

  getDataFromHttp() async {
    DataHelper db = await getDataHelp();
    if (chapter == null) {
      chapter = await db.getChapter(bookName, title);
    }
    db.updateCurrentChapter(bookName, title);
    CacheHelper.cacheBookAuto(bookName, title);

    await CacheHelper.getChapterContent(bookName, chapter['chapterName'], url,
        (String chapterCache) {
      XRegexObject find = new XRegexObject(text: chapterCache);
      String contentRegex = r'<div id="content">(.*?)</div>';

      content = find.getListWithRegex(contentRegex)[0];
      setState(() {
      });
      scroll.animateTo(0.0, duration: new Duration(milliseconds: 200), curve: Curves.ease);
    });
  }

  AppBar _appBar;
  double toolOpacity = 0.0;
  var showAppBar = false;
  showTipView() {
    setState(() {
      if (showAppBar == false) {
        showAppBar = true;
        toolOpacity = 1.0;
        _appBar = AppBar(
          title: Text(title),
          backgroundColor: XColor.appBarColor,
          textTheme: TextTheme(title: XTextStyle.readTitleStyle),
          iconTheme: IconThemeData(color: Colors.white),
          actions: <Widget>[
            IconButton(
                icon: Icon(
                  Icons.menu,
                  color: Colors.white,
                ),
                onPressed: null),
          ],
        );
      } else {
        showAppBar = false;
        _appBar = null;
        toolOpacity = 0.0;
      }
    });
  }

  nextChapter() async {
    print("next");
    DataHelper db = await getDataHelp();
    chapter = await db.getNextChapter(bookName, chapter["id"]);
    if (chapter != null) {
      title = chapter['chapterName'];
      url = chapter['link'];
      getDataFromHttp();
    }
  }

  lastChapter() async {
    print("last");
    DataHelper db = await getDataHelp();
    chapter = await db.getLastChapter(bookName, chapter["id"]);
    if (chapter != null) {
      title = chapter['chapterName'];
      url = chapter['link'];
      getDataFromHttp();
    }
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if(notification is ScrollUpdateNotification){
      double offset = notification.metrics.pixels;
      if(offset<minOffSet){
        minOffSet = offset;
      }
      if(offset>maxOffset){
        maxOffset = offset;
      }
    }
    if(notification is ScrollEndNotification){
      //下滑到最底部
      if(notification.metrics.extentAfter==0.0){
        if(maxOffset-notification.metrics.maxScrollExtent>100){
          nextChapter();
          maxOffset=0.0;
        }
      }
      //滑动到最顶部
      if(notification.metrics.extentBefore==0.0){
        if(minOffSet<-100){
          lastChapter();
          minOffSet=0.0;
        }
      }
    }
    return false;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: _appBar,
        backgroundColor: Color.fromRGBO(247, 235, 157, 1.0),
        body: Stack(
          children: <Widget>[
            GestureDetector(
              child: NotificationListener(child: contentObject.getParseListFromStr(content,scroll),
                onNotification: _handleScrollNotification,
              ),
              onTap: showTipView,
            ),
            Align(
              alignment: AlignmentDirectional.bottomCenter,
              child: Opacity(
                opacity: toolOpacity,
                child: ReadBottomView(
                  nextChapter: nextChapter,
                  lastChapter: lastChapter,
                ),
              ),
            )
          ],
        ));
  }
}