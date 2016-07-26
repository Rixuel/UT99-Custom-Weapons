// MagicSniper By LordRixuel. Weapon for Monster Hunt.

class MagicSniper extends TournamentWeapon;

#exec TEXTURE IMPORT NAME=magiccrosshair FILE="..\MagicSniper\magiccrosshair.pcx" FLAGS=2 MIPS=ON

#exec TEXTURE IMPORT NAME=MagicRifle2 FILE=MODELS\MagicRifle2.pcx GROUP=Skins LODSET=2

#exec TEXTURE IMPORT NAME=MagicRifle2a FILE=MODELS\MagicRifle2a.pcx GROUP=Skins LODSET=2
#exec TEXTURE IMPORT NAME=MagicRifle2b FILE=MODELS\MagicRifle2b.pcx GROUP=Skins LODSET=2
#exec TEXTURE IMPORT NAME=MagicRifle2c FILE=MODELS\MagicRifle2c.pcx GROUP=Skins LODSET=2
#exec TEXTURE IMPORT NAME=MagicRifle2d FILE=MODELS\MagicRifle2d.pcx GROUP=Skins LODSET=2

var int NumFire;
var name FireAnims[5];
var vector OwnerLocation;
var float StillTime, StillStart;
var(Display) texture MultiSkinsFirstPerson[8];


simulated function PostRender( canvas Canvas )
{
	local PlayerPawn P;
	local float Scale;
	//Super.PostRender(Canvas); Disable default Crosshair
	P = PlayerPawn(Owner);
	
	if ( (P != None) && (P.DesiredFOV != P.DefaultFOV) )
	{
		bOwnsCrossHair = true;
		
		// Crosshair size.
		Scale = Canvas.ClipX/832; //832, 1248;
		
		// Position of Zoom Crosshair on screen.
		Canvas.SetPos(0.5 * Canvas.ClipX - 128 * Scale, 0.5 * Canvas.ClipY - 128 * Scale);
		
		if ( Level.bHighDetailMode )
		{
			Canvas.Style = ERenderStyle.STY_Translucent;
			//Canvas.Style = ERenderStyle.STY_Modulated;
		}
		else
		{
			Canvas.Style = ERenderStyle.STY_Translucent;
			//Canvas.Style = ERenderStyle.STY_Normal;
		}
		
		Canvas.DrawIcon(Texture'magiccrosshair', Scale);
		Canvas.SetPos(0.5 * Canvas.ClipX - 10 * Scale, 0.5 * Canvas.ClipY + 116 * Scale);
		
		Canvas.DrawColor.R = 50;
		Canvas.DrawColor.G = 100;
		Canvas.DrawColor.B = 255;
		Scale = P.DefaultFOV/P.DesiredFOV;
		Canvas.DrawText("X"$int(Scale)$"."$int(10 * Scale - 10 * int(Scale)));

	}
	else
		bOwnsCrossHair = false;
}
function float RateSelf( out int bUseAltMode )
{
	local float dist;

	if ( AmmoType.AmmoAmount <=0 )
		return -2;

	bUseAltMode = 0;
	if ( (Bot(Owner) != None) && Bot(Owner).bSniping )
		return AIRating + 1.15;
	if (  Pawn(Owner).Enemy != None )
	{
		dist = VSize(Pawn(Owner).Enemy.Location - Owner.Location);
		if ( dist > 1200 )
		{
			if ( dist > 2000 )
				return (AIRating + 0.75);
			return (AIRating + FMin(0.0001 * dist, 0.45)); 
		}
	}
	return AIRating;
}

// set which hand is holding weapon
function setHand(float Hand)
{
	Super.SetHand(Hand);
	if ( Hand == 1 )
		Mesh = mesh(DynamicLoadObject("Botpack.Rifle2mL", class'Mesh'));
	else
		Mesh = mesh'Rifle2m';
	
	Super.SetHand(Hand);
	SetPickupSkins();
}

simulated function PlayFiring()
{
	local int r;
	
	PlayOwnedSound(FireSound, SLOT_None, Pawn(Owner).SoundDampening*0.0);
	PlayAnim(FireAnims[Rand(5)], 1.0 + 1.0 * FireAdjust, 0.05);

	
	if ( (PlayerPawn(Owner) != None) && (PlayerPawn(Owner).DesiredFOV == PlayerPawn(Owner).DefaultFOV) )
		bMuzzleFlash++;
}


simulated function bool ClientAltFire( float Value )
{
	GotoState('Zooming');
	return true;
}

function AltFire( float Value )
{
	ClientAltFire(Value);
}

function TraceFire( float Accuracy )
{
	local vector HitLocation, HitNormal, StartTrace, EndTrace, X,Y,Z;
	local actor Other;
	local Pawn PawnOwner;
	local int i;
	
	PawnOwner = Pawn(Owner);
	Owner.MakeNoise(PawnOwner.SoundDampening);
	GetAxes(PawnOwner.ViewRotation,X,Y,Z);
	StartTrace = Owner.Location + PawnOwner.Eyeheight * Z;
	AdjustedAim = PawnOwner.AdjustAim(1000000, StartTrace, 0*AimError, False, False);
	X = vector(AdjustedAim);
	EndTrace = StartTrace + 10000 * X;
	Other = PawnOwner.TraceShot(HitLocation,HitNormal,EndTrace,StartTrace);
	ProcessTraceHit(Other, HitLocation, HitNormal, X,Y,Z);
	
	ProjectileFire(Class'UnrealShare.DispersionAmmo2', 1, False);
	ProjectileFire(Class'UnrealShare.rocketS2', 1, False);
	ProjectileFire(Class'Botpack.rocketmk2S2', 1, False);
	ProjectileFire(Class'Botpack.Razor2AltS2', 1, False);
	ProjectileFire(Class'UnrealI.RazorBladeAltS2', 1, False);
	ProjectileFire(Class'Botpack.PlasmaSphere2', 1, False);
	
	for(i=0; i<9; i++)
		ProjectileFire(Class'Botpack.UTChunkS2', 1, False);

}



function ProcessTraceHit(Actor Other, Vector HitLocation, Vector HitNormal, Vector X, Vector Y, Vector Z)
{
	local UT_Shellcase s;
	
	s = Spawn(class'UT_ShellCase',, '', Owner.Location + CalcDrawOffset() + 30 * X + (2.8 * FireOffset.Y+5.0) * Y - Z * 1);
	
	
	if ( s != None )
	{
		s.DrawScale = 2.0;
		s.Eject(((FRand()*0.3+0.4)*X + (FRand()*0.2+0.2)*Y + (FRand()*0.3+1.0) * Z)*160);
	}
	
	if (Other == Level)
	{
		Spawn(class'UT_HeavyWallHitEffect',,, HitLocation+HitNormal, Rotator(HitNormal));
		Spawn(class'RingExplosion4',,, HitLocation+HitNormal, Rotator(HitNormal));
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
			Other.TakeDamage(500, Pawn(Owner), HitLocation, 35000 * X, AltDamageType);
			spawn(class'ut_SuperRing2',,,HitLocation+HitNormal*9);
		}
		else
		{
			Other.TakeDamage(60, Pawn(Owner), HitLocation, 30000.0*X, MyDamageType);
			Spawn(class'RingExplosion4',,, HitLocation+HitNormal, Rotator(HitNormal));
		}
		if ( !Other.bIsPawn && !Other.IsA('Carcass') )
		{
			spawn(class'UT_SpriteSmokePuff',,,HitLocation+HitNormal*9);
		}
	}
}






///////////////////////////////////////////////////////
state NormalFire
{
	function EndState()
	{
		Super.EndState();
		OldFlashCount = FlashCount;
	}
		
Begin:
	FlashCount++;
}

function Timer()
{
	local actor targ;
	local float bestAim, bestDist;
	local vector FireDir;
	local Pawn P;

	bestAim = 0.95;
	P = Pawn(Owner);
	if ( P == None )
	{
		GotoState('');
		return;
	}
	if ( VSize(P.Location - OwnerLocation) < 6 )
		StillTime += FMin(2.0, Level.TimeSeconds - StillStart);

	else
		StillTime = 0;
	StillStart = Level.TimeSeconds;
	OwnerLocation = P.Location;
	FireDir = vector(P.ViewRotation);
	targ = P.PickTarget(bestAim, bestDist, FireDir, Owner.Location);
	if ( Pawn(targ) != None )
	{
		SetTimer(1 + 4 * FRand(), false);
		bPointing = true;
		Pawn(targ).WarnTarget(P, 200, FireDir);
	}
	else 
	{
		SetTimer(0.4 + 1.6 * FRand(), false);
		if ( (P.bFire == 0) && (P.bAltFire == 0) )
			bPointing = false;
	}
}

function Finish()
{
	if ( (Pawn(Owner).bFire!=0) && (FRand() < 0.6) )
		Timer();
	Super.Finish();
}

state Idle
{
	function Fire( float Value )
	{
		if ( AmmoType == None )
		{
			// ammocheck
			GiveAmmo(Pawn(Owner));
		}
		if (AmmoType.UseAmmo(1))
		{
			GotoState('NormalFire');
			bCanClientFire = true;
			bPointing=True;
			if ( Owner.IsA('Bot') )
			{
				// simulate bot using zoom
				if ( Bot(Owner).bSniping && (FRand() < 0.65) )
					AimError = AimError/FClamp(StillTime, 1.0, 8.0);
				else if ( VSize(Owner.Location - OwnerLocation) < 6 )
					AimError = AimError/FClamp(0.5 * StillTime, 1.0, 3.0);
				else
					StillTime = 0;
			}
			Pawn(Owner).PlayRecoil(FiringSpeed);
			TraceFire(0.0);
			AimError = Default.AimError;
			ClientFire(Value);
		}
	}


	function BeginState()
	{
		bPointing = false;
		SetTimer(0.4 + 1.6 * FRand(), false);
		Super.BeginState();
	}

	function EndState()
	{	
		SetTimer(0.0, false);
		Super.EndState();
	}
	
Begin:
	bPointing=False;
	if ( AmmoType.AmmoAmount<=0 ) 
		Pawn(Owner).SwitchToBestWeapon();  //Goto Weapon that has Ammo
	if ( Pawn(Owner).bFire!=0 ) Fire(0.0);
	Disable('AnimEnd');
	PlayIdleAnim();
}

///////////////////////////////////////////////////////
state Zooming
{
	simulated function Tick(float DeltaTime)
	{
		if ( Pawn(Owner).bAltFire == 0 )
		{
			if ( (PlayerPawn(Owner) != None) && PlayerPawn(Owner).Player.IsA('ViewPort') )
				PlayerPawn(Owner).StopZoom();
			SetTimer(0.0,False);
			GoToState('Idle');
		}
	}

	simulated function BeginState()
	{
		if ( Owner.IsA('PlayerPawn') )
		{
			if ( PlayerPawn(Owner).Player.IsA('ViewPort') )
				PlayerPawn(Owner).ToggleZoom();
			SetTimer(0.2,True);
		}
		else
		{
			Pawn(Owner).bFire = 1;
			Pawn(Owner).bAltFire = 0;
			Global.Fire(0);
		}
	}
}

///////////////////////////////////////////////////////////
simulated function PlayIdleAnim()
{
	if ( Mesh != PickupViewMesh )
		PlayAnim('Still',1.0, 0.05);
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
	FireAnims(0)=Fire
	FireAnims(1)=Fire2
	FireAnims(2)=Fire3
	FireAnims(3)=Fire4
	FireAnims(4)=Fire5
	ItemName="Magic Sniper"
	PickupMessage="You got a Magic Sniper."
	FireSound=Sound'UnrealShare.flak.Click'
	MFTexture=Texture'MagicSniper.MagicSniper.magiccrosshair'
	
	PickupAmmoCount=50
	
	AutoSwitchPriority=5
	FiringSpeed=1.00000
	InventoryGroup=10

	
	
	WeaponDescription="Rixuel's Magic Sniper."
	AmmoName=Class'Botpack.BulletBox'

	bInstantHit=True
	bAltInstantHit=True

	FireOffset=(Y=-5.000000,Z=-2.000000)
	MyDamageType=shot
	AltDamageType=Decapitated
	shakemag=400.000000
	shaketime=0.150000
	shakevert=8.000000
	AIRating=0.540000
	RefireRate=0.600000
	AltRefireRate=0.300000

	SelectSound=Sound'UnrealI.Rifle.RiflePickup'
	DeathMessage="%k put a bullet through %o's head."
	NameColor=(R=0,G=0)
	bDrawMuzzleFlash=True
	MuzzleScale=1.000000
	FlashY=0.110000
	FlashO=0.014000
	FlashC=0.031000
	FlashLength=0.013000
	FlashS=256


	ItemName="Magic Sniper Rifle"
	PlayerViewOffset=(X=5.000000,Y=-1.600000,Z=-1.700000)
	PlayerViewMesh=LodMesh'Botpack.Rifle2m'
	PlayerViewScale=2.000000
	BobDamping=0.975000
	PickupViewMesh=LodMesh'Botpack.RiflePick'
	ThirdPersonMesh=LodMesh'Botpack.RifleHand'
	StatusIcon=Texture'Botpack.Icons.UseRifle'
	bMuzzleFlashParticles=True
	MuzzleFlashStyle=STY_Translucent
	MuzzleFlashMesh=LodMesh'Botpack.muzzsr3'
	MuzzleFlashScale=0.100000
	MuzzleFlashTexture=Texture'Botpack.Skins.Muzzy3'
	PickupSound=Sound'UnrealShare.Pickups.WeaponPickup'
	Icon=Texture'Botpack.Icons.UseRifle'
	Rotation=(Roll=-1536)
	Mesh=LodMesh'Botpack.RiflePick'
	bNoSmooth=False
	CollisionRadius=32.000000
	CollisionHeight=8.000000
	
	
	Multiskins(2)=Texture'MagicSniper.Skins.MagicRifle2'

	MultiSkinsFirstPerson(0)=Texture'MagicSniper.Skins.MagicRifle2a'
	MultiSkinsFirstPerson(1)=Texture'MagicSniper.Skins.MagicRifle2b'
	MultiSkinsFirstPerson(2)=Texture'MagicSniper.Skins.MagicRifle2c'
	MultiSkinsFirstPerson(3)=Texture'MagicSniper.Skins.MagicRifle2d'
}