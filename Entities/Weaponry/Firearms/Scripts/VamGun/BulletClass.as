

//Main classes for bullets
#include "BulletCase.as";
#include "BulletParticle.as";
#include "HittersKIWI.as";
#include "Explosion.as";

const SColor trueWhite = SColor(255,255,255,255);
Driver@ PDriver = getDriver();
const int ScreenX = getDriver().getScreenWidth();
const int ScreenY = getDriver().getScreenWidth();


class BulletObj
{
    CBlob@ hoomanShooter;
    CBlob@ gunBlob;

    BulletFade@ Fade;

    Vec2f TrueVelocity;
    Vec2f CurrentPos;
    Vec2f BulletGrav;
    Vec2f RenderPos;
    Vec2f OldPos;
    Vec2f LastPos;
    Vec2f Gravity;
    Vec2f KB;

    f32 StartingAimPos;
    f32 lastDelta;
    
    f32 Damage;
    u8 DamageType;
    
    u16[] TargetsPierced;
    u8 Pierces;
    bool Ricochet;

    u8 TeamNum;
    u8 Speed;

    string FleshHitSound;
    string ObjectHitSound;

    string Texture = "";
    Vec2f SpriteSize;
    

    u8 TimeLeft;

    bool FacingLeft;


    
	BulletObj(CBlob@ humanBlob, CBlob@ gun, f32 angle, Vec2f pos)
	{
        CurrentPos = pos;

        //Gun Vars
        BulletGrav	= gun.get_Vec2f("grav");
        Damage   	= gun.get_f32("damage");
        DamageType	= gun.get_u8("damage_type");
        TeamNum  	= gun.getTeamNum();
        TimeLeft 	= gun.get_u8("TTL");
        KB       	= gun.get_Vec2f("KB");
        Speed    	= gun.get_u8("speed")+XORRandom(gun.get_u8("random_speed")+1);
        Pierces  	= gun.get_u8("pierces");
			
        Ricochet 	= (XORRandom(100) < gun.get_u8("ricochet"));
        
        //Sound Vars
        FleshHitSound  = gun.get_string("flesh_hit_sound");
        ObjectHitSound = gun.get_string("object_hit_sound");
        
        //Sprite Vars
        Texture = gun.get_string("SpriteBullet");
        SpriteSize = Vec2f(16,16);
        
        //Misc Vars
        @hoomanShooter = humanBlob;
        FacingLeft = hoomanShooter.isFacingLeft();
        StartingAimPos = angle;
        OldPos     = CurrentPos;
        LastPos    = CurrentPos;
		RenderPos  = CurrentPos;

        @gunBlob   = gun;
        lastDelta = 0;
        
        //Fade
        if(gunBlob.exists("SpriteFade") && !v_fastrender){
			string fadeTexture = gunBlob.get_string("SpriteFade");
			if(!fadeTexture.empty()){ //No point even giving ourselves a fade if it doesn't have a texture
				@Fade = BulletFade(CurrentPos);
				Fade.Texture = fadeTexture;
				bullet_holder.addFade(Fade);
			}
		}
	}

    void SetStartAimPos(Vec2f aimPos, bool isFacingLeft)
    {
        Vec2f aimvector = aimPos - CurrentPos;
        StartingAimPos = isFacingLeft ? -aimvector.Angle()+180.0f : -aimvector.Angle();
    }

    bool onFakeTick(CMap@ map)
    {
        //map.debugRaycasts = true;
        //Time to live check
        TimeLeft--;
        if(TimeLeft == 0)
        {
            return true;
        }
        //End
        
        

        //Angle check, some magic stuff
        OldPos = CurrentPos;
        Gravity -= BulletGrav;
		//Gravity = Vec2f(0,0);
        const f32 angle = StartingAimPos * (FacingLeft ? 1 : 1);
        Vec2f dir = Vec2f((FacingLeft ? -1 : 1), 0.0f).RotateBy(angle);
        CurrentPos = ((dir * Speed) - (Gravity * Speed)) + CurrentPos;
        TrueVelocity = CurrentPos - OldPos;
        //End

		bool steelHit = false;
        bool endBullet = false;
        bool breakLoop = false;
        HitInfo@[] list;
        if(map.getHitInfosFromRay(OldPos, -(CurrentPos - OldPos).Angle(), (OldPos - CurrentPos).Length(), hoomanShooter, @list))
        {
            for(int a = 0; a < list.length(); a++)
            {
                breakLoop = false;
                HitInfo@ hit = list[a];
                Vec2f hitpos = hit.hitpos;
                CBlob@ blob = @hit.blob;
                if (blob !is null) // blob
                {   
                    int hash = blob.getName().getHash();
                    switch(hash)
                    {
                        case 1296319959://Stone_door
                        case 213968596://Wooden_door
                        case 916369496://Trapdoor
                        case -637068387://steelblock
                        {
                            if(blob.isCollidable())
                            {
                                CurrentPos = hitpos;
                                breakLoop = true;
                                Sound::Play(ObjectHitSound, hitpos, 1.5f);
                            }
                        }
                        break;

                        case 804095823://platform
                        {
                            if(CollidesWithPlatform(blob,TrueVelocity))
                            {
                                CurrentPos = hitpos;
                                breakLoop = true;
                                Sound::Play(ObjectHitSound, hitpos, 1.5f);
                            }
                        }
                        break;

                        default:
                        {
                            if(TargetsPierced.find(blob.getNetworkID()) <= -1){
                                //print(blob.getName() + '\n'+blob.getName().getHash()); //useful for debugging new tiles to hit
                                if((blob.hasTag("player") || blob.hasTag("flesh") || blob.hasTag("bullet_hits")) && blob.isCollidable())
                                {
									bool skip_bones = blob.hasTag("bones") && !(XORRandom(3)==0);
                                    if(blob.getTeamNum() == TeamNum
										//if commander offcier decides to kill an ally - no one shall stop them
										&& DamageType != HittersKIWI::cos_will
										//we always hit dummy
										&& !blob.hasTag("dummy")
										//only with a 33% chance we can hit a skeleton
										|| skip_bones
										//don't shoot NPCs <3
										|| blob.hasTag("migrant")){
                                        continue;
                                    }
									
                                    CurrentPos = hitpos;
									if (true){//!blob.hasTag("steel")) {
										if(!blob.hasTag("invincible") && !blob.hasTag("seated")) 
										{
											if(isServer())
											{
												CPlayer@ p = hoomanShooter.getPlayer();
												int coins = 0;
												hoomanShooter.server_Hit(blob, CurrentPos, Vec2f(0, 0)+KB.RotateByDegrees(-angle), Damage, DamageType); 
												
												if(blob.hasTag("flesh"))
												{
													coins = gunBlob.get_u16("coins_flesh");
												}
												else
												{
													coins = gunBlob.get_u16("coins_object");
												}
	
												if(p !is null)
												{
													p.server_setCoins(p.getCoins() + coins);
												}
											}
											else
											{
												Sound::Play(FleshHitSound,  CurrentPos, 1.5f); 
											}
	
										}
										if(Pierces <= 0 || blob.hasTag("non_pierceable"))breakLoop = true;
										else {
											Pierces-=1;
											TargetsPierced.push_back(blob.getNetworkID());
										}
									} else {
										//steel hit
										steelHit = true;
									}
                                }
                            }
                        }
                    }
                    if(breakLoop)//So we can break while inside the switch
                    {
                        endBullet = true;
                        break;
                    }
                }
                //else
				//TODO: make bullets ricochet from steel things
                if (blob is null || steelHit) { 
                    
                    if(Ricochet){
                        Vec2f tilepos = map.getTileWorldPosition(hit.tileOffset)+Vec2f(4,4);
						const bool flip = hitpos.x > tilepos.x;
						const f32 flip_factor = flip ? -1 : 1;
                        
                        Vec2f Direction = Vec2f(10,0);
                        Direction.RotateByDegrees(-StartingAimPos);
                        Vec2f FaceVector = Vec2f(1,0);
                        FaceVector.RotateByDegrees(Maths::Floor(((hitpos-tilepos).getAngleDegrees()+45.0f)/90.0f)*90);
                        FaceVector.Normalize();
                        print("FaceVector"+FaceVector);
						if (!steelHit)
							Sound::Play("dirt_ricochet_" + XORRandom(4), hitpos, 0.91 + XORRandom(5)*0.1, 1.0f);
                        
                        f32 dotProduct = (2*(Direction.x * FaceVector.x + Direction.y * FaceVector.y));
                        Vec2f RicochetV = ((FaceVector*dotProduct)-Direction);
                        StartingAimPos = RicochetV.getAngle();
                        
                        CurrentPos = OldPos;
                        Ricochet = false;
                    } else {
                        CurrentPos = hitpos;
                        endBullet = true;
                        ParticleBullet(CurrentPos, TrueVelocity);
                    }
                    
                    if(!isServer()){
                        Sound::Play(ObjectHitSound, hitpos, 1.5f);
                    }
                }
            }
        }

        if(endBullet == true)
        {
            TimeLeft = 1;
        }
       
        //End
		
		return false;
    }

    void onRender()//every bullet gets forced to join the queue in onRenders, so we use this to calc to position
    {   
        //Are we on the screen?
        const Vec2f xLast = PDriver.getScreenPosFromWorldPos(LastPos);
        const Vec2f xNew  = PDriver.getScreenPosFromWorldPos(CurrentPos);
        if(!(xNew.x > 0 && xNew.x < ScreenX))//Is our main position still on screen?
        {//No, so lets left if we just 'left'
            if(!(xLast.x > 0 && xLast.x < ScreenX))//Was our last position on screen?
            {//No
                if(Fade !is null)Fade.Front = CurrentPos;
                return;
            }
        }

        //Lerp
        const float blend = 1 - Maths::Pow(0.5f, getRenderApproximateCorrectionFactor());//EEEE
        const f32 x = lerp(LastPos.x, CurrentPos.x, blend);//Thanks to goldenGuy for finding this and telling me
        const f32 y = lerp(LastPos.y, CurrentPos.y, blend);
        Vec2f newPos = Vec2f(x,y);
        
        LastPos.x = x;
        LastPos.y = y;
        //End

		f32 angle = Vec2f(CurrentPos.x-newPos.x, CurrentPos.y-newPos.y).getAngleDegrees();//Sets the angle
		
        Vec2f TopLeft  = Vec2f(newPos.x - SpriteSize.x, newPos.y + SpriteSize.y);//New positions
        Vec2f TopRight = Vec2f(newPos.x - SpriteSize.x, newPos.y - SpriteSize.y);
        Vec2f BotLeft  = Vec2f(newPos.x + SpriteSize.x, newPos.y + SpriteSize.y);
        Vec2f BotRight = Vec2f(newPos.x + SpriteSize.x, newPos.y - SpriteSize.y);

        angle = -((angle % 360) + 90);
		
		if(Fade !is null)Fade.Front = newPos;
        
        if(Texture.empty()) return; //No point in trying to render if we have no texture.

        BotLeft.RotateBy( angle,newPos);
        BotRight.RotateBy(angle,newPos);
        TopLeft.RotateBy( angle,newPos);
        TopRight.RotateBy(angle,newPos);   

        Vertex[]@ bullet_vertex;
        if(getRules().get(Texture, @bullet_vertex)){
			bullet_vertex.push_back(Vertex(TopLeft.x,  TopLeft.y,  0, 0, 0, trueWhite)); // top left
			bullet_vertex.push_back(Vertex(TopRight.x, TopRight.y, 0, 1, 0, trueWhite)); // top right
			bullet_vertex.push_back(Vertex(BotRight.x, BotRight.y, 0, 1, 1, trueWhite)); // bot right
			bullet_vertex.push_back(Vertex(BotLeft.x,  BotLeft.y,  0, 0, 1, trueWhite)); // bot left
		}
    }

    
}


class BulletHolder
{
    BulletObj[] bullets;
    BulletFade@[] fade;
    PrettyParticle@[] PParticles;
	BulletHolder(){}

    void FakeOnTick(CRules@ this)
    {
        CMap@ map = getMap();
        for(int a = 0; a < bullets.length(); a++)
        {
            BulletObj@ bullet = bullets[a];
            if(bullet.onFakeTick(map))
            {
                if(bullets[a].Fade !is null)bullets[a].Fade.Front = bullets[a].CurrentPos;
				bullets.removeAt(a);
            }
        }
        //print(bullets.length() + '');
         
        for(int a = 0; a < PParticles.length(); a++)
        {
            if(PParticles[a].ttl == 0)
            {
                PParticles.removeAt(a);
                continue;
            }
            PParticles[a].FakeTick();
        }
		
		for(int a = 0; a < fade.length(); a++)
        {
            if(fade[a].TimeLeft <= 0){
				fade.removeAt(a);
			}
        }
    }

    void addFade(BulletFade@ fadeToAdd)
    {   
        fade.push_back(fadeToAdd);
    }

    void addNewParticle(CParticle@ p,const u8 type)
    {
        PParticles.push_back(PrettyParticle(p,type));
    }
    
    void FillVertexBook()
    {
        for (int a = 0; a < bullets.length(); a++)
		{
			bullets[a].onRender();
		}
		for (int a = 0; a < fade.length(); a++)
		{
			fade[a].onRender();
		}
    }

    void AddNewObj(BulletObj@ this)
    {
        CMap@ map = getMap();
        this.onFakeTick(map);
        bullets.push_back(this);
    }
    
	void Clean()
	{
		bullets.clear();
	}

    int ArrayCount()
	{
		return bullets.length();
	}
}


const float lerp(float v0, float v1, float t)
{
	//return (1 - t) * v0 + t * v1; //Golden guys version of lerp
    return v0 + t * (v1 - v0); //vams version
}


const bool CollidesWithPlatform(CBlob@ blob, const Vec2f velocity)//Stolen from rock.as
{
	const f32 platform_angle = blob.getAngleDegrees();	
	Vec2f direction = Vec2f(0.0f, -1.0f);
	direction.RotateBy(platform_angle);
	const float velocity_angle = direction.AngleWith(velocity);

	return !(velocity_angle > -90.0f && velocity_angle < 90.0f);
}

