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
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/utils/AppUtils.dart';

typedef OnContinueCallback(List<String> selectedOptions, OnContinueProgressController progressController);
typedef OnContinueProgressController({bool? loading});
class SettingsDialog extends StatefulWidget{
  final String? title;
  final List<TextSpan>? message;
  final String? continueButtonTitle;
  final List<String>? options;
  final List<String>? initialOptionsSelection;
  final OnContinueCallback? onContinue;
  final bool longButtonTitle; // make the button padding fit two lines ot title

  const SettingsDialog({Key? key, this.options, this.onContinue, this.title, this.message, this.continueButtonTitle, this.longButtonTitle = false, this.initialOptionsSelection}) : super(key: key);

  static show(BuildContext context, {bool? longButtonTitle,String? title, String? continueTitle, List<TextSpan>? message,List<String>? options, List<String>? initialOptionsSelection, OnContinueCallback? onContinue}) async{
    await showDialog(
       context: context,
       builder: (context) {
         return
           Material(
             type: MaterialType.transparency,
             child: Container(
               color: Styles().colors!.blackTransparent06,
               child: SingleChildScrollView(child:
               Column(children:[
                   Stack(
                     children: <Widget>[
                       Align(alignment: Alignment.center,
                           child: Container(
                             padding: EdgeInsets.symmetric(horizontal: 16,vertical: 17),
                             child: SettingsDialog(title:title, continueButtonTitle:continueTitle , message: message, options: options, onContinue: onContinue, initialOptionsSelection: initialOptionsSelection, longButtonTitle: longButtonTitle??false,)
                           )
                       )
                     ],
                   ),
                 ])
             )),
           );
        },
     );
  }
    @override
  State<StatefulWidget> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog>{
  
  final GlobalKey _confirmKey = GlobalKey();
  Size? _confirmSize;
  List<String> selectedOptions = [];
  bool? _loading = false;

  @override
  void initState() {
    selectedOptions = widget.initialOptionsSelection ?? [];
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      _evalConfirmSize();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Styles().colors!.white, borderRadius: BorderRadius.all(Radius.circular(4)), boxShadow: [BoxShadow(color: Styles().colors!.blackTransparent018!, spreadRadius: 2.0, blurRadius: 6.0, offset: Offset(2, 2))] ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            color: Styles().colors!.fillColorPrimary,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
             children: <Widget>[
              Expanded(child:
              Text(
                widget.title??"",
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white, fontSize: 24, fontFamily: Styles().fontFamilies!.bold,),
              )),
              Semantics(label: Localization().getStringEx("dialog.close.title", "Close"), button: true,
              child:GestureDetector(
              onTap: () => Navigator.pop(context),
              child:
                Container(
                  padding: EdgeInsets.only(left: 50, top: 4),
                  child:Image.asset("images/icon-circle-close.png", excludeFromSemantics: true,)
                ),
              ),)
            ],),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(border:  Border.all(color: Styles().colors!.fillColorPrimary!,width: 1), borderRadius: BorderRadius.only(bottomRight: Radius.circular(4), bottomLeft: Radius.circular(4))),
            child:
              Column(children: <Widget>[
              Container(height: 16,),
              RichText(
                text: TextSpan(
                  style: TextStyle(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.regular, fontSize: 16),
                  children: widget.message??[],
                ),
              ),
              _buildOptions(),
              Container(height: 14,),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child:
                  _buildCancellButton(),
                  ),
                  Container(width: 8,),
                  Expanded(child:
                  _buildConfirmButton()
                  ),
              ],),
              Container(height: 8,),
            ],))
        ],
      ),
    );
  }

  Widget _buildOptions(){
    if(widget.options?.isNotEmpty??false){
      List<Widget> options = [];
      widget.options!.forEach((option){
        options.add(_buildOptionButton(option));
      });

      if(options.isNotEmpty)
        return Container(
          padding: EdgeInsets.only(top: 18),
          child:SingleChildScrollView(child:Column(
            children: options,
          )
          ),
        );
    }

    return Container(height: 16,/*workaround to reduce last element bottom padding*/);
  }

  Widget _buildOptionButton(String option){
    bool isChecked = selectedOptions.contains(option);
    return
        AppSemantics.buildCheckBoxSemantics( selected: isChecked, title: option,
          child: GestureDetector(
            child: Container(
              padding: EdgeInsets.only(bottom: 16),
              child: Row(children: <Widget>[
                Image.asset(isChecked? "images/selected-checkbox.png" : "images/deselected-checkbox.png"),
                Container(width: 10,),
                Expanded(child:
                  Text(
                    option, style: TextStyle(fontFamily: Styles().fontFamilies!.regular, fontSize: 16, color: Styles().colors!.fillColorPrimary),),
                  )
              ],)
          ),
          onTap: (){
            AppSemantics.announceCheckBoxStateChange(context, !isChecked, option);
             if(selectedOptions.contains(option)){
               selectedOptions.remove(option);
             } else {
               selectedOptions.add(option);
             }
             setState((){});
          },
        ));
  }

  _buildCancellButton(){
    return
      Semantics( button: true,
      child: GestureDetector(
        onTap: (){ Navigator.pop(context);},
        child: Container(
          alignment: Alignment.center,
//          height: widget.longButtonTitle?56 : 42,
          decoration: BoxDecoration(
            color: (Styles().colors!.white),
            border: Border.all(
                color: Styles().colors!.fillColorPrimary!,
                width: 1),
            borderRadius: BorderRadius.circular(25),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child:
          Row(children: <Widget>[
            Expanded(child:
              Text(

                Localization().getStringEx("widget.settings.dialog.button.cancel.title","Cancel"), textAlign: TextAlign.center, style: TextStyle(fontFamily: Styles().fontFamilies!.bold, fontSize: 16, color: Styles().colors!.fillColorPrimary),),
            )
          ],)
        )));
  }
  _buildConfirmButton(){
    return
      Semantics( button: true, enabled: _getIsContinueEnabled,
        child: Stack(children: <Widget>[
          GestureDetector(
              onTap: (){ widget.onContinue!(selectedOptions, ({bool? loading})=>setState((){_loading = loading;}));},
              child: Container(
                key: _confirmKey,
                alignment: Alignment.center,
//                height: widget.longButtonTitle? 56: 42,
                decoration: BoxDecoration(
                  color: (_getIsContinueEnabled? Styles().colors!.fillColorSecondaryVariant : Styles().colors!.white),
                  border: Border.all(
                      color: _getIsContinueEnabled? Styles().colors!.fillColorSecondaryVariant!: Styles().colors!.fillColorPrimary!,
                      width: 1),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(children: <Widget>[
                  Expanded(child:
                      Text(widget.continueButtonTitle??"", textAlign: TextAlign.center, style: TextStyle(fontFamily: Styles().fontFamilies!.bold, fontSize: 16, color: _getIsContinueEnabled?Styles().colors!.white: Styles().colors!.fillColorPrimary),),
                  )
                ],)
              )),
          Visibility(visible: (_loading == true),
            child: (_confirmSize != null) ?
              SizedBox(width: _confirmSize!.width, height: _confirmSize!.height,
              child: Align(alignment: Alignment.center,
                child: SizedBox(height: 24, width: 24,
                  child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors!.white), strokeWidth: 2,),),),
              ) : Container(),
          )
        ],));
  }

  bool get _getIsContinueEnabled{
     return widget.options == null || selectedOptions.isNotEmpty;
  }

  void _evalConfirmSize() {
    try {
      final RenderObject? renderBox = _confirmKey.currentContext?.findRenderObject();
      if (renderBox is RenderBox) {
        if (mounted) {
          setState(() {
            _confirmSize = renderBox.size;
          });
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

}

class InfoButton extends StatelessWidget {
  final String? title;
  final String? description;
  final String? iconRes;
  final String? additionalInfo;
  final void Function()? onTap;

  const InfoButton({Key? key, this.title, this.description, this.iconRes, this.onTap, this.additionalInfo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Semantics(button: true, container: true, child:
    InkWell(onTap: onTap, child:
    Container(
      padding: EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: Styles().colors!.surface, borderRadius: BorderRadius.all(Radius.circular(4)), boxShadow: [BoxShadow(color: Styles().colors!.blackTransparent018!, spreadRadius: 2.0, blurRadius: 6.0, offset: Offset(2, 2))] ),
      child: Column(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 11),
              child: Image.asset(iconRes!, excludeFromSemantics: true,),
            ),
            Expanded(child:
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                    padding: EdgeInsets.only(right: 14),
                    child:Text(title!, style: TextStyle(fontFamily: Styles().fontFamilies!.bold, fontSize: 16, color: Styles().colors!.fillColorPrimary),)),
                Padding(padding: EdgeInsets.only(top: 5), child:
                Text(description!, style: TextStyle(fontFamily: Styles().fontFamilies!.regular, fontSize: 14, color: Styles().colors!.textSurface),),
                ),
                _buildAdditionalInfo(),
              ],
            ),
            ),
            Container(width: 10,),
            Container(
              padding: EdgeInsets.symmetric( vertical: 4),
              child:Image.asset('images/chevron-right.png', excludeFromSemantics: true,),
            ),
            Container(width: 16,)
          ],),
      ],),),),
    );
  }

  Widget _buildAdditionalInfo(){
    return additionalInfo?.isEmpty ?? true ? Container() :
        Column(
          children: <Widget>[
            Container(height: 12,),
            Container(height: 1, color: Styles().colors!.surfaceAccent,),
            Container(height: 12),
            Text(additionalInfo!, style: TextStyle(fontFamily: Styles().fontFamilies!.regular, fontSize: 12, color: Styles().colors!.textSurface),),
          ],
        );
  }
}
