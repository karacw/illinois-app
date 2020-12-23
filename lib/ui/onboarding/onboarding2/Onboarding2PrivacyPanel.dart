/*
 * Copyright 2020 Board of Trustees of the University of Illinois.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Onboarding2.dart';
import 'package:illinois/ui/widgets/ScalableWidgets.dart';
import 'package:illinois/ui/widgets/SwipeDetector.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/widgets/TrianglePainter.dart';

import 'Onboarding2Widgets.dart';

class Onboarding2PrivacyPanel extends StatefulWidget{

  Onboarding2PrivacyPanel();
  _Onboarding2PrivacyPanelState createState() => _Onboarding2PrivacyPanelState();
}

class _Onboarding2PrivacyPanelState extends State<Onboarding2PrivacyPanel> {

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String titleText = Localization().getStringEx(
        'panel.onboarding2.privacy.label.title',
        'YOUR PRIVACY LEVEL IS');

    return Scaffold(
        backgroundColor: Styles().colors.background,
        body: SafeArea(child: SwipeDetector(
            onSwipeLeft: () => _goNext(context),
            onSwipeRight: () => _goBack(context),
            child:
            ScalableScrollView(
              scrollableChild:
              Column(
                children:[
                Container(
                    color: Styles().colors.fillColorPrimary,
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[

                          Container(
                            padding: EdgeInsets.symmetric(vertical: 18),
                            child: Row(children: [
                            Onboarding2BackButton(padding: const EdgeInsets.only(
                                left: 17, right: 20),
                                color: Styles().colors.white,
                                onTap: () {
                                  Analytics.instance.logSelect(target: "Back");
                                  _goBack(context);
                                }),
                            Expanded(child: Container()),

                            GestureDetector(
                              onTap: () {
                                Analytics.instance.logSelect(target: 'Skip') ;
                                _goSkip(context);
                              },
                              child: Semantics(
                                  label: "Skip",
                                  hint: '',
                                  button: true,
                                  excludeSemantics: true,
                                  child: Padding(
                                      padding: EdgeInsets.symmetric(vertical: 0),
                                      child: Text(
                                        "Skip",
                                        style: TextStyle(
                                            fontFamily: Styles().fontFamilies.regular,
                                            fontSize: 16,
                                            color: Styles().colors.white,
                                            decoration: TextDecoration.underline,
                                            decorationColor: Styles().colors.fillColorSecondary,
                                            decorationThickness: 1,
                                            decorationStyle:
                                            TextDecorationStyle.solid),
                                      ))),
                            ),
                            Container(width: 16,)
                          ],)),
                          Semantics(
                              label: titleText,
                              hint: Localization().getStringEx(
                                  'panel.onboarding2.privacy.label.title.hint',
                                  ''),
                              excludeSemantics: true,
                              child: Padding(
                                padding: EdgeInsets.only(
                                    left: 17, right: 17, top: 0, bottom: 12),
                                child: Align(
                                    alignment: Alignment.center,
                                    child: Text(
                                        titleText,
                                        style: TextStyle(
                                            color: Styles().colors.white,
                                            fontSize: 24,
                                            fontFamily: Styles().fontFamilies.bold
                                        ))
                                ),
                              )),
                          _buildPrivacySlider(),
                          Semantics(
                              label: _privacyDescription,
                              excludeSemantics: true,
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Align(
                                    alignment: Alignment.topCenter,
                                    child: Text(
                                      _privacyDescription,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontFamily: Styles().fontFamilies.bold,
                                          fontSize: 32,
                                          color: Styles().colors.white),
                                    )),
                              )),
                          Container(height: 24,),
                          Container(
                              height: 90,
                              child: Stack(
                                children: [
                                  Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                      height: 90,
                                      child: Column(
                                          children: [
                                            CustomPaint(
                                              painter: TrianglePainter(
                                                painterColor: Styles().colors
                                                    .background,),
                                              child: Container(
                                                height: 70,
                                              ),
                                            ),
                                            Container(height: 20,
                                              color: Styles().colors.background,)
                                          ]),
                                    ),
                                  ),
                                ],
                              )
                          )
                ])),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child:
                  Text(
                    _privacyLongDescription,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: Styles().fontFamilies.regular,
                        fontSize: 16,
                        color: Styles().colors.fillColorPrimary),
                  )
                )
              ]),
              bottomNotScrollableWidget:
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(height: 16,),
                    Padding(
                      padding: EdgeInsets.only(
                          bottom: 13, top: 8),
                      child: ScalableRoundedButton(
                        label: _continueButtonLabel,
                        hint: Localization().getStringEx('panel.onboarding2.privacy_statement.button.continue.hint', ''),
                        fontSize: 16,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Styles().colors.background,
                        borderColor: Styles().colors.fillColorSecondaryVariant,
                        textColor: Styles().colors.fillColorPrimary,
                        onTap: () => _goNext(context),
                      ),),
                    Text(
                      Localization().getStringEx("panel.onboarding2.privacy.label.continue.description", "You can adjust your privacy level at any time in the Privacy Center."),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontFamily: Styles().fontFamilies.regular,
                          fontSize: 14,
                          color: Styles().colors.textSurface),
                    ),
                    Container(height: 16,)
                  ],
                ),
              ),
            ))));
  }

  Widget _buildPrivacySlider(){
    double selectedItemWidth = 50;
    double deselectedItemWidth = 40;
    double selectedTextSize = 28;
    double deselectedTextSize = 24;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 82),
      height: 100,
      child: Stack(
        children:[
          Align(
            alignment: Alignment.center,
            child: Row(children: [
              Expanded(child:
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 15),
                  child: Container(
                      height: 1,
                      color: Styles().colors.white,
                    )
              ))
            ]),
          ),
          Align(
            alignment: Alignment.center,
            child:
            Row(children: [
              Container(
                width: _privacyLevel==1? selectedItemWidth : deselectedItemWidth ,
                child: Stack(
                  children: [
                    Align(
                      child: Container(
                        width:50,
                        child: Image.asset(_privacyLevel==2?"images/privacy_box_selected.png" :"images/privacy_box_deselected.png", fit: BoxFit.fitWidth,),
                      )
                    ),
                    Center(
                      child:
                      Text(
                        "1",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: _privacyLevel==1? selectedTextSize: deselectedTextSize,
                          color: Styles().colors.white
                        ),
                      )
                    )
                  ],
              ),
            ),
            Expanded(
              child: Container(),
            ),
              Container(
                width: _privacyLevel==2? selectedItemWidth : deselectedItemWidth ,
                child: Stack(
                  children: [
                    Align(
                        child: Container(
                          width:50,
                          child: Image.asset(_privacyLevel==2?"images/privacy_box_selected.png" :"images/privacy_box_deselected.png", fit: BoxFit.fitWidth,),
                        )
                    ),
                    Center(
                        child:
                        Text(
                          "2",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: _privacyLevel==2? selectedTextSize: deselectedTextSize,
                              color: Styles().colors.white
                          ),
                        )
                    )
                  ],
                ),
              ),
              Expanded(
                child: Container(),
              ),
              Container(
                width: _privacyLevel==3? selectedItemWidth : deselectedItemWidth ,
                child: Stack(
                  children: [
                    Align(
                        child: Container(
                          width:50,
                          child: Image.asset(_privacyLevel==3?"images/privacy_box_selected.png" :"images/privacy_box_deselected.png", fit: BoxFit.fitWidth,),
                        )
                    ),
                    Center(
                        child:
                        Text(
                          "3",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: _privacyLevel==3? selectedTextSize: deselectedTextSize,
                              color: Styles().colors.white
                          ),
                        )
                    )
                  ],
                ),
              ),
              Expanded(
                child: Container(),
              ),
              Container(
                width: _privacyLevel==4? selectedItemWidth : deselectedItemWidth ,
                child: Stack(
                  children: [
                    Align(
                        child: Container(
                          width:50,
                          child: Image.asset(_privacyLevel==5?"images/privacy_box_selected.png" :"images/privacy_box_deselected.png", fit: BoxFit.fitWidth,),
                        )
                    ),
                    Center(
                        child:
                        Text(
                          "4",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: _privacyLevel==4? selectedTextSize: deselectedTextSize,
                              color: Styles().colors.white
                          ),
                        )
                    )
                  ],
                ),
              ),
              Expanded(
                child: Container(),
              ),
              Container(
                width: _privacyLevel==5? selectedItemWidth : deselectedItemWidth ,
                child: Stack(
                  children: [
                    Align(
                        child: Container(
                          width:50,
                          child: Image.asset(_privacyLevel==5?"images/privacy_box_selected.png" :"images/privacy_box_deselected.png", fit: BoxFit.fitWidth,),
                        )
                    ),
                    Center(
                        child:
                        Text(
                          "5",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: _privacyLevel==5? selectedTextSize: deselectedTextSize,
                              color: Styles().colors.white
                          ),
                        )
                    )
                  ],
                ),
              ),
            Container()
            ],)
          )
        ]
      )
    );
  }

  int get _privacyLevel{
    return Onboarding2().getPrivacyLevel;
  }

  String get _privacyDescription{
    //TBD
    return "Privacy is your highest concern.";
  }

  String get _privacyLongDescription{
    //TBD
    return "You are completely anonymous and can browse content. You won't be connected to the Illinois ecosystem";
  }

  String get _continueButtonLabel{
    return "Continue"; // tbd
  }

  void _goNext(BuildContext context) {
    //TBD do Login for certain privacy level

    Onboarding2().finish(context);
  }

  void _goBack(BuildContext context) {
    Navigator.of(context).pop();
  }

  void _goSkip(BuildContext context){
    Onboarding2().finish(context);
  }
}