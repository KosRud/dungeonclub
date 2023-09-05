import 'dart:async';
import 'dart:html';

import 'package:dungeonclub/actions.dart';

import '../main.dart';
import 'account.dart';
import 'communication.dart';
import 'home.dart' as home;
import 'notif.dart';
import 'section_page.dart';
import 'session/demo.dart';
import 'session/session.dart';

class User {
  Account? _account;
  Account? get account => _account;

  bool get registered => account != null;
  bool get isInDemo => _session?.isDemo ?? false;

  Session? _session;
  Session? get session => _session;

  Future<StateError?> joinSession(String id, [String? name]) async {
    var s = await socket.request(GAME_JOIN, {
      'id': id,
      if (name != null) 'name': name,
    });
    if (s is String) return StateError(s);

    _session = Session(id, s['name'], s['dm'] != null);
    _onSessionJoin(false, s);
    return null;
  }

  void joinFromJson(Map<String, dynamic> s, bool instantEdit) {
    _session = Session(s['id'], s['name'], s['dm'] != null);
    _onSessionJoin(instantEdit, s);
  }

  void joinDemo() {
    var demo = _session = DemoSession();
    demo.initializeDemo();
    _onSessionJoin(false);
  }

  void _onSessionJoin(bool instantEdit, [Map<String, dynamic>? s]) {
    if (s != null) _session!.fromJson(s, instantEdit: instantEdit);

    showPage('session');
    home.iconWall.stop();

    Future.delayed(Duration(seconds: 1), () {
      for (var vid in querySelectorAll('#home video')) {
        vid.remove();
      }
    });
  }

  void onMaintenanceScheduled(Map<String, dynamic> params) async {
    int? timestamp = params['shutdown'];
    if (timestamp == null) return;

    var d = DateTime.fromMillisecondsSinceEpoch(timestamp);

    var hour = d.hour.toString().padLeft(2, '0');
    var min = d.minute.toString().padLeft(2, '0');

    HtmlNotification(
            '''<b>Attention, please!</b> $appName will be down for a couple of
            minutes <br> for maintenance purposes,
            starting at $hour:$min!''')
        .display();

    var now = DateTime.now().millisecondsSinceEpoch;
    await Future.delayed(Duration(milliseconds: timestamp - now + 3000));

    window.location.href = homeUrl;
  }

  void onActivate(Map<String, dynamic> accJson) {
    _account = Account(accJson);
    home.onLogin();
  }

  Future<bool> login(String email, String password,
      {bool rememberMe = true}) async {
    var response = await socket.request(
      ACCOUNT_LOGIN,
      {
        'email': email,
        'password': password,
        'remember': rememberMe,
      },
    );
    if (response != null) {
      onActivate(response);
      return true;
    }
    return false;
  }

  Future<bool> loginToken(String token) async {
    var response = await socket.request(ACCOUNT_LOGIN, {'token': token});
    if (response != null) {
      onActivate(response);
      return true;
    }
    return false;
  }

  int get mediaBytesPerCampaign => account?.mediaBytesPerCampaign ?? 0;
  int get prefabsPerCampaign => account?.prefabsPerCampaign ?? 0;
  int get scenesPerCampaign => account?.scenesPerCampaign ?? 0;
  int get mapsPerCampaign => account?.mapsPerCampaign ?? 0;
  int get campaignsPerAccount => account?.campaignsPerAccount ?? 0;
  int get playersPerCampaign => account?.playersPerCampaign ?? 0;
  int get tokensPerScene => account?.tokensPerScene ?? 0;
}
