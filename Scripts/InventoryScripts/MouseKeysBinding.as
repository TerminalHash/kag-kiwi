//script by Skemonde uwu
#include "KIWI_Locales"
#include "UpdateInventoryOnClick"

const u8 GRID_SIZE = 48;
const u8 GRID_PADDING = 32;
const Vec2f MENU_DIMS = Vec2f(3, 2);
Vec2f tool_pos = Vec2f_zero;

void onInit(CBlob@ this)
{
	this.set_u16("LMB_item_netid", 0);
	this.set_u16("MMB_item_netid", 0);
	this.set_u16("RMB_item_netid", 0);
	
	this.addCommandID("LMB_item_choosed");
	this.addCommandID("MMB_item_choosed");
	this.addCommandID("RMB_item_choosed");
}

void onTick(CBlob@ this)
{
	CBlob@ carried = this.getCarriedBlob();
	if(isServer() && (getGameTime()) % 30 == 0){
		this.Sync("LMB_item_netid", true);
		this.Sync("MMB_item_netid", true);
		this.Sync("RMB_item_netid", true);
	}
	u16 lmb_binded_id = this.get_u16("LMB_item_netid"),
		mmb_binded_id = this.get_u16("MMB_item_netid"),
		rmb_binded_id = this.get_u16("RMB_item_netid");
	CBlob@ lmb_binded = getBlobByNetworkID(lmb_binded_id),
		mmb_binded = getBlobByNetworkID(mmb_binded_id),
		rmb_binded = getBlobByNetworkID(rmb_binded_id);
	CControls@ controls = this.getControls();
	bool interacting = getHUD().hasButtons() || getHUD().hasMenus() || this.isAttached();
	if (!interacting && carried is null && controls !is null) {
		if (lmb_binded !is null) {
			if (this.getInventory().isInInventory(lmb_binded)) {
				if (controls.isKeyJustPressed(KEY_LBUTTON))
					this.SendCommand(this.getCommandID("LMB_item_choosed"));
			}
			else if (this.getCarriedBlob() !is lmb_binded)
				this.set_u16("LMB_item_netid", 0);
		}
		if (mmb_binded !is null) {
			if (this.getInventory().isInInventory(mmb_binded)) {
				if (controls.isKeyJustPressed(KEY_MBUTTON))
					this.SendCommand(this.getCommandID("MMB_item_choosed"));
			}
			else if (this.getCarriedBlob() !is mmb_binded)
				this.set_u16("MMB_item_netid", 0);
		}
		if (rmb_binded !is null) {
			if (this.getInventory().isInInventory(rmb_binded)) {
				if (controls.isKeyJustPressed(KEY_RBUTTON))
					this.SendCommand(this.getCommandID("RMB_item_choosed"));
			}
			else if (this.getCarriedBlob() !is rmb_binded)
				this.set_u16("RMB_item_netid", 0);
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	u16 lmb_binded_id = this.get_u16("LMB_item_netid"),
		mmb_binded_id = this.get_u16("MMB_item_netid"),
		rmb_binded_id = this.get_u16("RMB_item_netid");
	CBlob@ lmb_binded = getBlobByNetworkID(lmb_binded_id),
		mmb_binded = getBlobByNetworkID(mmb_binded_id),
		rmb_binded = getBlobByNetworkID(rmb_binded_id);
	bool interacting = getHUD().hasButtons() || getHUD().hasMenus() || this.isAttached();
	if (interacting) return;
	if(cmd == this.getCommandID("LMB_item_choosed"))
	{
		this.server_Pickup(lmb_binded);
	}
	if(cmd == this.getCommandID("MMB_item_choosed"))
	{
		this.server_Pickup(mmb_binded);
	}
	if(cmd == this.getCommandID("RMB_item_choosed"))
	{
		this.server_Pickup(rmb_binded);
	}
}

void onInit(CInventory@ this)
{
	this.getBlob().addCommandID("set item for LMB");
	this.getBlob().addCommandID("set item for MMB");
	this.getBlob().addCommandID("set item for RMB");
}

void onCreateInventoryMenu(CInventory@ this, CBlob@ forBlob, CGridMenu@ menu)
{
	CBlob@ blob = this.getBlob();
	if (blob is null) return;

	DrawMouseBindings(blob, menu, forBlob);
}

void DrawMouseBindings(CBlob@ this, CGridMenu@ menu, CBlob@ forBlob) {
	if (isClient())
		tool_pos = menu.getUpperLeftPosition() + Vec2f(MENU_DIMS.x/2,-MENU_DIMS.y/2)*GRID_SIZE - Vec2f(0, GRID_PADDING);
	UpdateMouseBindings(this, forBlob);
}

void UpdateMouseBindings(CBlob@ this, CBlob@ forBlob) {
	CGridMenu@ tool = CreateGridMenu(tool_pos, this, MENU_DIMS, "Bind items to mouse buttons");
	if (tool !is null)
	{
		tool.SetCaptionEnabled(false);
		tool.deleteAfterClick = false;
		tool.SetCaptionEnabled(true);
		
		CPlayer@ player = null;
		u16 lmb_binded_id = this.get_u16("LMB_item_netid"),
			mmb_binded_id = this.get_u16("MMB_item_netid"),
			rmb_binded_id = this.get_u16("RMB_item_netid");
		CBlob@ carried = null,
			lmb_binded = getBlobByNetworkID(lmb_binded_id),
			mmb_binded = getBlobByNetworkID(mmb_binded_id),
			rmb_binded = getBlobByNetworkID(rmb_binded_id);
		if (forBlob is null) {
			@player = this.getPlayer();
			@carried = this.getCarriedBlob();
		} else {
			@player = forBlob.getPlayer();
			@carried = forBlob.getCarriedBlob();
		}
		u16 carried_id = 0;
		if (carried !is null)
			carried_id = carried.getNetworkID();
		
		if (player !is null) {
			string player_name = "";
			player_name = player.getUsername();
			
			CBitStream params;
			params.write_u16(this.getNetworkID());
			params.write_u16(carried_id);
	
			AddIconToken("$LMB$", "Keys.png", Vec2f(16, 16), 8);
			AddIconToken("$RMB$", "Keys.png", Vec2f(16, 16), 9);
			AddIconToken("$MMB$", "Keys.png", Vec2f(16, 16), 11);
			CGridButton@ lmb_icon = tool.AddButton("$LMB$", "", Vec2f(1,1));
			if (lmb_icon !is null) {
				lmb_icon.clickable = false;
			}
			CGridButton@ mmb_icon = tool.AddButton("$MMB$", "", Vec2f(1,1));
			if (mmb_icon !is null) {
				mmb_icon.clickable = false;
			}
			CGridButton@ rmb_icon = tool.AddButton("$RMB$", "", Vec2f(1,1));
			if (rmb_icon !is null) {
				rmb_icon.clickable = false;
			}
			CGridButton@ l_button = tool.AddButton(((lmb_binded_id == 0 || lmb_binded is null)?"":("$"+lmb_binded.getName()+"$")), "", this.getCommandID("set item for LMB"), Vec2f(1, 1), params);
			if (l_button !is null)
			{
				l_button.SetHoverText(" LMB  ");
			}
			CGridButton@ m_button = tool.AddButton(((mmb_binded_id == 0 || mmb_binded is null)?"":("$"+mmb_binded.getName()+"$")), "", this.getCommandID("set item for MMB"), Vec2f(1, 1), params);
			if (m_button !is null)
			{
				m_button.SetHoverText(" MMB  ");
			}
			CGridButton@ r_button = tool.AddButton(((rmb_binded_id == 0 || rmb_binded is null)?"":("$"+rmb_binded.getName()+"$")), "", this.getCommandID("set item for RMB"), Vec2f(1, 1), params);
			if (r_button !is null)
			{
				r_button.SetHoverText(" RMB  ");
			}
		}
	}
}

void onCommand(CInventory@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getBlob().getCommandID("set item for LMB"))
	{
		u16 caller_id;
		if (!params.saferead_u16(caller_id)) return;
		u16 carried_id;
		if (!params.saferead_u16(carried_id)) return;
		CBlob@ caller = getBlobByNetworkID(caller_id);
		CBlob@ carried = getBlobByNetworkID(carried_id);
		caller.set_u16("LMB_item_netid", carried_id);
		
		UpdateInventoryOnClick(caller);
	}
	if (cmd == this.getBlob().getCommandID("set item for MMB"))
	{
		u16 caller_id;
		if (!params.saferead_u16(caller_id)) return;
		u16 carried_id;
		if (!params.saferead_u16(carried_id)) return;
		CBlob@ caller = getBlobByNetworkID(caller_id);
		CBlob@ carried = getBlobByNetworkID(carried_id);
		caller.set_u16("MMB_item_netid", carried_id);
		
		UpdateInventoryOnClick(caller);
	}
	if (cmd == this.getBlob().getCommandID("set item for RMB"))
	{
		u16 caller_id;
		if (!params.saferead_u16(caller_id)) return;
		u16 carried_id;
		if (!params.saferead_u16(carried_id)) return;
		CBlob@ caller = getBlobByNetworkID(caller_id);
		CBlob@ carried = getBlobByNetworkID(carried_id);
		caller.set_u16("RMB_item_netid", carried_id);
		
		UpdateInventoryOnClick(caller);
	}
}