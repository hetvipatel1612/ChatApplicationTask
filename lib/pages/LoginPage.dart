import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import '../constants/app_constants.dart';
import '../constants/color_constants.dart';
import '../main.dart';
import '../providers/auth_provider.dart';
import '../widgets/loading_view.dart';
import 'HomePage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  bool _isAnimate = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() => _isAnimate = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    AuthProvider authProvider = Provider.of<AuthProvider>(context);
    switch (authProvider.status) {
      case Status.authenticateError:
        print(Status.authenticateError);
        Fluttertoast.showToast(msg: "Sign in fail");
        break;
      case Status.authenticateCanceled:
        Fluttertoast.showToast(msg: "Sign in canceled");
        break;
      case Status.authenticated:
        Fluttertoast.showToast(msg: "Sign in success");
        break;
      default:
        break;
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppConstants.loginTitle,
          style: TextStyle(color: ColorConstants.primaryColor, fontSize: 25),
        ),
        centerTitle: true,
      ),
      body: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Center(
          child: Image.asset(
            "assets/images/app_icon.png",
            width: 150,
            height: 150,
          ),
        ),
        SizedBox(height: 30),

        Center(
          child: Container(
            width: 220,
            child: TextButton(
              onPressed: () async {
                authProvider.handleSignIn().then((isSuccess) {
                  if (isSuccess) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HomePage(),
                      ),
                    );
                  }
                }).catchError((error, stackTrace) {
                  Fluttertoast.showToast(msg: error.toString());
                  authProvider.handleException();
                });
              },
              child: Row(
                children: [
                  Image.asset("assets/images/google.png", height: 20),
                  SizedBox(
                    width: 8,
                  ),
                  Text(
                    'Sign in with Google',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ],
              ),
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.resolveWith<Color>(
                  (Set<MaterialState> states) {
                    if (states.contains(MaterialState.pressed))
                      return const Color.fromARGB(255, 105, 178, 210)
                          .withOpacity(0.8);
                    return Color.fromARGB(255, 50, 155, 201);
                  },
                ),
                splashFactory: NoSplash.splashFactory,
                padding: MaterialStateProperty.all<EdgeInsets>(
                  EdgeInsets.fromLTRB(30, 15, 30, 15),
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 20,
        ),
        // Loading
        Positioned(
          child: authProvider.status == Status.authenticating
              ? LoadingView()
              : SizedBox.shrink(),
        ),
      ]),
    );
  }
}
