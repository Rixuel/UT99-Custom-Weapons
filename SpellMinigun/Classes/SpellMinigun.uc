// SpellMinigun By LordRixuel. Weapon for Monster Hunt.

class SpellMinigun extends TournamentWeapon;

#exec TEXTURE IMPORT NAME=SpellMini_t FILE=MODELS\SpellMini_t.PCX GROUP="Skins" LODSET=2
#exec TEXTURE IMPORT NAME=SpellMini_t1 FILE=MODELS\SpellMini_t1.PCX GROUP="Skins" LODSET=2
#exec TEXTURE IMPORT NAME=SpellMini_t2 FILE=MODELS\SpellMini_t2.PCX GROUP="Skins" LODSET=2
#exec TEXTURE IMPORT NAME=SpellMini_t3 FILE=MODELS\SpellMini_t3.PCX GROUP="Skins" LODSET=2
#exec TEXTURE IMPORT NAME=SpellMini_t4 FILE=MODELS\SpellMini_t4.PCX GROUP="Skins" LODSET=2

var float ShotAccuracy, LastShellSpawn;
var int Count;
var bool bOutOfAmmo, bFiredShot;
var() texture MuzzleFlashVariations[10];
var(Display) texture MultiSkinsFirstPerson[8];

var int choiceSM;

// set which hand is holding weapon
function setHand(float Hand)
{
	if ( Hand == 2 )
	{
		FireOffset.Y = 0;
		bHideWeapon = true;
		return;
	}
	else
		bHideWeapon = false;
	PlayerViewOffset = Default.PlayerViewOffset * 100;
	FireOffset.Y = Hand * Default.FireOffset.Y;
	PlayerViewOffset.Y *= Hand;
	if ( Hand == 1 )
		Mesh = mesh(DynamicLoadObject("Botpack.Minigun2L", class'Mesh'));
	else
	{
		Mesh = mesh'Minigun2m';
		if ( Hand == 0 )
		{
			PlayerViewOffset.X = Default.PlayerViewOffset.X * 95;
			PlayerViewOffset.Z = Default.PlayerViewOffset.Z * 105;
		}
	}
	
	Super.SetHand(Hand);
	SetPickupSkins();
}
simulated event RenderTexture(ScriptedTexture Tex)
{
	local Color C;
	local string Temp;
	
	Temp = String(AmmoType.AmmoAmount);

	while(Len(Temp) < 3) Temp = "0"$Temp;

	C.R = 255;
	C.G = 0;
	C.B = 0;

	Tex.DrawColoredText( 2, 10, Temp, Font'LEDFont2', C );	
}
function float RateSelf( out int bUseAltMode )
{
	local float dist;

	if ( AmmoType.AmmoAmount <=0 )
		return -2;

	if ( Pawn(Owner).Enemy == None )
	{
		bUseAltMode = 0;
		return AIRating;
	}

	dist = VSize(Pawn(Owner).Enemy.Location - Owner.Location); 
	bUseAltMode = 1;
	if ( dist > 1200 )
	{
		if ( dist > 1700 )
			bUseAltMode = 0;
		return (AIRating * FMin(Pawn(Owner).DamageScaling, 1.5) + FMin(0.0001 * dist, 0.3)); 
	}
	AIRating *= FMin(Pawn(Owner).DamageScaling, 1.5);
	return AIRating;
}

function TraceFire( float Accuracy )
{
	local vector HitLocation, HitNormal, StartTrace, EndTrace, X,Y,Z, AimDir;
	local actor Other;

	Owner.MakeNoise(Pawn(Owner).SoundDampening);
	GetAxes(Pawn(owner).ViewRotation,X,Y,Z);
	StartTrace = Owner.Location + CalcDrawOffset() + FireOffset.Y * Y + FireOffset.Z * Z; 
	AdjustedAim = pawn(owner).AdjustAim(1000000, StartTrace, 2.75*AimError, False, False);	
	EndTrace = StartTrace + Accuracy * (FRand() - 0.5 )* Y * 1000
		+ Accuracy * (FRand() - 0.5 ) * Z * 1000;
	AimDir = vector(AdjustedAim);
	EndTrace += (10000 * AimDir); 
	Other = Pawn(Owner).TraceShot(HitLocation,HitNormal,EndTrace,StartTrace);

	Count++;
	if ( Count == 4 )
	{
		Count = 0;
		if ( VSize(HitLocation - StartTrace) > 250 )
			Spawn(class'RingExplosion4',,, StartTrace + 96 * AimDir,rotator(EndTrace - StartTrace));
			//Spawn(class'RingExplosion4');
	}
	ProcessTraceHit(Other, HitLocation, HitNormal, vector(AdjustedAim),Y,Z);
}


simulated function PlayFiring()
{	
	if ( PlayerPawn(Owner) != None )
		PlayerPawn(Owner).ShakeView(ShakeTime, ShakeMag, ShakeVert);
		
	PlayAnim('Shoot1', 1.2 + 0.3 * FireAdjust, 0.05);
	AmbientGlow = 250;
	AmbientSound = FireSound;
	bSteadyFlash3rd = true;
}

function Fire( float Value )
{
	Enable('Tick');
	if ( AmmoType == None )
	{
		// ammocheck
		GiveAmmo(Pawn(Owner));
	}
	if ( AmmoType.UseAmmo(0) )
	{
		SoundVolume = 255*Pawn(Owner).SoundDampening;
		Pawn(Owner).PlayRecoil(FiringSpeed);
		bCanClientFire = true;
		bPointing=True;
		ShotAccuracy = 0.0;
		ClientFire(value);
		GotoState('NormalFire');
	}
	else GoToState('Idle');
}


function ProcessTraceHit(Actor Other, Vector HitLocation, Vector HitNormal, Vector X, Vector Y, Vector Z)
{		
	local UT_Shellcase s;
	
	local vector StartTrace, EndTrace, AimDir;
	
	if (choiceSM==0)
	{
		// Normal Bullet
		
		Owner.MakeNoise(Pawn(Owner).SoundDampening);
		GetAxes(Pawn(owner).ViewRotation,X,Y,Z);
		StartTrace = Owner.Location + CalcDrawOffset() + FireOffset.Y * Y + FireOffset.Z * Z; 
		AdjustedAim = pawn(owner).AdjustAim(1000000, StartTrace, 2.75*AimError, False, False);	
		EndTrace = StartTrace + 0 * (FRand() - 0.5 )* Y * 1000 + 0 * (FRand() - 0.5 ) * Z * 1000;
		AimDir = vector(AdjustedAim);
		EndTrace += (10000 * AimDir); 
		Other = Pawn(Owner).TraceShot(HitLocation,HitNormal,EndTrace,StartTrace);
		
		s = Spawn(class'UT_ShellCase',, '', Owner.Location + CalcDrawOffset() + 30 * X + (2.8 * FireOffset.Y+5.0) * Y - Z * 1);
		Spawn(class'MTracer',,, StartTrace + 96 * AimDir,rotator(EndTrace - StartTrace));

		if ( s != None )
		{
			s.DrawScale = 2.0;
			s.Eject(((FRand()*0.3+0.4)*X + (FRand()*0.2+0.2)*Y + (FRand()*0.3+1.0) * Z)*160);
		}
		
		if (Other == Level)
		{
			Spawn(class'UT_HeavyWallHitEffect',,, HitLocation+HitNormal, Rotator(HitNormal));
		}
		else if ( (Other != self) && (Other != Owner) && (Other != None) )
		{
			if ( Other.bIsPawn )
			{
				Other.PlaySound(Sound 'ChunkHit',, 4.0,,100);
			}
			if ( Other.bIsPawn && (HitLocation.Z - Other.Location.Z > 0.62 * Other.CollisionHeight)
			&& (instigator.IsA('PlayerPawn') || (instigator.IsA('Bot') && !Bot(Instigator).bNovice)) )
			{
				Other.TakeDamage(100, Pawn(Owner), HitLocation, 35000 * X, 'decapitated');
			}
			else
			{
				Other.TakeDamage(45, Pawn(Owner), HitLocation, 30000.0*X, MyDamageType);
			}
			if ( !Other.bIsPawn && !Other.IsA('Carcass') )
			{
				spawn(class'UT_HeavyWallHitEffect',,,HitLocation+HitNormal*9);
			}
		}
		
	}
	else if (choiceSM==1)
	{
		ProjectileFire(Class'UnrealShare.StingerProjectile', 1, False);
		ProjectileFire(Class'UnrealShare.DispersionAmmo', 1, False);
		ProjectileFire(Class'UnrealShare.DAmmo5', 1, False);
	}
	else if (choiceSM==2)
	{
		ProjectileFire(Class'Botpack.ShockProj', 1, False);
	}
	else if (choiceSM==3)
	{
		ProjectileFire(Class'UnrealI.RazorBlade', 1, False);
		ProjectileFire(Class'Botpack.Razor2', 1, False);
	}
	else if (choiceSM==4)
	{
		ProjectileFire(Class'Botpack.UTFlakShell', 1, False);
		ProjectileFire(Class'Botpack.UT_Grenade', 1, False);
	}
	else if (choiceSM==5)
	{
		ProjectileFire(Class'Botpack.RocketMk2S2', 1, False);
		ProjectileFire(Class'Botpack.PlasmaSphere2', 1, False);
	}
	else if (choiceSM==6)
	{
		AmmoType.UseAmmo(-2);
		Spawn(class'UTTeleEffect2');
	}

}


function AltFire( float Value )
{
	local PlayerPawn pn;
	
	Enable('Tick');
	if ( AmmoType == None )
	{
		// ammocheck
		GiveAmmo(Pawn(Owner));
	}
	
	if ( AmmoType.UseAmmo(0) )
	{
		bPointing=True;
		bCanClientFire = True;
		ShotAccuracy = 0.0;
		Pawn(Owner).PlayRecoil(FiringSpeed);
		//SoundVolume = 255*Pawn(Owner).SoundDampening;		
		ClientAltFire(value);	
		GoToState('AltFiring2');
	}
	else GoToState('Idle');
	
	if (choiceSM==0)
	{
		choiceSM=1;
		PlayerPawn(Owner).ClientMessage("Spell Minigun MODE - Blaster"); // Say next weapon
	}
	else if (choiceSM==1)
	{
		choiceSM=2;
		PlayerPawn(Owner).ClientMessage("Spell Minigun MODE - Shock Ball"); // Say next weapon
	}
	else if (choiceSM==2)
	{
		choiceSM=3;
		PlayerPawn(Owner).ClientMessage("Spell Minigun MODE - Double Razor"); // Say next weapon
	}
	else if (choiceSM==3)
	{
		choiceSM=4;
		PlayerPawn(Owner).ClientMessage("Spell Minigun MODE - Dropper"); // Say next weapon
	}
	else if (choiceSM==4)
	{
		choiceSM=5;
		PlayerPawn(Owner).ClientMessage("Spell Minigun MODE - Plasma Rocket"); // Say next weapon
	}
	else if (choiceSM==5)
	{
		choiceSM=6;
		PlayerPawn(Owner).ClientMessage("Spell Minigun MODE - RECHARGE bullets"); // Say next weapon
	}
	else if (choiceSM==6)
	{
		choiceSM=0;
		PlayerPawn(Owner).ClientMessage("Spell Minigun MODE - Normal"); // Say next weapon
	}
	else
	{
		choiceSM=0;
	}
	
	
}

simulated function PlayAltFiring()
{
	/*if ( PlayerPawn(Owner) != None )
		PlayerPawn(Owner).ShakeView(ShakeTime, ShakeMag, ShakeVert);
	PlayAnim('Shoot1',1 + 0.3 * FireAdjust, 0.05);
	AmbientGlow = 250;
	AmbientSound = FireSound;
	bSteadyFlash3rd = true;*/

}

simulated function PlayUnwind()
{
	if ( Owner != None )
	{
		PlayOwnedSound(Misc1Sound, SLOT_Misc, 3.0*Pawn(Owner).SoundDampening);  //Finish firing, power down		
		PlayAnim('UnWind',15.0, 0.0);
	}
	
}


state FinishFire
{
	function Fire(float F) {}
	function AltFire(float F) {}

	function ForceFire()
	{
		bForceFire = true;
	}

	function ForceAltFire()
	{
		bForceAltFire = true;
	}

	function BeginState()
	{
		PlayUnwind();
	}

Begin:
	FinishAnim();
	Finish();
}
state NormalFire
{
	function Tick( float DeltaTime )
	{
		if (Owner==None) 
			AmbientSound = None;
	}

	function AnimEnd()
	{
		if (Pawn(Owner).Weapon != self) GotoState('');
		else if (Pawn(Owner).bFire!=0 && AmmoType.AmmoAmount>0)
			Global.Fire(0);
		else if ( Pawn(Owner).bAltFire!=0 && AmmoType.AmmoAmount>0)
			Global.AltFire(0);
		else 
			GotoState('FinishFire');
	}

	function BeginState()
	{
		AmbientGlow = 250;
		AmbientSound = FireSound;
		bSteadyFlash3rd = true;
		Super.BeginState();
	}	

	function EndState()
	{
		bSteadyFlash3rd = false;
		AmbientGlow = 0;
		LightType = LT_None;
		AmbientSound = None;
		Super.EndState();
	}

Begin:
	Sleep(0.13);
	GenerateBullet();
	Goto('Begin');
}



state AltFiring2
{
	function EndState()
	{
		bSteadyFlash3rd = false;
		AmbientGlow = 0;
		LightType = LT_None;
		AmbientSound = None;
		Super.EndState();
	}


Begin:
	Sleep(0.13);
	GenerateNoBullet();
	Goto('Begin');
}
function GenerateNoBullet()
{
    LightType = LT_Steady;
	bFiredShot = true;
	if ( PlayerPawn(Owner) != None )
		PlayerPawn(Owner).ClientInstantFlash( -0.2, vect(325, 225, 95));
	if ( AmmoType.UseAmmo(0) ) 
		GotoState('FinishFire');//TraceFire(ShotAccuracy);
	else
		GotoState('FinishFire');
}
function GenerateBullet()
{
    LightType = LT_Steady;
	bFiredShot = true;
	if ( PlayerPawn(Owner) != None )
		PlayerPawn(Owner).ClientInstantFlash( -0.2, vect(325, 225, 95));
	if ( AmmoType.UseAmmo(1) ) 
		TraceFire(ShotAccuracy);
	else
		GotoState('FinishFire');
}





// ====================================

simulated event RenderOverlays( canvas Canvas )
{
	local UT_Shellcase s;
	local vector X,Y,Z;
	local float dir;

	if ( bSteadyFlash3rd )
	{
		bMuzzleFlash = 1;
		bSetFlashTime = false;
		if ( !Level.bDropDetail )
			MFTexture = MuzzleFlashVariations[Rand(10)];
		else
			MFTexture = MuzzleFlashVariations[Rand(5)];
	}
	else
		bMuzzleFlash = 0;
	FlashY = Default.FlashY * (1.08 - 0.16 * FRand());
	if ( !Owner.IsA('PlayerPawn') || (PlayerPawn(Owner).Handedness == 0) )
		FlashO = Default.FlashO * (4 + 0.15 * FRand());
	else		
		FlashO = Default.FlashO * (1 + 0.15 * FRand());
	Texture'MiniAmmoled'.NotifyActor = Self;
	Super.RenderOverlays(Canvas);
	Texture'MiniAmmoled'.NotifyActor = None;

	if ( bSteadyFlash3rd && Level.bHighDetailMode && (Level.TimeSeconds - LastShellSpawn > 0.125)
		&& (Level.Pauser=="") )
	{
		LastShellSpawn = Level.TimeSeconds;
		GetAxes(Pawn(Owner).ViewRotation,X,Y,Z);

		if ( PlayerViewOffset.Y >= 0 )
			dir = 1;
		else 
			dir = -1;
		if ( Level.bHighDetailMode )
		{
			s = Spawn(class'MiniShellCase',Owner, '', Owner.Location + CalcDrawOffset() + 30 * X + (0.4 * PlayerViewOffset.Y+5.0) * Y - Z * 5);
			if ( s != None ) 
				s.Eject(((FRand()*0.3+0.4)*X + (FRand()*0.3+0.2)*dir*Y + (FRand()*0.3+1.0) * Z)*160);              
		}
	}
	
	if (PlayerPawn(Owner) != None && PlayerPawn(Owner).ViewTarget == None && !PlayerPawn(Owner).bBehindView)
	  SetFirstPersonViewSkins();
	Super.RenderOverlays(Canvas);
	SetPickupSkins();
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
	MuzzleFlashVariations(0)=Texture'Botpack.Skins.pblst_a03'
	MuzzleFlashVariations(1)=Texture'Botpack.Skins.pblst_a04'
	MuzzleFlashVariations(2)=Texture'Botpack.Skins.pEnd_a00'
	MuzzleFlashVariations(3)=Texture'Botpack.Skins.pEnd_a01'
	MuzzleFlashVariations(4)=Texture'Botpack.Skins.pEnd_a02'
	MuzzleFlashVariations(5)=Texture'Botpack.Skins.pEnd_a03'
	MuzzleFlashVariations(6)=Texture'Botpack.Skins.phit_a00'
	MuzzleFlashVariations(7)=Texture'Botpack.Skins.phit_a01'
	MuzzleFlashVariations(8)=Texture'Botpack.Skins.phit_a02'
	MuzzleFlashVariations(9)=Texture'Botpack.Skins.phit_a03'
	

	WeaponDescription="Spell Minigun by Rixuel."
	PickupAmmoCount=50
	bInstantHit=True
	bAltInstantHit=True
	bRapidFire=True
	FireOffset=(X=8.000000,Y=-5.000000,Z=-4.000000)
	MyDamageType=shot
	shakemag=135.000000
	shakevert=8.000000
	AIRating=0.730000
	RefireRate=0.990000
	AltRefireRate=0.990000

	FireSound=Sound'UnrealShare.General.Exple03'
	AltFireSound=Sound'UnrealShare.General.Exple03'
	SelectSound=Sound'UnrealI.Minigun.MiniSelect'
	Misc1Sound=Sound'Botpack.minigun2.M2WindDown'

	bDrawMuzzleFlash=True

	MFTexture=Texture'Botpack.Skins.Muz9'
	AutoSwitchPriority=7
	InventoryGroup=7
	PickupMessage="You got the Spell Minigun."
	ItemName="Spell Minigun"
	PlayerViewOffset=(X=2.100000,Y=-0.350000,Z=-1.700000)
	PlayerViewMesh=LodMesh'Botpack.Minigun2m'

	BobDamping=0.975000

	PickupViewMesh=LodMesh'Botpack.MinigunPick'
	ThirdPersonMesh=LodMesh'Botpack.MiniHand'
	StatusIcon=Texture'Botpack.Icons.UseMini'

	bMuzzleFlashParticles=True
	MuzzleFlashStyle=STY_Translucent
	MuzzleFlashMesh=LodMesh'Botpack.MuzzFlash3'
	MuzzleFlashScale=0.250000
	MuzzleFlashTexture=Texture'Botpack.Skins.MuzzyPulse'
	PickupSound=Sound'UnrealShare.Pickups.WeaponPickup'
	Icon=Texture'Botpack.Icons.UseMini'
	Mesh=LodMesh'Botpack.MinigunPick'
	bNoSmooth=False
	SoundRadius=96
	SoundVolume=255
	CollisionRadius=34.000000
	CollisionHeight=8.000000
	LightEffect=LE_NonIncidence
	LightBrightness=255
	LightHue=110
	LightSaturation=32
	LightRadius=6

	AmmoName=Class'Botpack.Miniammo'

	DeathMessage="%k's %w turned %o into a leaky piece of meat."
	NameColor=(B=0)

	MuzzleScale=2.000000
	FlashY=0.180000
	FlashO=0.022000
	FlashC=0.006000
	FlashLength=0.200000
	FlashS=128
	
	
	MultiSkins(1)=Texture'SpellMinigun.Skins.SpellMini_t'
	MultiSkinsFirstPerson(0)=Texture'SpellMinigun.Skins.SpellMini_t1'
	MultiSkinsFirstPerson(1)=Texture'SpellMinigun.Skins.SpellMini_t2'
	MultiSkinsFirstPerson(2)=Texture'SpellMinigun.Skins.SpellMini_t3'
	MultiSkinsFirstPerson(3)=Texture'SpellMinigun.Skins.SpellMini_t4'
}