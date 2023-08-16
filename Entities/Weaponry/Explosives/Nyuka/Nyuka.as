#include "Hitters.as";
#include "Explosion.as";

string[] particles = 
{
	"LargeSmoke",
	"Explosion.png"
};

void onInit(CBlob@ this)
{
	this.getShape().SetRotationsAllowed(true);
	
	// this.set_string("custom_explosion_sound", "bigbomb_explosion.ogg");
	this.set_bool("map_damage_raycast", true);
	this.set_Vec2f("explosion_offset", Vec2f(0, 16));
	
	this.set_u8("stack size", 1);
	this.set_f32("bomb angle", 90);
	
	// this.Tag("map_damage_dirt");
	
	this.Tag("explosive");
	
	this.maxQuantity = 1;
}

void onTick(CBlob@ this) {
	if (this.exists("death_time")) {
		this.setPosition(this.get_Vec2f("death_pos"));
		this.setAngleDegrees(0);
		CSprite@ sprite = this.getSprite();
		if (sprite !is null) {
			sprite.ResetTransform();
			sprite.RotateBy(this.get_f32("death_angle"), Vec2f());
		}
		if (!this.hasTag("made_sound")) {
			Sound::Play("kaboom.ogg", getDriver().getWorldPosFromScreenPos(getDriver().getScreenCenterPos()), 2.0f, 1);
			this.Tag("made_sound");
		}
		if (this.get_u32("death_time")<getGameTime()) {
			this.server_Die();
			//this.getSprite().PlaySound("kaboom", 2, 1);
			this.set_u32("death_time", -1);
		}
	}
}

void onDie(CBlob@ this)
{
	if (isServer() && this.hasTag("DoExplode"))
	{
		CBlob@ boom = server_CreateBlobNoInit("nukeexplosion");
		boom.setPosition(this.getPosition());
		boom.set_u8("boom_start", 0);
		boom.set_u8("boom_end", 80);
		//boom.set_f32("mithril_amount", 50);
		boom.set_f32("flash_distance", 256);
		boom.Tag("no mithril");
		//boom.Tag("no flash");
		boom.Init();
		killBlobsInRadius(this);
	}
}

void killBlobsInRadius(CBlob@ this, f32 max_range = 512.00f)
{
	CBlob@[] blobs;
	if (this.getMap().getBlobsInRadius(this.getPosition(), max_range, @blobs))
	{
		for (int i = 0; i < blobs.length; i++)
		{
			CBlob@ blob = blobs[i];
			if (blob.hasTag("invincible") || blob.getName()==this.getName()) continue;
			if (!this.getMap().rayCastSolidNoBlobs(blob.getPosition(), this.getPosition()))
			{
				blob.server_Die();
			}
		}
	}
}

bool canBePickedUp( CBlob@ this, CBlob@ byBlob )
{
	return !this.exists("death_time");
}

bool canBePutInInventory( CBlob@ this, CBlob@ inventoryBlob )
{
	return !this.canBePickedUp(inventoryBlob);
}

void onAttach( CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint )
{
	this.setAngleDegrees(0);
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (damage >= this.getHealth() && !this.hasTag("dead"))
	{
		this.Tag("DoExplode");
		this.set_f32("bomb angle", 90);
		//this.server_Die();
		this.set_u32("death_time", getGameTime()+(2.1f*getTicksASecond()));
		this.set_Vec2f("death_pos", this.getPosition());
		this.set_f32("death_angle", this.getAngleDegrees());
		this.Tag("dead");
		//this.getSprite().SetOffset(this.getSprite().getOffset()+Vec2f(0, 8));
	}
	
	return damage;
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal)
{
	if (blob !is null ? !blob.isCollidable() : !solid)
	{
		return;
	}

	f32 vellen = this.getOldVelocity().Length();
	if (vellen >= 8.0f && !this.hasTag("dead")) 
	{
		Vec2f dir = Vec2f(-normal.x, normal.y);
		
		this.Tag("DoExplode");
		this.set_f32("bomb angle", dir.Angle());
		//this.server_Die();
		this.set_u32("death_time", getGameTime()+(2.1f*getTicksASecond()));
		this.set_Vec2f("death_pos", this.getPosition());
		this.set_f32("death_angle", this.getAngleDegrees());
		this.getSprite().SetOffset(this.getSprite().getOffset()+Vec2f(0, 8));
		this.Tag("dead");
	}
}
