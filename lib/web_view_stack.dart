import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewStack extends StatefulWidget {
  const WebViewStack({required this.controller, Key? key}) : super(key: key);

  final Completer<WebViewController> controller;

  @override
  State<WebViewStack> createState() => _WebViewStackState();
}

class _WebViewStackState extends State<WebViewStack> {
  var loadingPercentage = 0;

  void setScrollListener() async {
    if (widget.controller.isCompleted) {
      widget.controller.future.then((value) => getScroll(value));
    }
    /*int y = await _controller.getScrollY();
    if (y > 50) {
      setState(() {
        buttonshow = true;
      });
    } else {
      setState(() {
        buttonshow = false;
      });
    }*/
  }

  void getScroll(WebViewController controller) async {
    int y = await controller.getScrollY();
    /*int webViewMaxY = int.parse(await controller.runJavascriptReturningResult(
        "Math.max( document.body.scrollHeight, document.body.offsetHeight,document.documentElement.clientHeight, document.documentElement.scrollHeight, document.documentElement.offsetHeight );"));*/
    int webViewMaxY = int.parse(await controller
        .runJavascriptReturningResult("document.documentElement.scrollHeight"));

    print("Max Y:$webViewMaxY - Y scroll: $y");
  }

  void getMaxScroll(WebViewController controller) async {
    await Future.delayed(const Duration(milliseconds: 1000));

    String heightStr = await controller.runJavascriptReturningResult(
        "document.documentElement.scrollHeight") ??
        "0";

    print("Maximo Y:$heightStr");
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebView(
          initialUrl: 'about:blank',
          onWebViewCreated: (webViewController) {
            widget.controller.complete(webViewController);
            // _controller = webViewController;
            widget.controller.future.then((value) => loadHtmlFromAssets(value));
          },
          onPageStarted: (url) {
            setState(() {
              loadingPercentage = 0;
            });
          },
          onProgress: (progress) {
            setState(() {
              loadingPercentage = progress;
            });
          },
          onPageFinished: (url) async {
            widget.controller.future.then((value) => getMaxScroll(value));

            setState(() {
              loadingPercentage = 100;
            });
          },
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{}..add(
            Factory<VerticalDragGestureRecognizer>(
                    () => VerticalDragGestureRecognizer()
                  ..onDown = (tap) {
                    setScrollListener();
                  }),
          ),
          navigationDelegate: (navigation) {
            final host = Uri.parse(navigation.url).host;
            if (host.contains('youtube.com')) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Blocking navigation to $host',
                  ),
                ),
              );
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          javascriptMode: JavascriptMode.unrestricted, // Add this line
          javascriptChannels: {
            JavascriptChannel(
                name: 'FLUTTER_CHANNEL',
                onMessageReceived: (message) {
                  if (message.message.toString() == "end of scroll") {
                    print("END");
                    /*setState((){
                      enableAgreeButton = true;
                    });*/
                  }
                })
          },
        ),
        if (loadingPercentage < 100)
          LinearProgressIndicator(
            value: loadingPercentage / 100.0,
          ),
      ],
    );
  }

  loadHtmlFromAssets(WebViewController controller) async {
    String fileText = await rootBundle.loadString('assets/html/example.html');
    controller.loadUrl(Uri.dataFromString(fileText,
        mimeType: 'text/html', encoding: Encoding.getByName('utf-8'))
        .toString());
  }
}