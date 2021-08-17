import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:illinois/model/Auth.dart';
import 'package:illinois/model/Auth2.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/service/AppLivecycle.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/DeepLink.dart';
import 'package:illinois/service/Log.dart';
import 'package:illinois/service/Network.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/Service.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class Auth2 with Service implements NotificationsListener {
  
  static const String REDIRECT_URI         = 'edu.illinois.rokwire://rokwire.illinois.edu/shib-auth';

  static const String notifyLoginStarted   = "edu.illinois.rokwire.auth2.login.started";
  static const String notifyLoginSucceeded = "edu.illinois.rokwire.auth2.login.succeeded";
  static const String notifyLoginFailed    = "edu.illinois.rokwire.auth2.login.failed";
  static const String notifyLoginChanged   = "edu.illinois.rokwire.auth2.login.changed";
  static const String notifyLoginFinished  = "edu.illinois.rokwire.auth2.login.finished";
  static const String notifyLogout         = "edu.illinois.rokwire.auth2.logout";
  static const String notifyCardChanged    = "edu.illinois.rokwire.auth2.card.changed";

  static const String _authCardName        = "idCard.json";

  _OidcLogin _oidcLogin;
  List<Completer<bool>> _oidcAuthenticationCompleters;
  bool _processingOidcAuthentication;
  Timer _oidcAuthenticationTimer;

  Future<Response> _refreshTokenFuture;
  
  Auth2Token _token;
  Auth2Token _uiucToken;
  Auth2User _user;
  
  AuthCard  _authCard;
  File _authCardCacheFile;

  // Singletone instance

  Auth2._internal();
  static final Auth2 _instance = Auth2._internal();

  factory Auth2() {
    return _instance;
  }

  // Service

  @override
  void createService() {
    NotificationService().subscribe(this, [
      DeepLink.notifyUri,
      AppLivecycle.notifyStateChanged,
    ]);
  }

  @override
  Future<void> initService() async {
    _token = Storage().auth2Token;
    _uiucToken = Storage().auth2UiucToken;
    _user = Storage().auth2User;
    
    _authCardCacheFile = await _getAuthCardCacheFile();
    _authCard = await _loadAuthCardFromCache();
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
  }

  @override
  Set<Service> get serviceDependsOn {
    return Set.from([Storage(), Config() ]);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == DeepLink.notifyUri) {
      _onDeepLinkUri(param);
    }
    else if (name == AppLivecycle.notifyStateChanged) {
      if (param == AppLifecycleState.resumed) {
        _refreshAuthCardIfNeeded();
        _createOidcAuthenticationTimerIfNeeded();
      }
    }
  }

  void _onDeepLinkUri(Uri uri) {
    if (uri != null) {
      Uri redirectUri = (_oidcLogin?.redirectUrl != null) ? Uri.tryParse(_oidcLogin.redirectUrl) : null;
      if ((redirectUri != null) &&
          (redirectUri.scheme == uri.scheme) &&
          (redirectUri.authority == uri.authority) &&
          (redirectUri.path == uri.path))
      {
        _handleOidcAuthentication(uri);
      }
    }
  }

  // Getters

  Auth2Token get token => _token;
  Auth2Token get uiucToken => _uiucToken;
  Auth2User get user => _user;
  AuthCard get authCard => _authCard;

  // OIDC Authentication

  Future<bool> authenticateWithOidc() async {
    if ((Config().coreUrl != null) && (Config().appCanonicalId != null) && (Config().coreOrgId != null)) {

      NotificationService().notify(notifyLoginStarted);
      
      if (_oidcAuthenticationCompleters == null) {

        _OidcLogin oidcLogin = await _getOidcData();
        if (oidcLogin?.loginUrl != null) {
          _oidcLogin = oidcLogin;
          await _launchUrl(_oidcLogin?.loginUrl);
        }
        else {
          NotificationService().notify(notifyLoginFailed);
          NotificationService().notify(notifyLoginFinished);
          return false;
        }

        _oidcAuthenticationCompleters = <Completer<bool>>[];
      }

      Completer<bool> completer = Completer<bool>();
      _oidcAuthenticationCompleters.add(completer);
      return completer.future;
    }
    
    return false;
  }

  Future<bool> _handleOidcAuthentication(Uri uri) async {
    _cancelOidcAuthenticationTimer();
    _processingOidcAuthentication = true;
    bool result = await _processOidcAuthentication(uri);
    _processingOidcAuthentication = false;
    _completeOidcAuthentication(result);
    return result;
  }

  Future<bool> _processOidcAuthentication(Uri uri) async {
    if ((Config().coreUrl != null) && (Config().appCanonicalId != null) && (Config().coreOrgId != null)) {
      String url = "${Config().coreUrl}/services/auth/login";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      String post = AppJson.encode({
        'auth_type': auth2LoginTypeToString(Auth2LoginType.oidc),
        'org_id': Config().coreOrgId,
        'app_id': Config().appCanonicalId,
        'creds': uri?.toString(),
        'params': _oidcLogin?.params
      });
      _oidcLogin = null;
      
      Response response = await Network().post(url, headers: headers, body: post);
      Map<String, dynamic> responseJson = (response?.statusCode == 200) ? AppJson.decodeMap(response?.body) : null;
      if (responseJson != null) {
        Auth2Token token = Auth2Token.fromJson(AppJson.mapValue(responseJson['token']));
        Auth2User user = Auth2User.fromJson(AppJson.mapValue(responseJson['user']));

        if ((token != null) && token.isValid && (user != null) && user.isValid) {
          Storage().auth2Token = _token = token;
          Storage().auth2User = _user = user;

          Map<String, dynamic> params = AppJson.mapValue(responseJson['params']);
          Auth2Token uiucToken = (params != null) ? Auth2Token.fromJson(AppJson.mapValue(params['oidc_token'])) : null;
          Storage().auth2UiucToken = _uiucToken = ((uiucToken != null) && uiucToken.isValidUiuc) ? uiucToken : null;

          String authCardString = await _loadAuthCardStringFromNet();
          _authCard = AuthCard.fromJson(AppJson.decodeMap((authCardString)));
          Storage().authCardTime = (_authCard != null) ? DateTime.now().millisecondsSinceEpoch : null;
          await _saveAuthCardStringToCache(authCardString);
          NotificationService().notify(notifyCardChanged);

          NotificationService().notify(notifyLoginChanged);
          return true;
        }
      }
    }
    return false;
  }

  Future<_OidcLogin> _getOidcData() async {
    if ((Config().coreUrl != null) && (Config().appCanonicalId != null) && (Config().coreOrgId != null)) {

      String url = "${Config().coreUrl}/services/auth/login-url";
      //String redirectUrl = "$REDIRECT_URI/${DateTime.now().millisecondsSinceEpoch}";
      Map<String, String> headers = {
        'Content-Type': 'application/json'
      };
      String post = AppJson.encode({
        'auth_type': auth2LoginTypeToString(Auth2LoginType.oidc),
        'org_id': Config().coreOrgId,
        'app_id': Config().appCanonicalId,
        'redirect_uri': REDIRECT_URI,
      });
      Response response = await Network().post(url, headers: headers, body: post);
      _OidcLogin oidcLogin = (response?.statusCode == 200) ? _OidcLogin.fromJson(AppJson.decodeMap(response?.body)) : null;
      return (oidcLogin != null) ? _OidcLogin.fromOther(oidcLogin, redirectUrl: REDIRECT_URI) : null;
    }
    return null;
  }

  void _createOidcAuthenticationTimerIfNeeded() {
    if ((_oidcAuthenticationCompleters != null) && (_processingOidcAuthentication != true)) {
      if (_oidcAuthenticationTimer != null) {
        _oidcAuthenticationTimer.cancel();
      }
      _oidcAuthenticationTimer = Timer(Duration(milliseconds: 100), () {
        _completeOidcAuthentication(null);
        _oidcAuthenticationTimer = null;
      });
    }
  }

  void _cancelOidcAuthenticationTimer() {
    if(_oidcAuthenticationTimer != null){
      _oidcAuthenticationTimer.cancel();
      _oidcAuthenticationTimer = null;
    }
  }

  void _completeOidcAuthentication(bool success) {
    
    if (success == true) {
      NotificationService().notify(notifyLoginSucceeded);
    }
    else if (success == false) {
      NotificationService().notify(notifyLoginFailed);
    }
    NotificationService().notify(notifyLoginFinished);

    if (_oidcAuthenticationCompleters != null) {
      List<Completer<bool>> loginCompleters = _oidcAuthenticationCompleters;
      _oidcAuthenticationCompleters = null;

      for(Completer<void> completer in loginCompleters){
        completer.complete(success);
      }
    }
  }

  // Logout

  void logout() {
    if ((_token != null) || (_user != null)) {
      Storage().auth2Token = _token = null;
      Storage().auth2User = _user = null;
      
      Storage().auth2UiucToken = _uiucToken = null;
      
      _authCard = null;
      _saveAuthCardStringToCache(null);
      Storage().authCardTime = null;
      
      NotificationService().notify(notifyCardChanged);
      NotificationService().notify(notifyLoginChanged);
      NotificationService().notify(notifyLogout);
    }
  }

  // Refresh

  Future<Auth2Token> refreshToken() async {
    if ((Config().coreUrl != null) && (_token?.refreshToken != null)) {
      if (_refreshTokenFuture != null){
        Log.d("Auth2: will await refresh token");
        await _refreshTokenFuture;
        Log.d("Auth2: did await refresh token");
      }
      else {
        try {
          Log.d("Auth2: will refresh token");

          String url = "${Config().coreUrl}/services/auth/refresh";
          Map<String, String> headers = {
            'Content-Type': 'text/plain'
          };

          _refreshTokenFuture = Network().post(url, headers: headers, body: _token?.refreshToken);
          Response refreshTokenResponse = await _refreshTokenFuture;
          _refreshTokenFuture = null;

          if (refreshTokenResponse?.statusCode == 200) {
            Map<String, dynamic> responseJson = AppJson.decodeMap(refreshTokenResponse?.body);
            Auth2Token token = Auth2Token.fromJson(responseJson);
            if ((token != null) && token.isValid) {
              Log.d("Auth: did refresh token: ${token?.accessToken}");
              Storage().auth2Token = _token = token;

              Auth2Token uiucToken = Auth2Token.fromJson(AppJson.mapValue(responseJson['params']));
              Storage().auth2UiucToken = _uiucToken = ((uiucToken != null) && uiucToken.isValidUiuc) ? uiucToken : null;

              return token;
            }
            else {
              Log.d("Auth: failed to refresh token: ${refreshTokenResponse?.body}");
            }
          }
          else if(refreshTokenResponse?.statusCode == 400 || refreshTokenResponse?.statusCode == 401 || refreshTokenResponse?.statusCode == 403) {
            logout(); // Logout only on 400, 401 or 403. Do not do anything else for the rest of scenarios
          }
        }
        catch(e) {
          print(e.toString());
          _refreshTokenFuture = null; // make sure to clear this in case something went wrong.
        }
      }
    }
    return null;
  }

  // Auth Card

  Future<File> _getAuthCardCacheFile() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String cacheFilePath = join(appDocDir.path, _authCardName);
    return File(cacheFilePath);
  }

  Future<String> _loadAuthCardStringFromCache() async {
    try {
      return ((_authCardCacheFile != null) && await _authCardCacheFile.exists()) ? await _authCardCacheFile.readAsString() : null;
    }
    on Exception catch (e) {
      print(e.toString());
    }
    return null;
  }

  Future<void> _saveAuthCardStringToCache(String value) async {
    try {
      if (_authCardCacheFile != null) {
        if (value != null) {
          await _authCardCacheFile.writeAsString(value, flush: true);
        }
        else if (await _authCardCacheFile.exists()) {
          await _authCardCacheFile.delete();
        }
      }
    }
    on Exception catch (e) {
      print(e.toString());
    }
    return null;
  }

  Future<AuthCard> _loadAuthCardFromCache() async {
    return AuthCard.fromJson(AppJson.decodeMap(await _loadAuthCardStringFromCache()));
  }

  Future<String> _loadAuthCardStringFromNet() async {
    String url = Config().iCardUrl;
    String uin = _user?.getOrgMembership(Config().coreOrgId)?.getUserData('uin');
    String accessToken = _uiucToken?.accessToken;

    if (AppString.isStringNotEmpty(url) &&  AppString.isStringNotEmpty(uin) && AppString.isStringNotEmpty(accessToken)) {
      Response response = await Network().post(url, headers: {
        'UIN': uin,
        'access_token': accessToken
      });
      return (response?.statusCode == 200) ? response.body : null;
    }
    return null;
  }

  Future<void> _refreshAuthCardIfNeeded() async {
    int lastCheckTime = Storage().authCardTime;
    DateTime lastCheckDate = (lastCheckTime != null) ? DateTime.fromMillisecondsSinceEpoch(lastCheckTime) : null;
    DateTime lastCheckMidnight = AppDateTime.midnight(lastCheckDate);

    DateTime now = DateTime.now();
    DateTime todayMidnight = AppDateTime.midnight(now);

    // Do it one per day
    if ((lastCheckMidnight == null) || (lastCheckMidnight.compareTo(todayMidnight) < 0)) {
      if (await _refreshAuthCard() != null) {
        Storage().authCardTime = now.millisecondsSinceEpoch;
      }
    }
  }

  Future<AuthCard> _refreshAuthCard() async {
    String authCardString = await _loadAuthCardStringFromNet();
    AuthCard authCard = AuthCard.fromJson(AppJson.decodeMap((authCardString)));
    if ((authCard != null) && (authCard != _authCard)) {
      _authCard = authCard;
      await _saveAuthCardStringToCache(authCardString);
      NotificationService().notify(notifyCardChanged);
    }
    return authCard;
  }

  // Helpers

  static Future<void> _launchUrl(urlStr) async {
    try {
      if (await canLaunch(urlStr)) {
        await launch(urlStr);
      }
    }
    catch(e) {
      print(e);
    }
  }

}

class _OidcLogin {
  final String loginUrl;
  final String redirectUrl;
  final Map<String, dynamic> params;
  
  _OidcLogin({this.loginUrl, this.redirectUrl, this.params});

  factory _OidcLogin.fromOther(_OidcLogin value, { String loginUrl, String redirectUrl, Map<String, dynamic> params}) {
    return _OidcLogin(
      loginUrl: loginUrl ?? value?.loginUrl,
      redirectUrl: redirectUrl ?? value?.redirectUrl,
      params: params ?? value?.params
    );
  }

  factory _OidcLogin.fromJson(Map<String, dynamic> json) {
    return (json != null) ? _OidcLogin(
      loginUrl: AppJson.stringValue(json['login_url']),
      params: AppJson.mapValue(json['params'])
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'login_url' : loginUrl,
      'params': params
    };
  }  

}
