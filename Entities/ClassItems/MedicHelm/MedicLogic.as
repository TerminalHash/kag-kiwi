const u8 MAX_BOMB_AMOUNT = 4;
const u32 BOMB_PRODUCING_INTERVAL = 90;

void onTick(CBlob@ this)
{
	initProperties(this);
	
	if (this.isKeyJustPressed(key_action3)&&this.getCarriedBlob()is null&&this.get_u8("current_bomb_amount")>0) {
		if (isServer()) {
			CBlob@ healnad = server_CreateBlob("healingbomb", this.getTeamNum(), this.getPosition());
			if (healnad !is null) {
				this.server_Pickup(healnad);
			}
		}
		this.set_u32("last_bomb_make", getGameTime());
		this.sub_u8("current_bomb_amount", 1);		
	}
	
	generateBomb(this);
}

void generateBomb(CBlob@ this)
{
	if ((this.get_u32("last_bomb_make")+BOMB_PRODUCING_INTERVAL) > getGameTime()) return;
	
	if (this.get_u8("current_bomb_amount")<MAX_BOMB_AMOUNT) {
		this.add_u8("current_bomb_amount", 1);
	}
	
	this.set_u32("last_bomb_make", getGameTime());
}

void initProperties(CBlob@ this)
{
	if (!this.exists("last_bomb_make"))
		this.set_u32("last_bomb_make", 0);
	if (!this.exists("current_bomb_amount"))
		this.set_u8("current_bomb_amount", 0);
}

void onRender(CSprite@ this)
{
	if (this is null) return;
	CBlob@ blob = this.getBlob();
	if (blob is null) return;
	CBlob@ localblob = getLocalPlayerBlob();
	if (localblob is null) return;
	if (localblob !is blob) return;
	if (!isClient()) return;
	
	Driver@ driver = getDriver();
	Vec2f screen_tl = Vec2f();
	Vec2f screen_br = Vec2f(driver.getScreenWidth(), driver.getScreenHeight());
	
	Vec2f gui_pos = Vec2f(screen_br.x-350, screen_tl.y+20);
	
	for (int bomb_id = 0; bomb_id<MAX_BOMB_AMOUNT; ++bomb_id) {
		GUI::DrawIcon("MedicGUI.png", (blob.get_u8("current_bomb_amount")>bomb_id?1:0), Vec2f(8, 16), gui_pos+Vec2f(bomb_id*32,0), 2.0f, blob.getTeamNum());
	}
	GUI::SetFont("menu");
	GUI::DrawTextCentered("Space to make\na Treatment Vial", gui_pos+Vec2f(65, 80), color_white);
}