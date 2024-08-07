#include "FirearmVars"
#include "KIWI_Locales"

void onInit(CBlob@ this)
{
	this.setInventoryName(Names::pocket_smg);
	
	
	FirearmVars vars = FirearmVars();
	//GUN
	vars.T_TO_DIE 					= -1;
	vars.C_TAG						= "advanced_gun";
	vars.MUZZLE_OFFSET				= Vec2f(-25,-3);
	vars.SPRITE_TRANSLATION			= Vec2f(5, 3);
	//AMMO
	vars.CLIP						= 20; 
	vars.TOTAL						= 0; 
	vars.AMMO_TYPE.push_back("lowcal");
	//RELOAD
	vars.RELOAD_HANDFED_ROUNDS		= 0; 
	vars.EMPTY_RELOAD				= false;
	vars.RELOAD_TIME				= 90;
	vars.RELOAD_ANGLE				= -30;
	//FIRING
	vars.FIRE_INTERVAL				= 1; 
	vars.FIRE_AUTOMATIC				= true; 
	vars.ONOMATOPOEIA				= "ratta";
	vars.FLASH_SPRITE				= "from_bullet";
	vars.COOLING_INTERVAL			= 15;
	//EJECTION
	vars.SELF_EJECTING				= true; 
	vars.CART_SPRITE				= "RoundCase.png"; 
	vars.CLIP_SPRITE				= "uzi_mag.png";
	//MULTISHOT
	vars.BURST						= 1;
	vars.BURST_INTERVAL				= vars.FIRE_INTERVAL;
	vars.BUL_PER_SHOT				= 1; 
	vars.B_SPREAD					= 40; 
	vars.UNIFORM_SPREAD				= false;
	//TRAJECTORY
	vars.B_GRAV						= Vec2f(0, 0);
	vars.B_SPEED					= 19; 
	vars.B_SPEED_RANDOM				= 5; 
	vars.RANGE						= getMap().tilesize*90;
	//DAMAGE
	vars.B_DAMAGE					= 20; 
	vars.B_HITTER					= HittersKIWI::kep;
	vars.B_PENETRATION				= 0;
	//BULLET SOUNDS
	vars.S_FLESH_HIT				= "ArrowHitFlesh.ogg";
	vars.S_OBJECT_HIT				= "BulletImpact.ogg"; 
	//GUN SOUNDS
	vars.FIRE_SOUND					= "machine_pistol_fire.ogg";
	vars.FIRE_PITCH					= 1.0f;
	vars.CYCLE_SOUND				= "";
	vars.CYCLE_PITCH				= 1.0f;
	vars.LOAD_SOUND					= "smg_load.ogg";
	vars.LOAD_PITCH					= 1.0f;
	vars.RELOAD_SOUND				= "metal_slug_fullok.ogg";
	vars.RELOAD_PITCH				= 1.0f;
	//BULLET SPRITES
	vars.BULLET_SPRITE				= "smg_bullet";
	vars.FADE_SPRITE				= "";
	this.set("firearm_vars", @vars);
}