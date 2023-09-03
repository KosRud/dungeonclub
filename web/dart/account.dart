import 'dart:async';
import 'dart:html';

import '../main.dart';
import 'game.dart';
import 'html_helpers.dart';
import 'notif.dart';
import 'panels/edit_game.dart' as edit_game;
import 'panels/panel_overlay.dart';

class Account {
  final List<Game> games;
  final _joinStream = StreamController<bool>.broadcast();
  final Map<String, dynamic> limits;
  int _lockJoin = 0;

  Account(Map<String, dynamic> json)
      : games = List.from(json['games'])
            .map((e) => Game(e['id'], e['name'], e['mine']))
            .toList(),
        limits = (json['limits'] ?? {}) {
    var token = json['token'];
    if (token != null) {
      window.localStorage['token'] = token;
    }
  }

  int getMediaBytesPerCampaign() {
    return limits["media_bytes_per_campaign"] as int;
  }

  int getPrefabsPerCampaign() {
    return limits["prefabs_per_campaign"] as int;
  }

  int getScenesPerCampaign() {
    return limits["scenes_per_campaign"] as int;
  }

  int getMapsPerCampaign() {
    return limits["maps_per_campaign"] as int;
  }

  int getCampaignsPerAccount() {
    return limits["campaigns_per_account"] as int;
  }

  int getPlayersPerCampaign() {
    return limits["players_per_campaign"] as int;
  }

  int getMovablesPerScene() {
    return limits["movable_per_scene"] as int;
  }


  Future<Game?> createNewGame() async {
    final game = await edit_game.displayPrepare();
    if (game != null) games.add(game);
    return game;
  }

  Future displayPickCharacterDialog(String name) async {
    var notif = HtmlNotification('<b>$name</b> wants to join.');
    document.title = '$name wants to join | $appName';

    var letIn = await notif.prompt();
    document.title = appName;

    if (!letIn) return null;

    _lockJoin++;
    var count = _lockJoin;
    for (var i = 1; i < count; i++) {
      await _joinStream.stream.first;
    }

    var completer = Completer<int>();
    var chars = user.session!.characters;

    var available = chars.where((c) => !c.hasJoined);

    if (available.isEmpty) {
      return HtmlNotification('Every available character is already assigned!')
          .display();
    }
    if (available.length == 1) {
      // Prevent adding multiple events to _joinStream simultaneously
      await Future.microtask(() => null);
      _lockJoin--;
      _joinStream.add(true);
      return available.first.id;
    }

    HtmlElement parent = queryDom('#charPick');
    HtmlElement roster = parent.queryDom('.roster');
    List.from(roster.children).forEach((e) => e.remove());

    parent.queryDom('span').innerHtml = "Pick <b>$name</b>'s Character";

    for (var ch in chars) {
      roster.append(DivElement()
        ..className = 'char'
        ..classes.toggle('reserved', ch.hasJoined)
        ..append(ImageElement(src: ch.image.url))
        ..append(SpanElement()..text = ch.name)
        ..onClick.listen((e) {
          completer.complete(ch.id);
        }));
    }

    overlayVisible = true;
    parent.classes.add('show');
    var result = await completer.future;

    overlayVisible = false;
    parent.classes.remove('show');

    unawaited(
        user.session!.connectionEvent.firstWhere((join) => join).then((_) {
      _lockJoin--;
      _joinStream.add(true);
    }));
    return result;
  }
}
