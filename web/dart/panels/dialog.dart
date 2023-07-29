import 'dart:async';
import 'dart:html';

import '../html_helpers.dart';
import 'panel_overlay.dart';

final HtmlElement _overlay = queryDom('#overlay');

class Dialog<T> {
  final HtmlElement _e;
  final _completer = Completer<T>();
  InputElement _input;
  ButtonElement _okButton;

  Dialog(
    String title, {
    T Function() onClose,
    String okText = 'OK',
    String okClass,
  }) : _e = DivElement()..className = 'panel dialog' {
    _e
      ..append(HeadingElement.h2()..text = title)
      ..append(iconButton('times')
        ..className = 'close'
        ..onClick.listen((event) {
          _completer.complete(onClose());
        }))
      ..append(_okButton = ButtonElement()
        ..className = 'big' + (okClass != null ? ' $okClass' : '')
        ..text = okText
        ..onClick.listen((event) {
          _completer.complete(_input?.value ?? true);
        }));
  }

  Dialog addParagraph(String html) {
    _e.insertBefore(ParagraphElement()..innerHtml = html, _okButton);
    return this;
  }

  Dialog withInput({String type = 'text', String placeholder}) {
    _input = InputElement(type: type)
      ..placeholder = placeholder
      ..onKeyDown.listen((event) {
        if (event.keyCode == 13) {
          _completer.complete(_input.value as T);
        }
      });
    _e.insertBefore(_input, _okButton);
    return this;
  }

  void close() {
    _e.classes.remove('show');
    unawaited(
        Future.delayed(Duration(seconds: 1)).then((value) => _e.remove()));
    overlayVisible = false;
  }

  Future<T> display() async {
    overlayVisible = true;
    _overlay.append(_e);
    _e.innerText; // Trigger reflow
    _e.classes.add('show');
    (_input ?? _okButton).focus();

    var result = await _completer.future;
    close();
    return result;
  }
}

class ConstantDialog {
  final HtmlElement _e;

  ConstantDialog(String title) : _e = DivElement()..className = 'panel dialog' {
    _e.append(HeadingElement.h2()..text = title);
  }

  void addParagraph(String html) {
    _e.append(ParagraphElement()..innerHtml = html);
  }

  void append(Element element) {
    _e.append(element);
  }

  void display() {
    overlayVisible = true;
    _overlay.append(_e);
    _e.innerText; // Trigger reflow
    _e.classes.add('show');
  }

  void close() async {
    _e.classes.remove('show');
    overlayVisible = false;
    await Future.delayed(Duration(seconds: 1));
    _e.remove();
  }
}
