import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AdsterraBanner extends StatefulWidget {
  final int height;
  final int width;
  final String adKey;

  const AdsterraBanner({
    super.key,
    this.height = 60,
    this.width = 468,
    this.adKey = 'b3ebfb84dfe7f276ec8ca6b0601afc33',
  });

  @override
  State<AdsterraBanner> createState() => _AdsterraBannerState();
}

class _AdsterraBannerState extends State<AdsterraBanner> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final html = '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    * { box-sizing: border-box; }
    body {
      margin: 0;
      padding: 0;
      background: transparent;
      display: flex;
      justify-content: center;
      align-items: center;
      overflow: hidden;
      width: 100vw;
      height: 100vh;
    }
    iframe { border: none !important; }
  </style>
</head>
<body>
  <script type="text/javascript">
    atOptions = {
      'key' : '${widget.adKey}',
      'format' : 'iframe',
      'height' : ${widget.height},
      'width' : ${widget.width},
      'params' : {}
    };
  </script>
  <script type="text/javascript" src="https://www.highrevenueformat.com/${widget.adKey}/invoke.js"></script>
</body>
</html>
''';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
        ),
      )
      ..loadHtmlString(html);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width.toDouble(),
      height: widget.height.toDouble() + 8,
      child: Stack(
        alignment: Alignment.center,
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }
}
