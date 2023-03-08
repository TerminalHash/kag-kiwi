#include "FirearmVars"
#include "KIWI_Locales"

void onInit(CBlob@ this)
{
	this.setInventoryName(Names::assaultrifle);
	
	
	FirearmVars vars = FirearmVars();
	//GUN
	vars.T_TO_DIE 					= -1;
	vars.C_TAG						= "advanced_gun";
	vars.MUZZLE_OFFSET				= Vec2f(6, -2);
	vars.SPRITE_TRANSLATION			= Vec2f(7.5, -0.5);
	//AMMO
	vars.CLIP						= 30; 
	vars.TOTAL						= 0; 
	vars.AMMO_TYPE					= "highpow";
	//RELOAD
	vars.RELOAD_HANDFED_ROUNDS		= 0; 
	vars.EMPTY_RELOAD				= false;
	vars.RELOAD_TIME				= 60; 
	//FIRING
	vars.FIRE_INTERVAL				= 2; 
	vars.FIRE_AUTOMATIC				= true; 
	vars.ONOMATOPOEIA				= "ratta";
	//EJECTION
	vars.SELF_EJECTING				= true; 
	vars.CART_SPRITE				= "RoundCase.png"; 
	vars.CLIP_SPRITE				= "btr_clip.png";
	//MULTISHOT
	vars.BURST						= 0;
	vars.BURST_INTERVAL				= 2;
	vars.BUL_PER_SHOT				= 1; 
	vars.B_SPREAD					= 3; 
	vars.UNIFORM_SPREAD				= true;
	//TRAJECTORY
	vars.B_GRAV						= Vec2f(0,0);
	vars.B_SPEED					= 60; 
	vars.B_SPEED_RANDOM				= 2; 
	vars.B_TTL_TICKS				= 12; 
	vars.RICOCHET_CHANCE			= 10; 
	//DAMAGE
	vars.B_DAMAGE					= 2; 
	vars.B_HITTER					= HittersKIWI::bullet_rifle;
	vars.B_PENETRATION				= 0; 
	vars.B_KB						= Vec2f(0, 0); 
	//COINS
	vars.B_F_COINS					= 0;
	vars.B_O_COINS					= 0;
	//BULLET SOUNDS
	vars.S_FLESH_HIT				= "ArrowHitFlesh.ogg";
	vars.S_OBJECT_HIT				= "BulletImpact.ogg"; 
	//GUN SOUNDS
	vars.FIRE_SOUND					= "kastengewehr_shot.ogg";
	vars.FIRE_PITCH					= 1.8f;
	vars.CYCLE_SOUND				= "";
	vars.CYCLE_PITCH				= 1.0f;
	vars.LOAD_SOUND					= "smg_load.ogg";
	vars.LOAD_PITCH					= 0.7f;
	vars.RELOAD_SOUND				= "metal_slug_rechamber.ogg";
	vars.RELOAD_PITCH				= 1.0f;
	//BULLET SPRITES
	vars.BULLET_SPRITE				= "smg_bullet.png";
	vars.FADE_SPRITE				= "";
	//EXPLOSIVE LOGIC
	vars.EXPLOSIVE					= true;
	vars.EXPL_RADIUS 				= 16;
	vars.EXPL_DAMAGE 				= 15;
	vars.EXPL_MAP_RADIUS 			= 16;
	vars.EXPL_MAP_DAMAGE 			= 0.005;
	vars.EXPL_RAYCAST 				= false;
	vars.EXPL_TEAMKILL 				= false;
	this.set("firearm_vars", @vars);
}