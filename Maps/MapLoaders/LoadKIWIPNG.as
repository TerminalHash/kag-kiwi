// киви

#include "BasePNGLoader"
#include "MinimapHook"
#include "addCharacterToBlob"
#include "Edward"
#include "Tunes"

namespace KIWI_colors
{
	enum color
	{
		armory = 0xff4c565d,
		zombie_portal = 0xffb575f9,
		camp = 0xff5b6bf6,
		edward = 0xffc02020,
		campfire = 0xffdf7126,
		mercury_lamp = 0xffe0e050,
		cave_door = 0xff4d1f11,
		boombox = 0xff877b5c,
		boombox_tape = 0xffa69871,
		sandbag = 0xffffccaa,
		heavy_mg = 0xff4d443c,
		m_tank = 0xff504010,
		drill = 0xffd27801,
		
		nothing = 0xffffffff
	};
}

class KIWIPNGLoader : PNGLoader
{
	KIWIPNGLoader()
	{
		super();
	}
	
	void handlePixel(const SColor &in pixel, int offset) override
	{
		PNGLoader::handlePixel(pixel, offset);
		int map_center_x = map.tilemapwidth/2,
			struct_pos_x = map.getTileWorldPosition(offset).x/map.tilesize,
			blue = 0,
			red = 1,
			//first half of map with this color will be blue and the left one will colored red
			team_colored = struct_pos_x < map_center_x ? blue : red,
			elven = 2,
			undead = 3,
			neutral = -1;
			
		CBlob@ blob_to_spawn = null;
			
		//autotile(offset);
			
		switch (pixel.color)
		{
			case KIWI_colors::armory:
				spawnBlob(map, "armory", offset, team_colored, true, Vec2f(0, 0));
				autotile(offset); break;
				
			case KIWI_colors::drill:
				spawnBlob(map, "drill", offset, team_colored, false, Vec2f(0, 0));
				autotile(offset); break;
			
			case KIWI_colors::zombie_portal:
				spawnBlob(map, "zombieportal", offset, undead, true, Vec2f(-4, -4));
				autotile(offset); break;
				
			case KIWI_colors::sandbag:
				if (mapHasNeighbourPixel(offset)) break;
				spawnBlob(map, "sandbag", offset, neutral, false, mapHasNeighbourPixel(offset, false)?Vec2f(4, 0):Vec2f_zero);
				//getMap().SetTile(offset, getMap().getTile(offset-1).type);
				autotile(offset); break;
				
			case map_colors::blue_main_spawn:
			case map_colors::red_main_spawn:
			case KIWI_colors::camp:
				if (mapHasNeighbourPixel(offset)) break;
				spawnBlob(map, "camp", offset, team_colored, true, mapHasNeighbourPixel(offset, false)?Vec2f(4, 0):Vec2f_zero);
				autotile(offset); break;
				
			case KIWI_colors::edward:
				spawnBlob(map, "ed", offset, elven, false, Vec2f(-4, -4));
				autotile(offset); break;
				
			case KIWI_colors::campfire:
				spawnBlob(map, "campfire", offset, neutral, true, Vec2f(-4, 0));
				autotile(offset); break;
				
			case KIWI_colors::mercury_lamp:
				spawnBlob(map, "mercurylamp", offset, neutral, true, Vec2f(0, 0));
				autotile(offset); break;
				
			case KIWI_colors::m_tank:
				@blob_to_spawn = spawnBlob(map, "tankhull", offset, team_colored, false, Vec2f(0, 0));
				if (blob_to_spawn is null) break;
				
				blob_to_spawn.SetFacingLeft(team_colored==1?true:false);
				
				autotile(offset); break;
				
			case KIWI_colors::heavy_mg:
				@blob_to_spawn = spawnBlob(map, "sentry", offset, team_colored, true, Vec2f(-4, -4));
				if (blob_to_spawn is null) break;
				
				blob_to_spawn.SetFacingLeft(team_colored==1?true:false);
				
				autotile(offset); break;
				
			case KIWI_colors::boombox:
				@blob_to_spawn = spawnBlob(map, "boombox", offset, neutral, false, Vec2f(0, 0));
				if (blob_to_spawn is null) break;
				
				//blob_to_spawn.set_u32("tune", 9);
				//blob_to_spawn.getSprite().SetEmitSound(tunes[9]);
				
				autotile(offset); break;
				
			case KIWI_colors::boombox_tape:
				@blob_to_spawn = spawnBlob(map, "tape", offset, neutral, false, Vec2f(0, 0));
				if (blob_to_spawn is null) break;
				blob_to_spawn.set_u32("customData", 1);
				
				autotile(offset); break;
				
			case KIWI_colors::cave_door:
				spawnBlob(map, "cavedoor", offset, elven, true, Vec2f(-4, -4));
				autotile(offset); break;
		};
	}
};

bool mapHasNeighbourPixel(int offset, bool left_neighbour = true)
{
	CMap@ map = getMap();
	
	CFileImage map_image(map.getMapName());
	if (!map_image.canRead()) return false;
	//print("map name "+map.getMapName());
	
	map_image.setPixelPosition(map.getTileSpacePosition(offset));
	SColor initial_color = map_image.readPixel();
	map_image.setPixelPosition(map.getTileSpacePosition(offset+(left_neighbour?-1:1)));
	SColor neighbour_color = map_image.readPixel();
	//print("init color ("+initial_color.getRed()+", "+initial_color.getGreen()+", "+initial_color.getBlue()+")");
	//print("neighbour color ("+neighbour_color.getRed()+", "+neighbour_color.getGreen()+", "+neighbour_color.getBlue()+")");
	return neighbour_color == initial_color;
}

bool LoadMap(CMap@ map, const string& in fileName)
{
	KIWIPNGLoader loader();

	MiniMap::Initialise();

	return loader.loadMap(map, fileName);
}
