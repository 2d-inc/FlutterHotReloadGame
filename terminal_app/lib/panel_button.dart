import 'package:flutter/widgets.dart';
import "game_controls/game_colors.dart";

class PanelButton extends StatefulWidget
{
    final String _text;
    final double _fontSize;
    final double _letterSpacing;
    final EdgeInsets _margin;
    final VoidCallback _onTap;
    final bool isEnabled;
    final bool isAccented;
    final double height;

    PanelButton(
        this._text, 
        this._fontSize,
        this._letterSpacing,
        this._margin,
        this._onTap,
        { 
            this.isEnabled: true,
            this.isAccented: false,
            this.height,
            Key key 
        }
    ) : super(key: key);

    @override
    State<StatefulWidget> createState() => new PanelButtonState();
}

class PanelButtonState extends State<PanelButton> with SingleTickerProviderStateMixin
{
    Color _backgroundColor;
    Color _textColor;

    AnimationController _pressedColorController;
    Animation<Color> _buttonBackgroundAnimation;
    Animation<Color> _buttonTextAnimation;
    Color _currentBgColor;
    Color _currentTxtColor;

    @override
    initState()
    {
        super.initState();
        setColors();
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
                _buttonBackgroundAnimation = new ColorTween(
                    begin: _backgroundColor,
                    end: GameColors.buttonPressedBackground,
                ).animate(_pressedColorController);
                _buttonTextAnimation = new ColorTween(
                    begin: _textColor,
                    end: GameColors.buttonPressedText,
                ).animate(_pressedColorController);
                _pressedColorController
                    ..value = 0.0
                    ..animateTo(1.0, curve: Curves.decelerate, duration: const Duration(milliseconds: 50));
            });
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
            }
        );

        widget._onTap();
    }

    setColors()
    {
        _backgroundColor = (widget.isAccented ? GameColors.buttonAccentedBackground : (widget.isEnabled ? GameColors.buttonEnabledBackground : GameColors.buttonDisabledBackground));
        _textColor = (widget.isAccented ? GameColors.buttonAccentedText : (widget.isEnabled ? GameColors.buttonEnabledText : GameColors.buttonDisabledText));
        _currentBgColor = _backgroundColor;
        _currentTxtColor = _textColor;
    }

    @override
    void didUpdateWidget(PanelButton oldWidget) 
    {
        setColors();
        super.didUpdateWidget(oldWidget);
    }

    @override
    Widget build(BuildContext context)
    {
        return new GestureDetector(
                    onTapDown: widget.isEnabled ? _onButtonPressed : null,
                    onTapUp: widget.isEnabled ? _onButtonReleased : null,
                    child: new Container(
                        height:widget.height,
                        margin: widget._margin,
                        decoration: new BoxDecoration(
                            borderRadius: new BorderRadius.circular(3.0), 
                            color: _currentBgColor
                        ),
                        child: new Container(
                            alignment: Alignment.center,
                            child: new Text(
                                widget._text, 
                                textAlign: TextAlign.center,
                                style: 
                                    new TextStyle(
                                        color: _currentTxtColor,
                                        fontFamily: "Inconsolata", 
                                        fontWeight: FontWeight.w700, 
                                        fontSize: widget._fontSize, 
                                        decoration: TextDecoration.none, 
                                        letterSpacing: widget._letterSpacing
                                )
                            )
                        )
                    )
                );
    }
}