package states;

import flixel.addons.transition.FlxTransitionableState;
import signals.Lifecycle;
import flixel.FlxG;
import flixel.tile.FlxTilemap;
import flixel.math.FlxRandom;
using extensions.FlxStateExt;



typedef DimensionedMapData = {
	mapData: Array<Int>,
	width: Int,
	height: Int,
}
class PlayState extends FlxTransitionableState {
	static inline var TILE_WIDTH:Int = 16;
	static inline var TILE_HEIGHT:Int = 16;

	var map:FlxTilemap;
	var rnd:FlxRandom = new FlxRandom();

	override public function create() {
		super.create();
		Lifecycle.startup.dispatch();

		FlxG.camera.pixelPerfectRender = true;
		var remap = [
		  1, 17
		];

		var m = directionalCave(35, 20,1, 99);
		map = new FlxTilemap();
		map.customTileRemap = remap;
		map.loadMapFromArray(m.mapData, m.width, m.height, AssetPaths.tiles__png, TILE_WIDTH, TILE_HEIGHT);
		add(map);
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);
	}

	override public function onFocusLost() {
		super.onFocusLost();
		this.handleFocusLost();
	}

	override public function onFocus() {
		super.onFocus();
		this.handleFocus();
	}

	private function staticMapData():DimensionedMapData {
		return {
			mapData: [
				1, 1, 1, 1, 1,
				1, 0, 0, 0, 1,
				1, 0, 0, 0, 1,
				1, 0, 0, 0, 1,
				1, 1, 1, 1, 1,
			],
			width: 5,
			height: 5
		} 
	}

	private inline function setValue(m:DimensionedMapData, x:Int, y:Int, value:Int) {
		if (x > m.width || y > m.height)
			throw "trying to set map data at impossible location(" + x + ", " + y + ")";

		m.mapData[y*m.width + x] = value;
	}

	private function directionalCave(mapWidth:Int, mapHeight:Int, roughness:Int, windyness:Int):DimensionedMapData {
		// mapWidth, mapHeight = size of the cave to be generated
		// roughness = How much the cave varies in width. This should be a rough value, and should not reflect exactly in the level created.
		// For simplicity's sake, roughness can go from 1 to 100.
		// windyness = How much the cave varies in positioning. How much a path through it needs to 'wind' and 'swerve'.
		// This should also be, for example, 1 to 100.

		// See http://www.roguebasin.com/index.php?title=Basic_directional_dungeon_generation
		
		// try to make a min segment of 3, but shrink if the map is really small.
		// XXX: seems like there should be a better way get a min of an Int
		var minSegment:Int = Math.round(Math.min(3, mapWidth - 2));

		// start with a map of all walls
		var m:DimensionedMapData = {
			mapData: [for (i in 0...mapWidth * mapHeight) 1],
			width: mapWidth,
			height: mapHeight
		};
		
		// start at the bottom, center of the map
		var startX = Math.round(mapWidth / 2) - 1;
		var startY = mapHeight - 2; // -1 for the 0 based index, -1 so we don't end up at the very bottom
		
		var maxWidth = mapWidth - startX - 1;
		var startWidth = rnd.int(minSegment,  maxWidth);
		
		var width = startWidth;
		var x = startX;
		var y = startY;
		for (x in startX...startX + startWidth)
			setValue(m, x, startY, 0);

		do {
			y--;

			// Check if a random number out of 100 is smaller than or equal to roughness.
			if (isRandomUnderThreshold(roughness)) {
				// If it is, roll a random number between -2 and 2 (excluding 0). Add this number to the current width.
				width += randomAdjustment();
				
				// If width is now smaller than 3, set it to 3. If larger than the map width, set it to the map width.
				width = clamp(width, minSegment, mapWidth - 1);
			}

			// Check if a random number out of 100 is smaller than or equal to windyness. 
			if (isRandomUnderThreshold(windyness)) {
				// If it is, roll a random number between -2 and 2 (excluding 0). Add this number to the current x. 
				x += randomAdjustment();

				// If x is now smaller than 0, set it to 0. If larger than the map width-3, set it to the map width-3.
				clamp(x, 1, mapWidth - minSegment - 1);
				
			}
			
			// Place a rectangle from current x, current y, to current x + width, current y.
			carveLine(m, x, x + width, y,  0);

		} while (y > 1);
		
		return m;
	}

	private function isRandomUnderThreshold(threshold:Int):Bool {
		return rnd.int(1, 100) <= threshold;
	}

	private function randomAdjustment():Int {
		var adjustmentPossibilities = [-2, -1, 1, 2];
		return adjustmentPossibilities[rnd.int(0, adjustmentPossibilities.length - 1)];
	}

	private function clamp(value:Int, lower:Int, upper:Int):Int {
		if (value > upper)
			return upper;

		if (value < lower)
			return lower;

		return value;
	}

	private function carveLine(m:DimensionedMapData, fromX:Int, toX:Int, y:Int, value:Int) {
		for (x in fromX...toX)
			setValue(m, x, y, value);

	}
}
