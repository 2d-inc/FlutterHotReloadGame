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

class PanelButtonState extends State<PanelButton> with SingleTickerProviderStateMixin
{
    static const Color enabledBackground = const Color.fromARGB(255, 22, 75, 81);
    static const Color enabledText = const Color.fromARGB(255, 167, 230, 237);
    static const Color disabledBackground = const Color.fromARGB(204, 9, 45, 51);
    static const Color disabledText = const Color.fromARGB(51, 167, 230, 237);
    static const Color accentedBackground = const Color.fromARGB(255, 86, 234, 246);
    static const Color accentedText = const Color.fromARGB(255, 3, 28, 32);
    // TODO: should check these colors
    static const Color pressedBackground = const Color.fromARGB(255, 144, 8, 62);
    static const Color pressedText = const Color.fromARGB(255, 242, 220, 253);

    final String _text;
    final double _height;
    final double _fontSize;
    final double _letterSpacing;
    final EdgeInsets _margin;
    final VoidCallback _onTap;
    final Color _backgroundColor;
    final Color _textColor;

    AnimationController _pressedColorController;
    Animation<Color> _buttonBackgroundAnimation;
    Animation<Color> _buttonTextAnimation;
    bool _isPressed = false;
    Color _currentBgColor;
    Color _currentTxtColor;

    PanelButtonState(this._text, this._height, this._fontSize, this._letterSpacing, this._margin, this._onTap, bool isEnabled, bool isAccented) :
        _backgroundColor = (isAccented ? accentedBackground : (isEnabled ? enabledBackground : disabledBackground)),
        _textColor = (isAccented ? accentedText : (isEnabled ? enabledText : disabledText))
        {
            _currentBgColor = _backgroundColor;
            _currentTxtColor = _textColor;
        }

    @override
    initState()
    {
        super.initState();
        _pressedColorController = new AnimationController(vsync: this)
                ..addListener(()
                    {
                        setState(()
                        {
                            _currentBgColor = _buttonBackgroundAnimation.value;
                            _currentTxtColor = _buttonTextAnimation.value;
                        });
                    }
                );
    }

    @override
    dispose()
    {
        _pressedColorController.dispose();
        super.dispose();
    }

    void _onButtonPressed(TapDownDetails details)
    {
        setState(
            ()
            {
                this._isPressed = true;

                _buttonBackgroundAnimation = new ColorTween(
                    begin: _backgroundColor,
                    end: pressedBackground,
                ).animate(_pressedColorController);
                _buttonTextAnimation = new ColorTween(
                    begin: _textColor,
                    end: pressedText,
                ).animate(_pressedColorController);
                _pressedColorController
                    ..value = 0.0
                    ..animateTo(1.0, curve: Curves.elasticOut, duration: const Duration(milliseconds: 50));
            });
        this._onTap();
    }

    void _onButtonReleased(TapUpDetails details)
    {
        setState(
            ()
            {
                _buttonBackgroundAnimation = new ColorTween(
                    begin: _currentBgColor,
                    end: _backgroundColor,
                ).animate(_pressedColorController);
                _buttonTextAnimation = new ColorTween(
                    begin: _currentTxtColor,
                    end: _textColor,
                ).animate(_pressedColorController);
                _pressedColorController
                    ..value = 0.0
                    ..animateTo(1.0, curve: Curves.easeOut, duration: const Duration(milliseconds: 150));
            });
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
                            color: _currentBgColor
                        ),
                        child: new Container(
                            height: _height,
                            alignment: Alignment.center,
                            child: new Text(
                                _text, 
                                style: 
                                    new TextStyle(
                                        color: _currentTxtColor,
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