import 'dart:async';

import 'package:flutter/widgets.dart';

class PanelButton extends StatefulWidget
{
    final String _text;
    final double _height;
    final double _fontSize;
    final double _letterSpacing;
    final EdgeInsets _margin;
    final VoidCallback _onTap;
    final bool isEnabled;
    final bool isAccented;

    PanelButton(
        this._text, 
        this._height,
        this._fontSize,
        this._letterSpacing,
        this._margin,
        this._onTap,
        { 
            this.isEnabled: true,
            this.isAccented: false,
            Key key 
        }
    ) : super(key: key);

    @override
    State<StatefulWidget> createState() => new PanelButtonState(_text, _height, _fontSize, _letterSpacing, _margin, _onTap, isEnabled, isAccented);
}

class PanelButtonState extends State<PanelButton>
{
    static const Color enabledBackground = const Color.fromARGB(255, 22, 75, 81);
    static const Color enabledText = const Color.fromARGB(255, 167, 230, 237);
    static const Color disabledBackground = const Color.fromARGB(204, 9, 45, 51);
    static const Color disabledText = const Color.fromARGB(51, 167, 230, 237);
    static const Color accentedBackground = const Color.fromARGB(255, 86, 234, 246);
    static const Color accentedText = const Color.fromARGB(255, 3, 28, 32);
    static const Color pressedColor = const Color.fromARGB(255, 144, 8, 62);

    final String _text;
    final double _height;
    final double _fontSize;
    final double _letterSpacing;
    final EdgeInsets _margin;
    final VoidCallback _onTap;
    final bool _isEnabled;
    final bool _isAccented;
    
    bool _isPressed;

    PanelButtonState(this._text, this._height, this._fontSize, this._letterSpacing, this._margin, this._onTap, this._isEnabled, this._isAccented);

    void _onButtonPressed(TapDownDetails details)
    {
        setState(
            ()
            {
                this._isPressed = true;
            });
        this._onTap();
    }

    void _onButtonReleased(TapUpDetails details)
    {
        setState(
            ()
            {
                this._isPressed = false;
            });
        this._onTap();
    }

    @override
    Widget build(BuildContext context)
    {
        return new GestureDetector(
                    onTapDown: _onButtonPressed,
                    onTapUp: _onButtonReleased,
                    child: new Container(
                        margin: _margin,
                        decoration: new BoxDecoration(
                            borderRadius: new BorderRadius.circular(3.0), 
                            color: _isPressed ? pressedColor : _isAccented ? accentedBackground : (_isEnabled ? enabledBackground : disabledBackground)
                        ),
                        child: new Container(
                            height: _height,
                            alignment: Alignment.center,
                            child: new Text(
                                _text, 
                                style: 
                                    new TextStyle(
                                        color: _isAccented ? accentedText : (_isEnabled ? enabledText : disabledText),
                                        fontFamily: "Inconsolata", 
                                        fontWeight: FontWeight.w700, 
                                        fontSize: _fontSize, 
                                        decoration: TextDecoration.none, 
                                        letterSpacing: this._letterSpacing
                                )
                            )
                        )
                    )
                );
    }
}