//script by Skemonde uwu
#include "KIWI_Locales"
#include "UpdateInventoryOnClick"
#include "FirearmVars"

const u8 GRID_SIZE = 48;
const u8 GRID_PADDING = 12;

void onInit(CInventory@ this)
{
	this.getBlob().addCommandID("change altfire");
}

void onCreateInventoryMenu(CInventory@ this, CBlob@ forBlob, CGridMenu@ menu)
{
	CBlob@ blob = this.getBlob();
	if (blob is null) return;

	DrawAvailableAttachments(blob, menu, forBlob);
}

void DrawAvailableAttachments(CBlob@ this, CGridMenu@ menu, CBlob@ forBlob) {
	Vec2f inventory_space = this.getInventory().getInventorySlots();
	string[] available_attachments;
	CInventory@ inv = this.getInventory();
	if (inv is null) return;
	CBlob@ carried = this.getCarriedBlob();
	if (carried is null) return;
	//if not a gun
	if (!carried.exists("clip")) return;
	
	for (int counter = 0; counter<inv.getItemsCount(); ++counter) {
		CBlob@ item = inv.getItem(counter);
		
		//no nulls
		if (item is null) continue;
		
		//if not a gun attachment item
		if (!item.exists("alt_fire_item")||(item.hasScript("StandardFire.as")&&item.getName()!="combatknife")) continue;
		
		//if already is added
		if (available_attachments.find(item.getName())>-1) continue;
		
		available_attachments.push_back(item.getName());
	}
	if (available_attachments.size()<1) return;
	const Vec2f MENU_DIMS = Vec2f(1, available_attachments.size());
	//const Vec2f TOOL_POS = menu.getUpperLeftPosition() - Vec2f(GRID_PADDING, 0) - Vec2f(1, 0) * GRID_SIZE / 2;
	const Vec2f TOOL_POS = Vec2f(menu.getUpperLeftPosition().x-MENU_DIMS.x*GRID_SIZE/2-GRID_PADDING, menu.getUpperLeftPosition().y+(MENU_DIMS.y+2)*GRID_SIZE/2);
	CGridMenu@ tool = CreateGridMenu(TOOL_POS, this, MENU_DIMS, "");
	if (tool !is null)
	{
		tool.SetCaptionEnabled(false);
		
		for (int button_idx = 0; button_idx<available_attachments.size(); button_idx++) {
			CBlob@ item = inv.getItem(available_attachments[button_idx]);
			CBitStream params;
			params.write_u16(carried.getNetworkID());
			params.write_u16(item.getNetworkID());
			
			CGridButton@ button = tool.AddButton("$"+item.getName()+"$", "", this.getCommandID("change altfire"), Vec2f(1, 1), params);
			if (button !is null)
			{
				button.SetHoverText("Attach "+item.getInventoryName()+" to your gun!\n");
				if (item.get_u8("alt_fire_item") == carried.get_u8("override_alt_fire")) {
					button.SetEnabled(false);
					button.SetHoverText("You've already got that attachment on your gun!");
				}
			}
		}
	}
}

void onCommand(CInventory@ this, u8 cmd, CBitStream @params)
{
	CBlob@ blob = this.getBlob();
	if (blob is null) return;
	if(cmd == blob.getCommandID("change altfire"))
	{
		u16 gun_id, item_id;
		if (!params.saferead_u16(gun_id)) return;
		if (!params.saferead_u16(item_id)) return;
		CBlob@ gun = getBlobByNetworkID(gun_id);
		CBlob@ item = getBlobByNetworkID(item_id);
		if (gun is null || item is null) return;
		
		gun.set_u8("override_alt_fire", item.get_u8("alt_fire_item"));
		if (item.exists("alt_fire_interval"))
			gun.set_u8("override_altfire_interval", item.get_u16("alt_fire_interval"));
			
		if (item.getName()=="naderitem") {
			FirearmVars@ vars;
			if (!gun.get("firearm_vars", @vars)) return;
			
			if (vars.AMMO_TYPE.size()<2) {
				vars.AMMO_TYPE.push_back("froggy");
			} else {
				vars.AMMO_TYPE[1].opAssign("froggy");
			}
		} else {
			FirearmVars@ vars;
			if (!gun.get("firearm_vars", @vars)) return;
			if (vars.AMMO_TYPE.size()>1)
				vars.AMMO_TYPE.erase(1);
		}
		
		item.server_Die();
	}
}