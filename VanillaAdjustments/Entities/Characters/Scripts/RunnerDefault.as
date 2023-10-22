#include "RunnerCommon.as";
#include "Hitters.as";
#include "KnockedCommon.as"
#include "FireCommon.as"
#include "Help.as"
#include "UpdateInventoryOnClick.as"

void onInit(CBlob@ this)
{
	this.getCurrentScript().removeIfTag = "dead";
	this.Tag("medium weight");

	//default player minimap dot - not for migrants
	if (this.getName() != "migrant")
	{
		this.SetMinimapVars("GUI/Minimap/MinimapIcons.png", 8, Vec2f(8, 8));
	}

	this.set_s16(burn_duration , 130);
	this.set_f32("heal amount", 0.0f);

	//fix for tiny chat font
	this.SetChatBubbleFont("hud");
	this.maxChatBubbleLines = 4;

	InitKnockable(this);
}

void onTick(CBlob@ this)
{
	if (Maths::Abs(this.getVelocity().x)>0.2f)
		this.setAngleDegrees(0+this.getVelocity().x*3);
	
	this.Untag("prevent crouch");
	DoKnockedUpdate(this);
}

// pick up efffects
// something was picked up

void onAddToInventory(CBlob@ this, CBlob@ blob)
{
	if (!blob.hasTag("quick_detach"))
		this.getSprite().PlaySound("/PutInInventory.ogg");
}

void onRender( CSprite@ this )
{
	CBlob@ blob = this.getBlob();
	if (blob is null) return;
	
	Vec2f bubble_center = blob.getInterpolatedPosition()-Vec2f(0, 24);
	
	const u32 LAST_MSG = blob.get_u32("last chat tick");
	const string MESSAGE = blob.get_string("last chat msg");
	Vec2f message_dims = Vec2f();
	GUI::SetFont("menu");
	GUI::GetTextDimensions(MESSAGE, message_dims);
	
	if (getGameTime()>(LAST_MSG+Maths::Max(60, MESSAGE.length()*2))) return;
	Vec2f pane_center_screen = getDriver().getScreenPosFromWorldPos(bubble_center);
	
	Vec2f pane_tl = pane_center_screen-Vec2f(message_dims.x/2, message_dims.y/2)-Vec2f(1, 1)*8;
	Vec2f pane_br = pane_center_screen+Vec2f(message_dims.x/2, message_dims.y/2)+Vec2f(1, 1)*8;
	
	GUI::DrawBubble(pane_tl, pane_br);
	GUI::DrawText(MESSAGE, pane_tl+Vec2f(1, 1)*4, pane_br-Vec2f(1, 1)*4, SColor(0xff000000), false, false, false);
	GUI::SetFont("default");
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	if (!attached.hasTag("quick_detach"))
		this.getSprite().PlaySound("/Pickup.ogg");

	this.ClearButtons();

	if (getNet().isClient())
	{
		RemoveHelps(this, "help throw");

		if (!attached.hasTag("activated"))
			SetHelp(this, "help throw", "", getTranslatedString("${ATTACHED}$Throw    $KEY_C$").replace("{ATTACHED}", getTranslatedString(attached.getName())), "", 2);
	}

	CBlob@ carried = this.getCarriedBlob();
	if (carried is null) return;
	if (!carried.isAttached()) return;
	
	if (carried.hasTag("detach on seat in vehicle") && attached.hasTag("vehicle")) {
		if (!this.server_PutInInventory(carried))
			carried.server_DetachFromAll();
	}
	
	if (carried.hasTag("detach on seat in TANK") && attached.hasTag("tank")) {
		carried.server_DetachFromAll();
	}
	// check if we picked a player - don't just take him out of the box
	/*if (attached.hasTag("player"))
	this.server_DetachFrom( attached ); CRASHES*/
}

// set the Z back
// The baseZ is assumed to be 0
void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	const bool FLIP = this.isFacingLeft();
	const f32 FLIP_FACTOR = FLIP ? -1 : 1;
	const u16 ANGLE_FLIP_FACTOR = FLIP ? 180 : 0;
	this.getSprite().SetZ(0.0f);
	this.getSprite().SetRelativeZ(0.0f);
	
	if (isServer() && detached !is null && detached.hasTag("firearm")) {
		detached.setPosition(detached.getPosition()+Vec2f(detached.getWidth()/2,0).RotateBy(detached.get_f32("gunangle")+ANGLE_FLIP_FACTOR,Vec2f()));
	}
	
	if (this.hasTag("has_inventory_opened"))
		UpdateInventoryOnClick(this);
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	bool isSleeper = !(this.get_string("sleeper_name").empty()||!this.exists("sleeper_name"));
	return this.hasTag("migrant") || this.hasTag("dead") || isSleeper;
}
