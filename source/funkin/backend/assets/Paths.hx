package funkin.backend.assets;

import flixel.graphics.frames.FlxFramesCollection;
import haxe.io.Path;
import funkin.backend.assets.LimeLibrarySymbol;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import funkin.backend.assets.ModsFolder;
import funkin.backend.scripting.Script;
import animateatlas.AtlasFrameMaker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.graphics.FlxGraphic;

using StringTools;

class Paths
{
	/**
	 * Preferred sound extension for the game's audio files.
	 * Currently is set to `mp3` for web targets, and `ogg` for other targets.
	 */
	inline public static final SOUND_EXT = #if web "mp3" #else "ogg" #end;

	public static var assetsTree:AssetsLibraryList;

	public static var tempFramesCache:Map<String, FlxFramesCollection> = [];

	public static function init() {
		FlxG.signals.preStateSwitch.add(function() {
			tempFramesCache.clear();
		});
	}

	public static inline function getPath(file:String, ?library:String)
		return library != null ? '$library:assets/$library/$file' : 'assets/$file';

	public static inline function video(key:String)
		return getPath('videos/$key.mp4');

	public static inline function ndll(key:String)
		return getPath('ndlls/$key.ndll');

	inline static public function file(file:String, ?library:String)
		return getPath(file, library);

	inline static public function txt(key:String, ?library:String)
		return getPath('data/$key.txt', library);

	inline static public function ini(key:String, ?library:String)
		return getPath('data/$key.ini', library);

	inline static public function fragShader(key:String, ?library:String)
		return getPath('shaders/$key.frag', library);

	inline static public function vertShader(key:String, ?library:String)
		return getPath('shaders/$key.vert', library);

	inline static public function xml(key:String, ?library:String)
		return getPath('data/$key.xml', library);

	inline static public function json(key:String, ?library:String)
		return getPath('data/$key.json', library);

	inline static public function ps1(key:String, ?library:String)
		return getPath('data/$key.ps1', library);

	static public function sound(key:String, ?library:String)
		return getPath('sounds/$key.$SOUND_EXT', library);

	inline static public function soundRandom(key:String, min:Int, max:Int, ?library:String)
		return sound(key + FlxG.random.int(min, max), library);

	inline static public function music(key:String, ?library:String)
		return getPath('music/$key.$SOUND_EXT', library);

	inline static public function voices(song:String, difficulty:String = "normal")
	{
		var diff = getPath('songs/${song.toLowerCase()}/song/Voices-${difficulty.toLowerCase()}.$SOUND_EXT', null);
		return OpenFlAssets.exists(diff) ? diff : getPath('songs/${song.toLowerCase()}/song/Voices.$SOUND_EXT', null);
	}

	inline static public function inst(song:String, difficulty:String = "normal")
	{
		var diff = getPath('songs/${song.toLowerCase()}/song/Inst-${difficulty.toLowerCase()}.$SOUND_EXT', null);
		return OpenFlAssets.exists(diff) ? diff : getPath('songs/${song.toLowerCase()}/song/Inst.$SOUND_EXT', null);
	}

	static public function image(key:String, ?library:String, checkForAtlas:Bool = false)
	{
		if (checkForAtlas) {
			var atlasPath = getPath('images/$key/spritemap.png', library);
			var multiplePath = getPath('images/$key/1.png', library);
			if (atlasPath != null && OpenFlAssets.exists(atlasPath)) return atlasPath.substr(0, atlasPath.length - 14);
			if (multiplePath != null && OpenFlAssets.exists(multiplePath)) return multiplePath.substr(0, multiplePath.length - 6);
		}
		return getPath('images/$key.png', library);
	}

	inline static public function script(key:String, ?library:String, isAssetsPath:Bool = false) {
		var scriptPath = isAssetsPath ? key : getPath(key, library);
		if (!OpenFlAssets.exists(scriptPath)) {
			var p:String;
			for(ex in Script.scriptExtensions) {
				p = '$scriptPath.$ex';
				if (OpenFlAssets.exists(p)) {
					scriptPath = p;
					break;
				}
			}
		}
		return scriptPath;
	}

	static public function chart(song:String, ?difficulty:String = "normal"):String {
		difficulty = difficulty.toLowerCase();
		song = song.toLowerCase();

		return getPath('songs/$song/charts/$difficulty.json', null);
	}

	static public function character(character:String):String {
		return getPath('data/characters/$character.xml', null);
	}

	inline static public function font(key:String)
	{
		return getPath('fonts/$key');
	}

	inline static public function obj(key:String) {
		return getPath('models/$key.obj');
	}

	inline static public function dae(key:String) {
		return getPath('models/$key.dae');
	}

	inline static public function md2(key:String) {
		return getPath('models/$key.md2');
	}

	inline static public function md5(key:String) {
		return getPath('models/$key.md5');
	}

	inline static public function awd(key:String) {
		return getPath('models/$key.awd');
	}

	inline static public function getSparrowAtlas(key:String, ?library:String)
		return FlxAtlasFrames.fromSparrow(image(key, library), file('images/$key.xml', library));

	inline static public function getSparrowAtlasAlt(key:String)
		return FlxAtlasFrames.fromSparrow('$key.png', '$key.xml');

	inline static public function getPackerAtlas(key:String, ?library:String)
		return FlxAtlasFrames.fromSpriteSheetPacker(image(key, library), file('images/$key.txt', library));

	inline static public function getPackerAtlasAlt(key:String)
		return FlxAtlasFrames.fromSpriteSheetPacker('$key.png', '$key.txt');


	/**
	 * Gets frames at specified path.
	 * @param key Path to the frames
	 * @param library (Additional) library to load the frames from.
	 */
	public static function getFrames(key:String, assetsPath:Bool = false, ?library:String) {
		if (tempFramesCache.exists(key)) {
			var frames = tempFramesCache[key];
			if (frames.parent != null && frames.parent.bitmap != null && frames.parent.bitmap.readable)
				return frames;
			else
				tempFramesCache.remove(key);
		}
		return tempFramesCache[key] = loadFrames(assetsPath ? key : Paths.image(key, library, true));
	}


	/**
	 * Loads frames from a specific image path. Supports Sparrow Atlases, Packer Atlases, and multiple spritesheets.
	 * @param path Path to the image
	 * @param Unique Whenever the image should be unique in the cache
	 * @param Key Key to the image in the cache
	 * @param SkipAtlasCheck Whenever the atlas check should be skipped.
	 * @return FlxFramesCollection Frames
	 */
	static function loadFrames(path:String, Unique:Bool = false, Key:String = null, SkipAtlasCheck:Bool = false):FlxFramesCollection {
		var noExt = Path.withoutExtension(path);

		if (Assets.exists('$noExt/1.png')) {
			// MULTIPLE SPRITESHEETS!!

			var graphic = FlxG.bitmap.add("flixel/images/logo/default.png", false, '$noExt/mult');
			var frames = FlxAtlasFrames.findFrame(graphic);
			if (frames != null)
				return frames;

			trace("no frames yet for multiple atlases!!");
			var spritesheets = [];
			var cur = 1;
			var finalFrames = new FlxFramesCollection(graphic, ATLAS);
			while(Assets.exists('$noExt/$cur.png')) {
				spritesheets.push(loadFrames('$noExt/$cur.png'));
				cur++;
			}
			for(frames in spritesheets)
				if (frames != null && frames.frames != null)
					for(f in frames.frames)
						if (f != null) {
							finalFrames.frames.push(f);
							f.parent = frames.parent;
						}
			return finalFrames;
		} else if (!SkipAtlasCheck && Assets.exists('$noExt/Animation.json')
		&& Assets.exists('$noExt/spritemap.json')
		&& Assets.exists('$noExt/spritemap.png')) {
			return AtlasFrameMaker.construct(noExt);
		} else if (Assets.exists('$noExt.xml')) {
			return Paths.getSparrowAtlasAlt(noExt);
		} else if (Assets.exists('$noExt.txt')) {
			return Paths.getPackerAtlasAlt(noExt);
		}

		var graph:FlxGraphic = FlxG.bitmap.add(path, Unique, Key);
		if (graph == null)
			return null;
		return graph.imageFrame;
	}
	static public function getFolderDirectories(key:String, addPath:Bool = false, source:AssetsLibraryList.AssetSource = BOTH):Array<String> {
		if (!key.endsWith("/")) key += "/";
		var content = assetsTree.getFolders('assets/$key', source);
		if (addPath) {
			for(k=>e in content)
				content[k] = '$key$e';
		}
		return content;
	}
	static public function getFolderContent(key:String, addPath:Bool = false, source:AssetsLibraryList.AssetSource = BOTH):Array<String> {
		// designed to work both on windows and web
		if (!key.endsWith("/")) key += "/";
		var content = assetsTree.getFiles('assets/$key', source);
		if (addPath) {
			for(k=>e in content)
				content[k] = '$key$e';
		}
		return content;
		/*
		if (!key.endsWith("/")) key = key + "/";

		if (ModsFolder.currentModFolder == null && !scanSource)
			return getFolderContent(key, false, addPath, true);

		var folderPath:String = scanSource ? getAssetsPath(key) : getLibraryPathForce(key, 'mods/${ModsFolder.currentModFolder}');
		var libThing = new LimeLibrarySymbol(folderPath);
		var library = libThing.library;

		if (library is openfl.utils.AssetLibrary) {
			var lib = cast(libThing.library, openfl.utils.AssetLibrary);
			@:privateAccess
			if (lib.__proxy != null) library = lib.__proxy;
		}

		var content:Array<String> = [];
		#if MOD_SUPPORT
		if (library is funkin.backend.assets.ModsAssetLibrary) {
			// easy task, can immediately scan for files!
			var lib = cast(library, funkin.backend.assets.ModsAssetLibrary);
			content = lib.getFiles(libThing.symbolName);
			if (addPath)
				for(i in 0...content.length)
					content[i] = '$folderPath${content[i]}';
		} else #end {
			@:privateAccess
			for(k=>e in library.paths) {
				if (k.toLowerCase().startsWith(libThing.symbolName.toLowerCase())) {
					if (addPath) {
						if (libThing.libraryName != "")
							content.push('${libThing.libraryName}:$k');
						else
							content.push(k);
					} else {
						var barebonesFileName = k.substr(libThing.symbolName.length);
						if (!barebonesFileName.contains("/"))
							content.push(barebonesFileName);
					}
				}
			}
		}

		if (includeSource) {
			var sourceResult = getFolderContent(key, false, addPath, true);
			for(e in sourceResult)
				if (!content.contains(e))
					content.push(e);
		}

		return content;
		*/
	}
}
