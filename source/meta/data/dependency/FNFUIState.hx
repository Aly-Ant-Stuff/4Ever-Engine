package meta.data.dependency;

import flixel.FlxG;
import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.ui.FlxUIState;

class FNFUIState extends FlxUIState
{
	//frontend
	private static var _traceCam:FlxCamera;
	private static var _traceGroup:FlxTypedGroup<FlxText>;
	//backend
	private static var _numLogs:Int = 1; //for when increase will update the last text position
	private static var _trackedLogs:Array<String> = [];

	override function create()
	{
		// for trace stuff
		_traceCam = new FlxCamera();
		_traceCam.bgColor.alpha = 0;
		FlxG.cameras.add(_traceCam);

		_traceGroup = new FlxTypedGroup<FlxText>();
		_traceGroup.cameras = [_traceCam];
		add(_traceGroup);

		// state stuffs
		if (!FlxTransitionableState.skipNextTransOut)
			openSubState(new FNFTransition(0.5, true));

		super.create();
	}

	var lastText:FlxText = null;
	public static function logTrace(log:String, type:TextType):Void
	{
		_trackedLogs.push(log);
		if (_traceCam != null && _traceGroup != null)
		{
			//_numLogs++;
			var color:FlxColor;
			var text = new FlxText(5, 0, FlxG.width, log, 22);
			switch (type)
			{
				case NORMAL:
					color = FlxColor.WHITE;
				case ERROR:
					color = FlxColor.RED;
				case NOTICE:
					color = FlxColor.GREEN;
			}
			//text.ID = _numLogs;
			text.setFormat(Paths.font('vcr.tff'), 22, color, FlxTextAlign.LEFT,  FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			text.y = (lastText != null ? lastText.height + 5 : 10);
			_traceGroup.add(text);
	
			new FlxTimer().start(3, function(t:FlxTimer) {
				FlxTween.tween(text, {alpha: 0.000001}, 0.5, {
					onComplete: function(tw:FlxTween) {
						//lastText = text;
						text.destroy();
					}
				});
			});
		}
	}

	override function destroy():Void
	{
		for (id in 0..._trackedLogs.length)
		{
			var log = _trackedLogs[id];
			_trackedLogs.remove(log);
		}
		super.destroy();
	}
}

enum TextType
{
	NORMAL;
	ERROR;
	NOTICE;
}
