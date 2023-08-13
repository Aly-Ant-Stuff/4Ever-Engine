package gameObjects;

//flixel stuff
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;

//4ever engine dependecies
import gameObjects.background.*;
import meta.state.PlayState;
import meta.data.dependency.FNFSprite;
import meta.data.Conductor;
import meta.CoolUtil;

//other packages
import haxe.Json;
import sys.FileSystem;
import sys.io.File;

using StringTools;

typedef StageFile = {
	var objects:Null<Array<ObjectStruct>>;
	@:optional var groups:Null<Array<GroupStruct>>;
	@:optional var sounds:Null<Array<SoundStruct>>;
	var bf_position:Array<Float>;
	var gf_position:Array<Float>;
	var dad_position:Array<Float>;
	var camera_zoom:Float;
	var curStage:String;
}

typedef ObjectStruct = {
	var name_tag:String; //util for a event or something
	var image:String;
	var x:Float;
	var y:Float;
	var scale:Array<Float>;
	var scroll_factor:Array<Float>;
	var animated:Bool;
	@:optional var animations:Null<Array<AnimationStruct>>;
	@:optional var atlas:String;
	@:optional var object_front_of:Null<String>;
	@:optional var antialiasing:Null<Bool>;
	var object_class:String;
	var add_object:Bool;
}

typedef GroupStruct = {
	var name_tag:String;
	var image:String;
	var repeat_same_thing:Bool;
	var x:Float;
	var y:Float;
	var copy_x:Float;
	var copy_y:Float;
	var copy_times:Int;
	var animated:Bool;
	@:optional var animations:Array<AnimationStruct>;
	@:optional var atlas:Null<String>;
	@:optional var object_front_of:Null<String>;
	var antialiasing:Bool;
	var add_group:Bool;
}

typedef AnimationStruct = {
	var name:String;
	var prefix:String;
	var framerate:Int;
	var offsets:Array<Float>;
	var indices:Array<Int>;
	var loop:Bool;
	var auto_play:Bool;
}

typedef SoundStruct = {
	var name_tag:String;
	var path:String;
	var auto_play:Bool;
}


/**
	This is the stage class. It sets up everything you need for stages in a more organised and clean manner than the
	base game. It's not too bad, just very crowded. I'll be adding stages as a separate
	thing to the weeks, making them not hardcoded to the songs.
**/

class Stage extends FlxTypedGroup<FlxBasic>
{
	var halloweenBG:FNFSprite;
	var phillyCityLights:FlxTypedGroup<FNFSprite>;
	var phillyTrain:FNFSprite;
	var trainSound:FlxSound;

	public var limo:FNFSprite;

	public var grpLimoDancers:FlxTypedGroup<BackgroundDancer>;

	var fastCar:FNFSprite;

	var upperBoppers:FNFSprite;
	var bottomBoppers:FNFSprite;
	var santa:FNFSprite;

	var bgGirls:BackgroundGirls;
	public var gfForeground:FlxTypedGroup<FlxBasic>;
	public var foreground:FlxTypedGroup<FlxBasic>;
	public var curStage:String;
	public var stageObjects:Map<String, FNFSprite> = new Map<String, FNFSprite>();
	public var stageGroups:Map<String, FlxTypedGroup<FNFSprite>> = new Map<String, FlxTypedGroup<FNFSprite>>();
	public var stageSounds:Map<String, FlxSound> = new Map<String, FlxSound>();

	//i had to make this manually so respect me -AlyAnt0
	public var stageTemplate = '{
		"objects": [
			{
				"name_tag": "stageBackground",
				"image": "stage/stageback",
				"x": -600, 
				"y": -200,
				"scale": [1, 1],
				"scroll_factor": [0.9, 0.9],
				"animated": false,
				"animations": [],
				"antialiasing": true,
				"add_object": true
			},
			{
				"name_tag": "stageFront",
				"image": "stage/stagefront",
				"x": -650,
				"y": 600,
				"scale": [0.9, 0.9],
				"scroll_factor": [0.9, 0.9],
				"animated": false,
				"animations": [],
				"antialiasing": true,
				"add_object": true
			},
			{
				"name_tag": "stageCurtains",
				"image": "stage/stagecurtains",
				"x": -500,
				"y": -300,
				"scale": [0.9, 0.9],
				"scroll_factor": [1.3, 1.3],
				"animated": false,
				"animations": [],
				"antialiasing": true,
				"add_object": true
			}
		],
		"bf_position": [770, 450],
		"gf_position": [400, 130],
		"dad_position": [100, 100],
		"camera_zoom": 0.9,
		"curStage": "stageTemplate"
	}';
	var daPixelZoom = PlayState.daPixelZoom;

	public var curFile:StageFile = null; //initially its null for no error stuff

	public function new(curStage)
	{
		super();
		this.curStage = curStage;

		//i got so fucking hard coded -AlyAnt0
		var __base:String = SUtil.getStorageDirectory() + 'assets/images/backgrounds/' + curStage + '/';
		var __fileToLoad:String = '';
		var __path:String = '';
		if (FileSystem.exists(__base + _targetFile + '.json'))
			__fileToLoad = _targetFile;

		__path = __base + __fileToLoad + '.json';
		if (FileSystem.exists(__path))
		{
				curFile = Json.parse(File.getContent(__path));
				FlxG.log.add('it exists!!');
		} else {
				curFile = Json.parse(stageTemplate);
				FlxG.log.error('it doesent exists you DUMBASS!!!!!!');
		}

		/// get hardcoded stage type if chart is fnf style
		if (PlayState.determinedChartType == "FNF")
		{
			// this is because I want to avoid editing the fnf chart type
			// custom stage stuffs will come with forever charts
			switch (CoolUtil.spaceToDash(PlayState.SONG.song.toLowerCase()))
			{
				case 'spookeez' | 'south' | 'monster':
					curStage = 'spooky';
				case 'pico' | 'blammed' | 'philly-nice':
					curStage = 'philly';
				case 'milf' | 'satin-panties' | 'high':
					curStage = 'highway';
				case 'cocoa' | 'eggnog':
					curStage = 'mall';
				case 'winter-horrorland':
					curStage = 'mallEvil';
				case 'senpai' | 'roses':
					curStage = 'school';
				case 'thorns':
					curStage = 'schoolEvil';
				default:
					curStage = 'stage';
			}

			PlayState.curStage = curStage;
		}

		// to apply what objects will be front of the gf
		gfForeground = new FlxTypedGroup<FlxBasic>();
		// to apply to foreground use foreground.add(); instead of add();
		foreground = new FlxTypedGroup<FlxBasic>();

		/*
		switch (curStage)
		{
			case 'spooky':
				curStage = 'spooky';
				// halloweenLevel = true;

				var hallowTex = Paths.getSparrowAtlas('backgrounds/' + curStage + '/halloween_bg');

				halloweenBG = new FNFSprite(-200, -100);
				halloweenBG.frames = hallowTex;
				halloweenBG.animation.addByPrefix('idle', 'halloweem bg0');
				halloweenBG.animation.addByPrefix('lightning', 'halloweem bg lightning strike', 24, false);
				halloweenBG.animation.play('idle');
				halloweenBG.antialiasing = true;
				add(halloweenBG);

			// isHalloween = true;
			case 'philly':
				curStage = 'philly';

				var bg:FNFSprite = new FNFSprite(-100).loadGraphic(Paths.image('backgrounds/' + curStage + '/sky'));
				bg.scrollFactor.set(0.1, 0.1);
				add(bg);

				var city:FNFSprite = new FNFSprite(-10).loadGraphic(Paths.image('backgrounds/' + curStage + '/city'));
				city.scrollFactor.set(0.3, 0.3);
				city.setGraphicSize(Std.int(city.width * 0.85));
				city.updateHitbox();
				add(city);

				phillyCityLights = new FlxTypedGroup<FNFSprite>();
				add(phillyCityLights);

				for (i in 0...5)
				{
					var light:FNFSprite = new FNFSprite(city.x).loadGraphic(Paths.image('backgrounds/' + curStage + '/win' + i));
					light.scrollFactor.set(0.3, 0.3);
					light.visible = false;
					light.setGraphicSize(Std.int(light.width * 0.85));
					light.updateHitbox();
					light.antialiasing = true;
					phillyCityLights.add(light);
				}

				var streetBehind:FNFSprite = new FNFSprite(-40, 50).loadGraphic(Paths.image('backgrounds/' + curStage + '/behindTrain'));
				add(streetBehind);

				phillyTrain = new FNFSprite(2000, 360).loadGraphic(Paths.image('backgrounds/' + curStage + '/train'));
				add(phillyTrain);

				trainSound = new FlxSound().loadEmbedded(Paths.sound('train_passes'));
				FlxG.sound.list.add(trainSound);

				// var cityLights:FNFSprite = new FNFSprite().loadGraphic(AssetPaths.win0.png);

				var street:FNFSprite = new FNFSprite(-40, streetBehind.y).loadGraphic(Paths.image('backgrounds/' + curStage + '/street'));
				add(street);
			case 'highway':
				curStage = 'highway';
				PlayState.defaultCamZoom = 0.90;

				var skyBG:FNFSprite = new FNFSprite(-120, -50).loadGraphic(Paths.image('backgrounds/' + curStage + '/limoSunset'));
				skyBG.scrollFactor.set(0.1, 0.1);
				add(skyBG);

				var bgLimo:FNFSprite = new FNFSprite(-200, 480);
				bgLimo.frames = Paths.getSparrowAtlas('backgrounds/' + curStage + '/bgLimo');
				bgLimo.animation.addByPrefix('drive', "background limo pink", 24);
				bgLimo.animation.play('drive');
				bgLimo.scrollFactor.set(0.4, 0.4);
				add(bgLimo);

				grpLimoDancers = new FlxTypedGroup<BackgroundDancer>();
				add(grpLimoDancers);

				for (i in 0...5)
				{
					var dancer:BackgroundDancer = new BackgroundDancer((370 * i) + 130, bgLimo.y - 400);
					dancer.scrollFactor.set(0.4, 0.4);
					grpLimoDancers.add(dancer);
				}

				var overlayShit:FNFSprite = new FNFSprite(-500, -600).loadGraphic(Paths.image('backgrounds/' + curStage + '/limoOverlay'));
				overlayShit.alpha = 0.5;
				// add(overlayShit);

				// var shaderBullshit = new BlendModeEffect(new OverlayShader(), FlxColor.RED);

				// FlxG.camera.setFilters([new ShaderFilter(cast shaderBullshit.shader)]);

				// overlayShit.shader = shaderBullshit;

				var limoTex = Paths.getSparrowAtlas('backgrounds/' + curStage + '/limoDrive');

				limo = new FNFSprite(-120, 550);
				limo.frames = limoTex;
				limo.animation.addByPrefix('drive', "Limo stage", 24);
				limo.animation.play('drive');
				limo.antialiasing = true;

				fastCar = new FNFSprite(-300, 160).loadGraphic(Paths.image('backgrounds/' + curStage + '/fastCarLol'));
			// loadArray.add(limo);
			case 'mall':
				curStage = 'mall';
				PlayState.defaultCamZoom = 0.80;

				var bg:FNFSprite = new FNFSprite(-1000, -500).loadGraphic(Paths.image('backgrounds/' + curStage + '/bgWalls'));
				bg.antialiasing = true;
				bg.scrollFactor.set(0.2, 0.2);
				bg.active = false;
				bg.setGraphicSize(Std.int(bg.width * 0.8));
				bg.updateHitbox();
				add(bg);

				upperBoppers = new FNFSprite(-240, -90);
				upperBoppers.frames = Paths.getSparrowAtlas('backgrounds/' + curStage + '/upperBop');
				upperBoppers.animation.addByPrefix('bop', "Upper Crowd Bob", 24, false);
				upperBoppers.antialiasing = true;
				upperBoppers.scrollFactor.set(0.33, 0.33);
				upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
				upperBoppers.updateHitbox();
				add(upperBoppers);

				var bgEscalator:FNFSprite = new FNFSprite(-1100, -600).loadGraphic(Paths.image('backgrounds/' + curStage + '/bgEscalator'));
				bgEscalator.antialiasing = true;
				bgEscalator.scrollFactor.set(0.3, 0.3);
				bgEscalator.active = false;
				bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
				bgEscalator.updateHitbox();
				add(bgEscalator);

				var tree:FNFSprite = new FNFSprite(370, -250).loadGraphic(Paths.image('backgrounds/' + curStage + '/christmasTree'));
				tree.antialiasing = true;
				tree.scrollFactor.set(0.40, 0.40);
				add(tree);

				bottomBoppers = new FNFSprite(-300, 140);
				bottomBoppers.frames = Paths.getSparrowAtlas('backgrounds/' + curStage + '/bottomBop');
				bottomBoppers.animation.addByPrefix('bop', 'Bottom Level Boppers', 24, false);
				bottomBoppers.antialiasing = true;
				bottomBoppers.scrollFactor.set(0.9, 0.9);
				bottomBoppers.setGraphicSize(Std.int(bottomBoppers.width * 1));
				bottomBoppers.updateHitbox();
				add(bottomBoppers);

				var fgSnow:FNFSprite = new FNFSprite(-600, 700).loadGraphic(Paths.image('backgrounds/' + curStage + '/fgSnow'));
				fgSnow.active = false;
				fgSnow.antialiasing = true;
				add(fgSnow);

				santa = new FNFSprite(-840, 150);
				santa.frames = Paths.getSparrowAtlas('backgrounds/' + curStage + '/santa');
				santa.animation.addByPrefix('idle', 'santa idle in fear', 24, false);
				santa.antialiasing = true;
				add(santa);
			case 'mallEvil':
				curStage = 'mallEvil';
				var bg:FNFSprite = new FNFSprite(-400, -500).loadGraphic(Paths.image('backgrounds/mall/evilBG'));
				bg.antialiasing = true;
				bg.scrollFactor.set(0.2, 0.2);
				bg.active = false;
				bg.setGraphicSize(Std.int(bg.width * 0.8));
				bg.updateHitbox();
				add(bg);

				var evilTree:FNFSprite = new FNFSprite(300, -300).loadGraphic(Paths.image('backgrounds/mall/evilTree'));
				evilTree.antialiasing = true;
				evilTree.scrollFactor.set(0.2, 0.2);
				add(evilTree);

				var evilSnow:FNFSprite = new FNFSprite(-200, 700).loadGraphic(Paths.image("backgrounds/mall/evilSnow"));
				evilSnow.antialiasing = true;
				add(evilSnow);
			case 'school':
				curStage = 'school';

				// defaultCamZoom = 0.9;

				var bgSky = new FNFSprite().loadGraphic(Paths.image('backgrounds/' + curStage + '/weebSky'));
				bgSky.scrollFactor.set(0.1, 0.1);
				add(bgSky);

				var repositionShit = -200;

				var bgSchool:FNFSprite = new FNFSprite(repositionShit, 0).loadGraphic(Paths.image('backgrounds/' + curStage + '/weebSchool'));
				bgSchool.scrollFactor.set(0.6, 0.90);
				add(bgSchool);

				var bgStreet:FNFSprite = new FNFSprite(repositionShit).loadGraphic(Paths.image('backgrounds/' + curStage + '/weebStreet'));
				bgStreet.scrollFactor.set(0.95, 0.95);
				add(bgStreet);

				var fgTrees:FNFSprite = new FNFSprite(repositionShit + 170, 130).loadGraphic(Paths.image('backgrounds/' + curStage + '/weebTreesBack'));
				fgTrees.scrollFactor.set(0.9, 0.9);
				add(fgTrees);

				var bgTrees:FNFSprite = new FNFSprite(repositionShit - 380, -800);
				var treetex = Paths.getPackerAtlas('backgrounds/' + curStage + '/weebTrees');
				bgTrees.frames = treetex;
				bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
				bgTrees.animation.play('treeLoop');
				bgTrees.scrollFactor.set(0.85, 0.85);
				add(bgTrees);

				var treeLeaves:FNFSprite = new FNFSprite(repositionShit, -40);
				treeLeaves.frames = Paths.getSparrowAtlas('backgrounds/' + curStage + '/petals');
				treeLeaves.animation.addByPrefix('leaves', 'PETALS ALL', 24, true);
				treeLeaves.animation.play('leaves');
				treeLeaves.scrollFactor.set(0.85, 0.85);
				add(treeLeaves);

				var widShit = Std.int(bgSky.width * 6);

				bgSky.setGraphicSize(widShit);
				bgSchool.setGraphicSize(widShit);
				bgStreet.setGraphicSize(widShit);
				bgTrees.setGraphicSize(Std.int(widShit * 1.4));
				fgTrees.setGraphicSize(Std.int(widShit * 0.8));
				treeLeaves.setGraphicSize(widShit);

				fgTrees.updateHitbox();
				bgSky.updateHitbox();
				bgSchool.updateHitbox();
				bgStreet.updateHitbox();
				bgTrees.updateHitbox();
				treeLeaves.updateHitbox();

				bgGirls = new BackgroundGirls(-100, 190);
				bgGirls.scrollFactor.set(0.9, 0.9);

				if (PlayState.SONG.song.toLowerCase() == 'roses')
					bgGirls.getScared();

				bgGirls.setGraphicSize(Std.int(bgGirls.width * daPixelZoom));
				bgGirls.updateHitbox();
				add(bgGirls);
			case 'schoolEvil':
				var posX = 400;
				var posY = 200;
				var bg:FNFSprite = new FNFSprite(posX, posY);
				bg.frames = Paths.getSparrowAtlas('backgrounds/' + curStage + '/animatedEvilSchool');
				bg.animation.addByPrefix('idle', 'background 2', 24);
				bg.animation.play('idle');
				bg.scrollFactor.set(0.8, 0.9);
				bg.scale.set(6, 6);
				add(bg);

			default:
				setStageJson(curFile);
		}
		*/

	}

	// return the girlfriend's type
	public function returnGFtype(curStage)
	{
		var gfVersion:String = 'gf';

		switch (curStage)
		{
			case 'highway':
				gfVersion = 'gf-car';
			case 'mall' | 'mallEvil':
				gfVersion = 'gf-christmas';
			case 'school':
				gfVersion = 'gf-pixel';
			case 'schoolEvil':
				gfVersion = 'gf-pixel';
		}

		return gfVersion;
	}

	// get the dad's position
	public function dadPosition(curStage, boyfriend:Character, dad:Character, gf:Character, camPos:FlxPoint):Void
	{
		var characterArray:Array<Character> = [dad, boyfriend];
		for (char in characterArray)
		{
			switch (char.curCharacter)
			{
				case 'gf':
					char.setPosition(gf.x, gf.y);
					gf.visible = false;
					/*
						if (isStoryMode)
						{
							camPos.x += 600;
							tweenCamIn();
					}*/
					/*
						case 'spirit':
							var evilTrail = new FlxTrail(char, null, 4, 24, 0.3, 0.069);
							evilTrail.changeValuesEnabled(false, false, false, false);
							add(evilTrail);
					 */
			}
		}
	}

	//generate all the stage
	public function generateStage(boyfriend:Character, dad:Character, gf:Character, stage:Dynamic = null):Void
	{
		var file:StageFile = cast stage;
		PlayState.defaultCamZoom = file.camera_zoom;
		positionCharacters(boyfriend, dad, gf, file);
		this.curStage = file.curStage;

		// will create all the objects
		for (i in 0...file.objects.length)
		{
			/*
				_nameTag:String,
				_image:String,
				_x:Float,
				_y:Float,
				_scale:Array<Float>;
				_scroll_factor:Array<Float>;
				_animated:Bool,
				_animations:Array<AnimationStruct>,
				_atlas:String,
				_object_front_of:Null<String>,
				_antialiasing:Null<Bool>,
				_add_object:Bool
			*/ 
			var objData = file.objects[i];
			createStageObject(
				objData.name_tag,
				objData.image,
				objData.x,
				objData.y,
				objData.scale,
				objData.scroll_factor,
				objData.animated,
				objData.animations,
				objData.atlas,
				objData.object_front_of,
				objData.antialiasing,
				objData.object_class,
				objData.add_object
			);
			// TODO: MAKE THAT IT ADDS GROUPS AND SOUNDS FROM THE .JSON
		}
	}
	public function positionCharacters(boyfriend:Character, dad:Character, gf:Character, file:StageFile):Void
	{
		// REPOSITIONING
			if (boyfriend != null) boyfriend.setPosition(file.bf_position[0], file.bf_position[1]);
			if (gf != null) gf.setPosition(file.gf_position[0], file.gf_position[1]);
			if (dad != null) dad.setPosition(file.dad_position[0], file.dad_position[1]);
		/*
		PlayState.defaultCamZoom = file.camera_zoom;
		this.curStage = file.curStage;
		switch (curStage)
		{
			case 'highway':
				boyfriend.y -= 220;
				boyfriend.x += 260;

			case 'mall':
				boyfriend.x += 200;
				dad.x -= 400;
				dad.y += 20;

			case 'mallEvil':
				boyfriend.x += 320;
			case 'school':
				boyfriend.x += 200;
				boyfriend.y += 220;
				dad.x += 200;
				dad.y += 580;
				gf.x += 200;
				gf.y += 320;
			case 'schoolEvil':
				dad.x -= 150;
				dad.y += 50;
				boyfriend.x += 200;
				boyfriend.y += 220;
				gf.x += 180;
				gf.y += 300;
		}
		*/
	}

	var curLight:Int = 0;
	var trainMoving:Bool = false;
	var trainFrameTiming:Float = 0;

	var trainCars:Int = 8;
	var trainFinishing:Bool = false;
	var trainCooldown:Int = 0;
	var startedMoving:Bool = false;

	public function stageUpdate(curBeat:Int, boyfriend:Boyfriend, gf:Character, dadOpponent:Character)
	{
		// trace('update backgrounds');
		switch (PlayState.curStage)
		{
			case 'highway':
				// trace('highway update');
				if (grpLimoDancers != null) {
					grpLimoDancers.forEach(function(dancer:BackgroundDancer)
					{
						dancer.dance();
					});
				}
			case 'mall':
				upperBoppers.animation.play('bop', true);
				bottomBoppers.animation.play('bop', true);
				santa.animation.play('idle', true);

			case 'school':
				bgGirls.dance();

			case 'philly':
				if (!trainMoving)
					trainCooldown += 1;

				if (curBeat % 4 == 0)
				{
					var lastLight:FlxSprite = phillyCityLights.members[0];

					phillyCityLights.forEach(function(light:FNFSprite)
					{
						// Take note of the previous light
						if (light.visible == true)
							lastLight = light;

						light.visible = false;
					});

					// To prevent duplicate lights, iterate until you get a matching light
					while (lastLight == phillyCityLights.members[curLight])
					{
						curLight = FlxG.random.int(0, phillyCityLights.length - 1);
					}

					phillyCityLights.members[curLight].visible = true;
					phillyCityLights.members[curLight].alpha = 1;

					FlxTween.tween(phillyCityLights.members[curLight], {alpha: 0}, Conductor.stepCrochet * .016);
				}

				if (curBeat % 8 == 4 && FlxG.random.bool(30) && !trainMoving && trainCooldown > 8)
				{
					trainCooldown = FlxG.random.int(-4, 0);
					trainStart();
				}
		}
	}

	public function stageUpdateConstant(elapsed:Float, boyfriend:Boyfriend, gf:Character, dadOpponent:Character)
	{
		switch (PlayState.curStage)
		{
			case 'philly':
				if (trainMoving)
				{
					trainFrameTiming += elapsed;

					if (trainFrameTiming >= 1 / 24)
					{
						updateTrainPos(gf);
						trainFrameTiming = 0;
					}
				}
		}
	}

	// PHILLY STUFFS!
	function trainStart():Void
	{
		trainMoving = true;
		if (!trainSound.playing)
			trainSound.play(true);
	}

	function updateTrainPos(gf:Character):Void
	{
		if (trainSound.time >= 4700)
		{
			startedMoving = true;
			gf.playAnim('hairBlow');
		}

		var phillyTrainC:FNFSprite = stageObjects.get('phillyTrain');

		if (startedMoving)
		{
			phillyTrainC.x -= 400;

			if (phillyTrainC.x < -2000 && !trainFinishing)
			{
				phillyTrainC.x = -1150;
				trainCars -= 1;

				if (trainCars <= 0)
					trainFinishing = true;
			}

			if (phillyTrainC.x < -4000 && trainFinishing)
				trainReset(gf);
		}
	}

	function trainReset(gf:Character):Void
	{
		gf.playAnim('hairFall');
		phillyTrain.x = FlxG.width + 200;
		trainMoving = false;
		// trainSound.stop();
		// trainSound.time = 0;
		trainCars = 8;
		trainFinishing = false;
		startedMoving = false;
	}
/*
	var name_tag:String; //util for a event or something
	var image:String;
	var x:Float;
	var y:Float;
	var scale:Array<Float>;
	var scroll_factor:Array<Float>;
	var animated:Bool;
	@:optional var animations:Array<AnimationStruct>;
	@:optional var atlas:String;
	@:optional var object_front_of:Null<String>;
	@:optional var antialiasing:Null<Bool>;
	var add_object:Bool;
*/
	function createStageObject(
		_nameTag:String,
		_image:String,
		_x:Float,
		_y:Float,
		_scale:Array<Float>,
		_scroll_factor:Array<Float>,
		_animated:Bool,
		_animations:Array<AnimationStruct>,
		_atlas:String,
		_object_front_of:Null<String>,
		_antialiasing:Null<Bool>,
		_object_class:Null<String>,
		_add_object:Bool
	) {
		var obj:FNFSprite = new FNFSprite(_x, _y); //pra nao vira nulo

		//classes lololololo
		//pra atualiza depois
		/*
		if (_object_class != null)
		{
			switch (_object_class) {
				case '' | 'normal' | 'FNFSprite' |  null:
					obj = new FNFSprite(_x, _y);
				//e pros objetos tipo os capanga da mae da gf na week 4
			}
		}
		*/
		//backgrounds/' + curStage + '/weebTrees

		var _imagePath = 'backgrounds/' + _image;
		if (!_animated) {
			obj.loadGraphic(Paths.image(_imagePath));
		} else {
			switch (_atlas) {
				case "sparrow":
					obj.frames = Paths.getSparrowAtlas(_imagePath);
				case "packer":
					obj.frames = Paths.getPackerAtlas(_imagePath);
			}
			for (anim in _animations) 
			{
				if (anim != null) 
				{
					createObjectAnimation(
						obj,
						anim.name,
						anim.prefix,
						anim.framerate,
						anim.offsets,
						anim.indices,
						anim.loop,
						anim.auto_play,
						_atlas
					);
				}
			}
		}
		obj.scrollFactor.set(_scale[0], _scale[1]);
		obj.scale.set(_scale[0], _scale[1]);
		obj.updateHitbox();
		if (_antialiasing != null) obj.antialiasing = _antialiasing;
		if (_add_object) {
			if (_object_front_of != null)
			{
				switch(_object_front_of)
				{
					case "bf" | "0" | "boyfriend":
						//TODO: for front of the bf
					case "gf" | "1" | "girlfriend":
						gfForeground.add(obj);
					case "dad" | "2" | "opponent":
						//TODO: same thing for the bf
					case "all_chars":
						foreground.add(obj);
					case "back" | "":
						add(obj);
				}
			} else {
				add(obj);
			}
		}
		stageObjects.set(_nameTag, obj);
		//logTrace('Object from the added: ')
	}

	/*
	var name:String;
	var prefix:String;
	var framerate:Int;
	var offsets:Array<Float>;
	var indices:Array<Int>;
	var loop:Bool;
	var auto_play:Bool;
	*/
	public function createObjectAnimation(
		_obj:FNFSprite,
		_name:String,
		_prefix:String,
		_framerate:Int,
		_offsets:Array<Float>,
		_indices:Null<Array<Int>>,
		_loop:Bool,
		_autoplay:Bool,
		_atlas:String
	) {
		var animObject = _obj;
		if (_indices != null) {
			if (_atlas != "packer")
				animObject.animation.addByPrefix(_name, _prefix, _framerate, _loop);
		} else {
			if (_atlas != "packer")
				animObject.animation.addByIndices(_name, _prefix, _indices, "", _framerate, _loop);
		}
		// TODO: do for the packer atlas
		animObject.addOffset(_name, _offsets[0], _offsets[1]);
		if (_autoplay)
			animObject.playAnim(_name);
	}

	override function add(Object:FlxBasic):FlxBasic
	{
		if (Init.trueSettings.get('Disable Antialiasing') && Std.isOfType(Object, FlxSprite))
			cast(Object, FlxSprite).antialiasing = false;
		return super.add(Object);
	}
}
