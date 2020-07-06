import 'dart:convert';
import 'dart:io';

import 'package:apple_sign_in/apple_sign_in.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pikobar_flutter/blocs/authentication/Bloc.dart';
import 'package:pikobar_flutter/blocs/remoteConfig/Bloc.dart';
import 'package:pikobar_flutter/constants/Colors.dart';
import 'package:pikobar_flutter/constants/Dictionary.dart';
import 'package:pikobar_flutter/constants/Dimens.dart';
import 'package:pikobar_flutter/constants/FontsFamily.dart';
import 'package:pikobar_flutter/constants/firebaseConfig.dart';
import 'package:pikobar_flutter/environment/Environment.dart';

import 'TermsConditions.dart';

class OnBoardingLoginScreen extends StatefulWidget {
  final AuthenticationBloc authenticationBloc;
  final double positionBottom;

  OnBoardingLoginScreen({this.authenticationBloc, this.positionBottom});

  @override
  _OnBoardingLoginScreenState createState() => _OnBoardingLoginScreenState();
}

class _OnBoardingLoginScreenState extends State<OnBoardingLoginScreen> {
  RemoteConfigBloc _remoteConfigBloc;

  bool isAgree = false;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RemoteConfigBloc>(
      create: (BuildContext context) =>
          _remoteConfigBloc = RemoteConfigBloc()..add(RemoteConfigLoad()),
      child: Stack(
        children: <Widget>[
          Positioned(
            left: 0.0,
            right: 0.0,
            top: 0.0,
            child: Column(
              children: <Widget>[
                Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height * 0.3,
                  child: Image.asset(
                    '${Environment.imageAssets}onboarding_login.png',
                    fit: BoxFit.fitWidth,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    top: 20,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Image.asset('${Environment.logoAssets}logo.png',
                          width: 50.0, height: 50.0),
                      Container(
                          padding: const EdgeInsets.all(10.0),
                          child: Text(
                            Dictionary.appName,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: FontsFamily.intro,
                            ),
                          ))
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.fromLTRB(
                      Dimens.padding, 20.0, Dimens.padding, 0.0),
                  child: Text(
                    Dictionary.titleOnBoardingLogin,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: FontsFamily.lato,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.0),
                  ),
                )
              ],
            ),
          ),
          Positioned(
            left: 0.0,
            right: 0.0,
            bottom: widget.positionBottom ?? 0.0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                BlocBuilder<RemoteConfigBloc, RemoteConfigState>(
                  builder: (context, state) {
                    return state is RemoteConfigLoaded
                        ? _buildTermsConditions(state.remoteConfig)
                        : Container();
                  },
                ),
                Container(
                  width: MediaQuery.of(context).size.width,
                  height: 40.0,
                  margin: EdgeInsets.fromLTRB(
                      Dimens.padding, Dimens.padding, Dimens.padding, 25.0),
                  child: RaisedButton(
                      splashColor: Colors.lightGreenAccent,
                      padding: EdgeInsets.all(0.0),
                      color: isAgree ? ColorBase.green : Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        Dictionary.acceptLogin,
                        style: TextStyle(
                            fontFamily: FontsFamily.lato,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.0,
                            color: Colors.white),
                      ),
                      onPressed: () {
                        if (isAgree) {
                          Platform.isAndroid ?
                          widget.authenticationBloc.add(LoggedIn()) :
                          _loginBottomSheet(context);
                        } else {
                          Scaffold.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: Theme.of(context).primaryColor,
                              content: Text(Dictionary.aggrementIsFalse),
                              duration: Duration(seconds: 5),
                            ),
                          );
                        }
                      }),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  _buildTermsConditions(RemoteConfig remoteConfig) {
    var termsConditions;
    if (remoteConfig.getString(FirebaseConfig.termsConditions).isNotEmpty) {
      termsConditions =
          json.decode(remoteConfig.getString(FirebaseConfig.termsConditions));
      return Container(
        margin: EdgeInsets.fromLTRB(Dimens.padding, 0.0, Dimens.padding, 0.0),
        child: Row(
          children: <Widget>[
            Checkbox(
              value: isAgree,
              activeColor: Color(0xffD5F6E3),
              checkColor: Color(0xff27AE60),
              onChanged: (bool value) {
                setState(() {
                  isAgree = value;
                });
              },
            ),
            Container(
              width: MediaQuery.of(context).size.width * 0.75,
              child: RichText(
                text: TextSpan(
                    text: termsConditions['agreement'],
                    style: TextStyle(
                        fontFamily: FontsFamily.lato,
                        color: Color(0xff828282),
                        fontSize: 11.0),
                    children: <TextSpan>[
                      TextSpan(
                          text: Dictionary.termsConditions,
                          style: TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.bold),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        TermsConditionsPage(termsConditions)),
                              );
                            })
                    ]),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container();
    }
  }

  void _loginBottomSheet(context) {
    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10.0),
            topRight: Radius.circular(10.0),
          ),
        ),
        elevation: 60.0,
        builder: (BuildContext context) {
          return Container(
            margin: EdgeInsets.only(bottom: 20.0),
            child: Wrap(
              alignment: WrapAlignment.center,
              children: <Widget>[
                Container(
                  margin: EdgeInsets.only(top: 14.0),
                  color: Colors.black,
                  height: 1.5,
                  width: 40.0,
                ),
                Container(
                  alignment: Alignment.topCenter,
                  padding: EdgeInsets.all(20.0),
                  decoration: BoxDecoration(boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.05),
                      offset: Offset(0.0, 0.05),
                    ),
                  ]),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(height: 5.0),

                      _appleSignInButton(),

                      SizedBox(
                        height: 16.0,
                      ),

                      _googleSignInButton()
                    ],
                  ),
                )
              ],
            ),
          );
        });
  }

  Widget _appleSignInButton() {
    return RaisedButton(
      splashColor: Colors.grey,
      color: Colors.black,
      onPressed: () {
        Navigator.pop(context);
        widget.authenticationBloc.add(LoggedIn(isApple: true));
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image(image: AssetImage('${Environment.iconAssets}apple_white.png'), height: 24.0),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(
                'Sign in with Apple',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _googleSignInButton() {
    return OutlineButton(
      splashColor: Colors.grey,
      onPressed: () {
        Navigator.pop(context);
        widget.authenticationBloc.add(LoggedIn(isApple: false));
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      highlightElevation: 0,
      borderSide: BorderSide(color: Colors.grey),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image(image: AssetImage('${Environment.iconAssets}google.png'), height: 24.0),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(
                'Sign in with Google',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _remoteConfigBloc.close();
    super.dispose();
  }
}
