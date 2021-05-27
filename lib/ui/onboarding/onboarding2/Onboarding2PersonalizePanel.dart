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
import 'package:illinois/ui/onboarding/onboarding2/Onboarding2ImprovePanel.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/ui/widgets/ScalableWidgets.dart';
import 'package:illinois/ui/widgets/SwipeDetector.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/widgets/TrianglePainter.dart';
import 'package:illinois/utils/Utils.dart';

import 'Onboarding2PrivacyPanel.dart';
import 'Onboarding2Widgets.dart';

class Onboarding2PersonalizePanel extends StatefulWidget{

  Onboarding2PersonalizePanel();
  _Onboarding2PersonalizePanelState createState() => _Onboarding2PersonalizePanelState();
}

class _Onboarding2PersonalizePanelState extends State<Onboarding2PersonalizePanel> {
  bool _toggled = false;

  @override
  void initState() {
    _toggled = Onboarding2().getPersonalizeChoice;
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String titleText = Localization().getStringEx(
        'panel.onboarding2.personalize.label.title',
        'Store your app activity and personal information?');
    String descriptionText = Localization().getStringEx(
        'panel.onboarding2.personalize.label.description',
        'This includes content you view, teams you follow, and sign-in information. ');

    return Scaffold(
        backgroundColor: Styles().colors.background,
        body: SafeArea(child:SwipeDetector(
            onSwipeLeft: () => _goNext(context),
            onSwipeRight: () => _goBack(context),
            child:
            ScalableScrollView(
              scrollableChild:
              Container(
                  color: Styles().colors.white,
                  child:Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Container(
                            height: 8,
                            padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                            child:Row(children: [
                              Expanded(
                                  flex:1,
                                  child: Container(color: Styles().colors.fillColorPrimary,)
                              ),
                              Container(width: 2,),
                              Expanded(
                                  flex:1,
                                  child: Container(color: Styles().colors.fillColorPrimary,)
                              ),
                              Container(width: 2,),
                              Expanded(
                                  flex:1,
                                  child: Container(color: Styles().colors.backgroundVariant,)
                              ),
                            ],)
                        ),
                        Row(children:[
                          Onboarding2BackButton(padding: const EdgeInsets.only(
                              left: 17, top: 19, right: 20, bottom: 27),
                              onTap: () {
                                Analytics.instance.logSelect(target: "Back");
                                _goBack(context);
                              }),
                        ],),
                        Semantics(
                            label: titleText,
                            hint: Localization().getStringEx(
                                'panel.onboarding2.personalize.label.title.hint', ''),
                            excludeSemantics: true,
                            child: Padding(
                              padding: EdgeInsets.only(
                                  left: 17, right: 17, top: 0, bottom: 12),
                              child: Align(
                                  alignment: Alignment.center,
                                  child: Text(
                                    titleText,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Styles().colors.fillColorPrimary,
                                      fontSize: 24,
                                      fontFamily: Styles().fontFamilies.bold,
                                      height: 1.2
                                  ))
                              ),
                            )),
                        Semantics(
                            label: descriptionText,
                            excludeSemantics: true,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Align(
                                  alignment: Alignment.topCenter,
                                  child: Text(
                                    descriptionText,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontFamily: Styles().fontFamilies.regular,
                                        fontSize: 16,
                                        color: Styles().colors.fillColorPrimary),
                                  )),
                            )),
                        Container(height: 10,),
                        GestureDetector(
                          onTap: _onTapLearnMore,
                          child:  Text(
                              Localization().getStringEx('panel.onboarding2.personalize.button.title.learn_more', 'Learn More'),
                              style: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 14, decoration: TextDecoration.underline, decorationColor: Styles().colors.fillColorSecondary, fontFamily: Styles().fontFamilies.regular,)
                          ),
                        ),
                        Container(height: 12,),
                        Container(
                            height: 200,
                            child: Stack(
                              children: [
                                Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Container(
                                    height: 160,
                                    child:Column(
                                        children:[
                                          CustomPaint(
                                            painter: TrianglePainter(painterColor: Styles().colors.background, left: false),
                                            child: Container(
                                              height: 100,
                                            ),
                                          ),
                                          Container(height: 60, color: Styles().colors.background,)
                                        ]),
                                  ),
                                ),
                                Align(
                                    alignment: Alignment.center,
                                    child:Container(
                                      child: Image.asset("images/group_138.png", excludeFromSemantics: true,fit: BoxFit.fitWidth, width: 300,),
                                    )
                                )
                              ],
                            )
                        )
                      ])),
              bottomNotScrollableWidget:
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child:
                      Onboarding2ToggleButton(
                        toggledTitle: Localization().getStringEx('panel.onboarding2.personalize.button.toggle.title', 'Store my app activity and information I share.'),
                        unToggledTitle: Localization().getStringEx('panel.onboarding2.personalize.button.toggle.title', 'Do not store my app activity or information.'),
                        toggled: _toggled,
                        onTap: _onToggleTap,
                      ),
                    ),
                    ScalableRoundedButton(
                      label: Localization().getStringEx('panel.onboarding2.personalize.button.continue.title', 'Continue'),
                      hint: Localization().getStringEx('panel.onboarding2.personalize.button.continue.hint', ''),
                      fontSize: 16,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Styles().colors.white,
                      borderColor: Styles().colors.fillColorSecondaryVariant,
                      textColor: Styles().colors.fillColorPrimary,
                      onTap: () => _goNext(context),
                    )
                  ],
                ),
              ),
            ))));
  }

  String get _toggleButtonLabel{
    return _toggled? "Yes." : "Not now.";
  }

  String get _toggleButtonDescription{
    return _toggled? "Save my preferences." : "Don’t save events or follow athletic teams.";
  }

  void _onToggleTap(){
    setState(() {
      _toggled = !_toggled;
    });
  }

  void _goNext(BuildContext context) {
    Onboarding2().storePersonalizeChoice(_toggled);
    if (Onboarding2().getPersonalizeChoice) {
      Navigator.push(context,
          CupertinoPageRoute(builder: (context) => Onboarding2ImprovePanel()));
    } else {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => Onboarding2PrivacyPanel()));
    }
  }

  void _goBack(BuildContext context) {
    Navigator.of(context).pop();
  }

  void _onTapLearnMore(){
    //TBD implement learn more
    AppToast.show("TBD");
  }
}