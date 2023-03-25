#include "Hitters.as";
#include "HittersKIWI.as";
#include "CommonHitFXs.as";
#include "FleshHitFXs.as";
#include "SteelHitFXs.as";

//don't forget to put a DamageProcessing.as right after this script in blob's cfg!!!

void onInit(CBlob@ this)
{
	this.Tag("steel");
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{	
	bool do_damage = false;
	
	// steel guys don't get more than 1 HP of damage from gunfire
	switch (customData)
	{
		//heavy machine guns and rifles with a 100% chance deal damage (and keep their damage)
		case HittersKIWI::bullet_rifle:
		case HittersKIWI::bullet_hmg:
			damage *= 1; break;
			
		//50% chance smg bullet will do damage + cube of damage up to 100% starting from 3 damage
		case HittersKIWI::bullet_pistol:
			do_damage = XORRandom(30) < Maths::Min(30, 14+Maths::Pow(damage,3));
			do_damage ? damage = 1 : damage = 0; break;
		
		//10% chance shotgun buckshot will do damage
		case HittersKIWI::pellet:
			do_damage = XORRandom(10) == 0;
			do_damage ? damage = 1 : damage = 0; break;
			
		case Hitters::fire:
		case Hitters::burn:
			this.hasTag("flesh") ? damage *= 1 : damage = 0; break;
			
		default:
			damage *= 1;
	}
	
	// blobs that have the script get only damage multiple to 1 heart in vanilla terms or half a heart in KIWI terms(1 HP)
	return Maths::Round(damage/1);
}