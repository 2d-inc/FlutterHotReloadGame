import 'package:flutter/widgets.dart';

import "../decorations/game_colors.dart";

/// A [PanelButton] has three possible states:
/// 1. Inactive: A button that's present but doesn't respond to tap events.
/// 2. Active: A button that response to tap events.
/// 3. Accented: A button that responds to tap events and has a bright cyan color.
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

/// A [State] for the PanelButton is necessary in order to animate it upon tap events.
class PanelButtonState extends State<PanelButton> with SingleTickerProviderStateMixin
{
    Color _backgroundColor;
    Color _textColor;
    Color _borderColor;

    /// A single [AnimationController] will take care of animating all the properties at the same time.
    AnimationController _pressedColorController;
    /// This element will animate three parameters: 
    /// 1. Color of the background;
    /// 2. Color of its text;
    /// 3. Color of its border.
    Animation<Color> _buttonBackgroundAnimation;
    Animation<Color> _buttonTextAnimation;
    Animation<Color> _buttonBorderAnimation;
    /// State variables to perform the animation.
    Color _currentBgColor;
    Color _currentTxtColor;
    Color _currentBorderColor;

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
                            _currentBorderColor = _buttonBorderAnimation.value;
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
                _buttonBorderAnimation = new ColorTween(
                    begin: _currentBorderColor,
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
                _buttonBorderAnimation = new ColorTween(
                    begin: _currentBorderColor,
                    end: _borderColor,
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
        _borderColor = _backgroundColor;
        _currentBgColor = _backgroundColor;
        _currentTxtColor = _textColor;
        _currentBorderColor = _backgroundColor;
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
                            border: new Border.all(color:_currentBorderColor, width:2.0),
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