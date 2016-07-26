// Rixuel Rifle by Rixuel (obviously lol). Weapon for Monster Hunt.

class RixuelRifle extends TournamentWeapon;

#exec TEXTURE IMPORT NAME=rixuel_ASMD_t FILE=MODELS\rixuel_ASMD_t.pcx GROUP="Skins" LODSET=2
#exec TEXTURE IMPORT NAME=rixuel_ASMD_t1 FILE=MODELS\rixuel_ASMD_t1.pcx GROUP="Skins" LODSET=2
#exec TEXTURE IMPORT NAME=rixuel_ASMD_t2 FILE=MODELS\rixuel_ASMD_t2.pcx GROUP="Skins" LODSET=2
#exec TEXTURE IMPORT NAME=rixuel_ASMD_t3 FILE=MODELS\rixuel_ASMD_t3.pcx GROUP="Skins" LODSET=2
#exec TEXTURE IMPORT NAME=rixuel_ASMD_t4 FILE=MODELS\rixuel_ASMD_t4.pcx GROUP="Skins" LODSET=2

var() int HitDamage;
var() float ShotAcc;
var(Display) texture MultiSkinsFirstPerson[8];

function Fire( float value )
{	
	if( AmmoType.UseAmmo(0) )
	{
		TraceFire(ShotAcc);
		GotoState('NormalFire');
		bPointing = True;
		bCanClientFire = true;
		ClientFire(Value);
		
		Pawn(Owner).PlayRecoil(FiringSpeed);
	}
}

function AltFire( float value )
{
	if( AmmoType.UseAmmo(0) )
	{
		ProjectileFire(Class'UnrealShare.DAmmo6', AltProjectileSpeed, False);
		ProjectileFire(Class'UnrealShare.DAmmo7', AltProjectileSpeed, False);
		ProjectileFire(Class'UnrealShare.DAmmo8', AltProjectileSpeed, True);

		GotoState('AltFiring');
		bPointing = True;
		bCanClientFire = true;
		ClientAltFire(Value);
		
		Pawn(Owner).PlayRecoil(FiringSpeed);
	}
}

simulated function PlayFiring()
{
	PlayOwnedSound(FireSound, SLOT_None, Pawn(Owner).SoundDampening*1.0);
	LoopAnim('Fire1', 1.8 + 1.8 * FireAdjust,0.05); // Firing speed
}

simulated function PlayAltFiring()
{
	PlayOwnedSound(AltFireSound, SLOT_None,Pawn(Owner).SoundDampening*1.0);
	LoopAnim('Fire1',2.5 + 2.5* FireAdjust,0.05); // AltFiring speed
}

function ProcessTraceHit(Actor Other, Vector HitLocation, Vector HitNormal, Vector X, Vector Y, Vector Z)
{
	local int i;
	local PlayerPawn PlayerOwner;
	
	if (Other==None)
	{
		HitNormal = -X;
		HitLocation = Owner.Location + X*10000.0;
	}	
	
	PlayerOwner = PlayerPawn(Owner);
	
	if ( PlayerOwner != None )
		PlayerOwner.ClientInstantFlash( -0.4, vect(450, 190, 650));
		
	SpawnEffect(HitLocation, Owner.Location + CalcDrawOffset() + (FireOffset.X + 20) * X + FireOffset.Y * Y + FireOffset.Z * Z);	
	
	// NOTE: Do not combine ShockProj and TazerProj
	// Because of "accessed none".
	if ( (ShockProj(Other)!=None) )
	{
		AmmoType.UseAmmo(0);
		ShockProj(Other).SuperExplosion();
		spawn(class'ShockWave',,,HitLocation+ HitNormal*16);
	}
	else if ( (TazerProj(Other)!=None) )
	{
		AmmoType.UseAmmo(0);
		TazerProj(Other).SuperExplosion();
		spawn(class'ShockWave',,,HitLocation+ HitNormal*16);	
	}
	else
	{
		Spawn(class'UT_RingExplosion5',,, HitLocation+HitNormal*8, rotator(HitNormal));
	}
	
	if ( (Other != self) && (Other != Owner) && (Other != None) )
	{		
		if ( Other.bIsPawn && (HitLocation.Z - Other.Location.Z > 0.62 * Other.CollisionHeight)
		&& (instigator.IsA('PlayerPawn') || (instigator.IsA('Bot') && !Bot(Instigator).bNovice)) )
		{
			Other.TakeDamage(hitdamage*3, Pawn(Owner), HitLocation, 65000 * X, 'decapitated');
			spawn(class'UT_Superring2',,,HitLocation+HitNormal*8, rotator(HitNormal));
		}
		else
		{
			Other.TakeDamage(hitdamage*1.3, Pawn(Owner), HitLocation, 60000.0*X, MyDamageType);
		}
		
		if ( !Other.bIsPawn && !Other.IsA('Carcass') )
		{
			spawn(class'UT_SpriteSmokePuff',,,HitLocation+HitNormal*9);
		}
	}
}

// ====================================

function SpawnEffect(vector HitLocation, vector SmokeLocation)
{
	local RixuelShockBeam Smoke,shock;
	local Vector DVector;
	local int NumPoints;
	local rotator SmokeRotation;

	DVector = HitLocation - SmokeLocation;
	NumPoints = VSize(DVector)/ 170; //135.0;
	if ( NumPoints < 1 )
		return;
	SmokeRotation = rotator(DVector);
	SmokeRotation.roll = Rand(65535);
	
	Smoke = Spawn(class'RixuelShockBeam',,,SmokeLocation,SmokeRotation);
	Smoke.MoveAmount = DVector/NumPoints;
	Smoke.NumPuffs = NumPoints - 1;	
}


simulated function PlayIdleAnim()
{
	if ( Mesh != PickupViewMesh )
		LoopAnim('Still',0.04,0.3);
}


// Pickup Look

state Pickup
{
   simulated function BeginState()
   {
	  Super.BeginState();
	  SetPickupSkins();
   }
}

simulated function SetOwnerDisplay()
{
   Super.SetOwnerDisplay();
   SetPickupSkins();
}

simulated function setHand(float Hand)
{
   Super.SetHand(Hand);
   SetPickupSkins();
}

simulated function BecomeItem()
{
   Super.BecomeItem();
   SetPickupSkins();
}

simulated function BecomePickup()
{
   Super.BecomePickup();
   SetPickupSkins();
}

simulated function RenderOverlays( canvas Canvas )
{
   if (PlayerPawn(Owner) != None && PlayerPawn(Owner).ViewTarget == None && !PlayerPawn(Owner).bBehindView)
	  SetFirstPersonViewSkins();
   Super.RenderOverlays(Canvas);
   SetPickupSkins();
}

simulated function SetPickupSkins()
{
local byte i;

   for (i = 0; i < ArrayCount(MultiSkins); i++)
	  MultiSkins[i] = default.MultiSkins[i];
}

simulated function SetFirstPersonViewSkins()
{
local byte i;

   if (Owner == None)
	  SetPickupSkins();
   for (i = 0; i < ArrayCount(MultiSkins); i++)
	  MultiSkins[i] = MultiSkinsFirstPerson[i];
}


defaultproperties
{	
	hitdamage=100
	WeaponDescription="Classification: Rixuel's enchanted Shock Rifle."
	InstFlash=-0.400000
	InstFog=(Z=800.000000)
	AmmoName=Class'Botpack.ShockCore'
	PickupAmmoCount=20
	bInstantHit=True
	bAltWarnTarget=True
	bSplashDamage=True
	FiringSpeed=1.000000
	FireOffset=(X=10.000000,Y=-5.000000,Z=-8.000000)
	AltProjectileClass=Class'Botpack.ShockProj'
	MyDamageType=shot
	AIRating=0.630000
	AltRefireRate=0.700000
	FireSound=Sound'UnrealShare.flak.Click'
	AltFireSound=Sound'UnrealShare.ASMD.Vapour'
	SelectSound=Sound'UnrealShare.ASMD.TazerSelect'
	DeathMessage="%k inflicted mortal damage upon %o with the %w."
	NameColor=(R=128,G=0)
	AutoSwitchPriority=5
	InventoryGroup=4
	PickupMessage="You got Rixuel Rifle!"
	ItemName="Rixuel Rifle"
	PlayerViewOffset=(X=4.400000,Y=-1.700000,Z=-1.600000)
	PlayerViewMesh=LodMesh'Botpack.ASMD2M'
	PlayerViewScale=2.000000
	BobDamping=0.975000
	PickupViewMesh=LodMesh'Botpack.ASMD2pick'
	ThirdPersonMesh=LodMesh'Botpack.ASMD2hand'
	StatusIcon=Texture'Botpack.Icons.UseASMD'
	PickupSound=Sound'UnrealShare.Pickups.WeaponPickup'
	Icon=Texture'Botpack.Icons.UseASMD'
	Mesh=LodMesh'Botpack.ASMD2pick'
	bNoSmooth=False
	CollisionRadius=34.000000
	CollisionHeight=8.000000
	Mass=50.000000
	
	ShotAcc=0.00000
	MultiSkins(1)=Texture'RixuelRifle.Skins.rixuel_ASMD_t'
	MultiSkinsFirstPerson(0)=Texture'RixuelRifle.Skins.rixuel_ASMD_t1'
	MultiSkinsFirstPerson(1)=Texture'RixuelRifle.Skins.rixuel_ASMD_t2'
	MultiSkinsFirstPerson(2)=Texture'RixuelRifle.Skins.rixuel_ASMD_t3'
	MultiSkinsFirstPerson(3)=Texture'RixuelRifle.Skins.rixuel_ASMD_t4'
}
