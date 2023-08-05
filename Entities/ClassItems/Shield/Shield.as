#include "Hitters"
#include "HittersKIWI"
#include "FirearmVars"
#include "Knocked"

const u16 BASH_INTERVAL = 90;

void onInit(CBlob@ this)
{
	CSprite@ sprite = this.getSprite();
	sprite.SetRelativeZ(10.0f);

	if (this.getName()=="shield") {
		this.Tag("medium weight");
	}
	this.Tag("shield");
	this.set_u32("next_bash", 0);
}

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob is null) return;
	
	AttachmentPoint@ point = blob.getAttachments().getAttachmentPointByName("PICKUP");
	if(point is null) return;
	CBlob@ holder = point.getOccupied();
	if(holder is null) return;
	
	const bool FLIP = holder.isFacingLeft();
	const f32 FLIP_FACTOR = FLIP ? -1: 1;
	const u16 ANGLE_FLIP_FACTOR = FLIP ? 180 : 0;
	
	f32 shield_dist = 6;
	this.ResetTransform();
	this.SetOffset(Vec2f(-shield_dist, 2)+blob.get_Vec2f("gun_trans_from_carrier")+(holder.isKeyPressed(key_down)?Vec2f(1,-2):Vec2f()));
	this.ScaleBy(1.0f, 1.0f);
	f32 angle_step = 45;
	this.RotateBy(Maths::Floor((getShieldAngle(holder)+holder.getAngleDegrees())/angle_step+(FLIP?0:1))*angle_step, Vec2f(shield_dist*FLIP_FACTOR, 0));
	if (getGameTime()<(blob.get_u32("next_bash")-10)) {
		//this.RotateBy(30*FLIP_FACTOR, Vec2f());
	}
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	CSprite@ sprite = this.getSprite();
	sprite.ResetTransform();
	sprite.SetOffset(Vec2f());
	sprite.RotateBy(-90, Vec2f());
}

bool checkIfHolderCanBash(CBlob@ this, CBlob@ holder)
{
	if (holder is null) return false;
	if (getGameTime()<this.get_u32("next_bash")) return false;
	if (!holder.isOnGround()) return false;
	if (!holder.isKeyPressed(key_action2)) return false;
	return true;
}

void doShieldBash(CBlob@ this, CBlob@ holder, f32 shield_angle)
{
	const bool FLIP = holder.isFacingLeft();
	const f32 FLIP_FACTOR = FLIP ? -1: 1;
	const u16 ANGLE_FLIP_FACTOR = FLIP ? 180 : 0;
	holder.AddForce(Vec2f(this.getName()=="shield"?300:400, -180*FLIP_FACTOR).RotateBy(ANGLE_FLIP_FACTOR));
	holder.getSprite().PlaySound("shield_hmm.ogg", 1.0f, holder.getSexNum() == 0 ? 1.0f : 1.5f);
	this.set_u32("next_bash", getGameTime()+BASH_INTERVAL);
}

void checkForBlobsToHit(CBlob@ this, CBlob@ holder)
{
	if (holder is null) return;
	const bool FLIP = holder.isFacingLeft();
	const f32 FLIP_FACTOR = FLIP ? -1: 1;
	const u16 ANGLE_FLIP_FACTOR = FLIP ? 180 : 0;
	
	for (int count = 0; count < holder.getTouchingCount(); ++count) {
		CBlob@ touching_blob = holder.getTouchingByIndex(count);
		if (touching_blob is null) continue;
		//tick period
		int bash_moment = this.getName()=="shield"?7:14;
		//you can't just move away your shield and bash an enemy
		bool has_right_direction = holder.getVelocity().x>0&&touching_blob.getPosition().x>holder.getPosition().x ||
			holder.getVelocity().x<0&&touching_blob.getPosition().x<holder.getPosition().x;
		//checking for the period
		bool can_bash = ((this.get_u32("next_bash")-getGameTime())>BASH_INTERVAL-bash_moment)&&((this.get_u32("next_bash")-getGameTime())<BASH_INTERVAL);
		if (touching_blob.isCollidable() &&
			can_bash &&
			isKnockable(touching_blob) &&
			has_right_direction &&
			!touching_blob.hasTag("invincible") &&
			!isKnocked(touching_blob))
		{
			//touching_blob.AddForce(Vec2f(150, -150*FLIP_FACTOR).RotateBy(ANGLE_FLIP_FACTOR));
			touching_blob.setVelocity(touching_blob.getVelocity()+holder.getVelocity());
			holder.setVelocity(Vec2f());
			SetDazzled(touching_blob, 45);
			holder.getSprite().PlaySound(this.getName()=="shield"?"BaseHitSound.ogg":"catapult_hit.ogg", 2.0f, 1.0f);
			this.sub_u32("next_bash", bash_moment+2);
		}
	}
}

void onTick(CBlob@ this)
{
	AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
	if(point is null) return;
	CBlob@ holder = point.getOccupied();
	if(holder is null) return;
	
	f32 shield_angle = getShieldAngle(holder);
	this.set_f32("shield_angle", shield_angle);
	this.setAngleDegrees(0);
	
	if (checkIfHolderCanBash(this, holder)) {
		doShieldBash(this, holder, shield_angle);
	}
	checkForBlobsToHit(this, holder);
}

void onRender(CSprite@ this)
{
	if (this is null) return;
	CBlob@ blob = this.getBlob();
	if (blob is null) return;
	CBlob@ localblob = getLocalPlayerBlob();
	if (localblob is null) return;
	AttachmentPoint@ point = blob.getAttachments().getAttachmentPointByName("PICKUP");
	if(point is null) return;
	CBlob@ holder = point.getOccupied();
	if(holder is null) return;
	if(holder !is localblob) return;
	CBlob@ carried = holder.getCarriedBlob();
	if(carried is null) return;
	if (!isClient()) return;
	
	const f32 SCALEX = getDriver().getResolutionScaleFactor();
	const f32 ZOOM = getCamera().targetDistance * SCALEX;
	CMap@ map = getMap();
	const bool FLIP = blob.isFacingLeft();
	const f32 FLIP_FACTOR = FLIP ? -1 : 1;
	const u16 ANGLE_FLIP_FACTOR = FLIP ? 180 : 0;
	
	Vec2f pos = blob.getInterpolatedScreenPos();
	GUI::DrawTextCentered("Shield "+carried.getHealth()*20+" HP", Vec2f(pos.x, pos.y + 24*ZOOM + Maths::Sin(getGameTime() / 10.0f) * 10.0f), SColor(0xfffffcf0));
	
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return true;
}

f32 getShieldAngle(CBlob@ this)
{
	const bool flip = this.isFacingLeft();
	const f32 flip_factor = flip ? -1: 1;
	const u16 angle_flip_factor = flip ? 180 : 0;
	
	Vec2f pos = this.getPosition();
 	Vec2f aimvector = this.getAimPos() - pos;
	f32 angle = aimvector.Angle() + this.getAngleDegrees();
	//return angle_flip_factor-angle;
    return constrainAngle(angle_flip_factor-(angle+flip_factor));
}