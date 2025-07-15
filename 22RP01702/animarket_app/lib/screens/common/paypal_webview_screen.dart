import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PayPalWebViewScreen extends StatefulWidget {
  @override
  _PayPalWebViewScreenState createState() => _PayPalWebViewScreenState();
}

class _PayPalWebViewScreenState extends State<PayPalWebViewScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    
    // Initialize the WebViewController
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar if needed
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {},
        ),
      )
      ..loadRequest(Uri.dataFromString(
        '''
        <!DOCTYPE html>
        <html>
          <head>
            <title>PayPal Sandbox Checkout</title>
            <script src="https://www.paypal.com/sdk/js?client-id=AQrbQ2q4MABy3xFfDehF03EJqefFQw2apHDTdHDkTeqixuTX7Wu6p9yyGrG55GOaWAzCFUseQ_1wbc3T&currency=USD"></script>
          </head>
          <body>
            <div id="paypal-button-container"></div>
            <script>
              paypal.Buttons({
                createOrder: function(data, actions) {
                  return actions.order.create({
                    purchase_units: [{
                      amount: {
                        value: '10.00'
                      },
                      description: 'Premium Upgrade'
                    }]
                  });
                },
                onApprove: function(data, actions) {
                  return actions.order.capture().then(function(details) {
                    document.body.innerHTML = '<h2>Payment Successful!</h2><p>Thank you, ' + details.payer.name.given_name + '.</p>';
                  });
                }
              }).render('#paypal-button-container');
            </script>
          </body>
        </html>
        ''',
        mimeType: 'text/html',
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pay with PayPal')),
      body: WebViewWidget(controller: _controller),
    );
  }
}