// Graffiti Tool by Rixuel. Weapon for Monster Hunt.

class GraffitiTool extends TournamentWeapon;

var() int hitdamage;
var  float AltAccuracy;
var Enforcer SlaveEnforcer;		// The left (second) Enforcer is a slave to the right.
var bool bIsSlave;
var bool bSetup;				// used for setting display properties
var bool bFirstFire, bBringingUp;
var() texture MuzzleFlashVariations[5];

var int choiceGT;
var int PrimaryFireSpeed;

function Destroyed()
{
	Super.Destroyed();
}
function setHand(float Hand)
{
	local rotator newRot;

	if ( Hand == 2 )
	{
		bHideWeapon = true;
		Super.SetHand(Hand);
		return;
	}

	bHideWeapon = false;
	Super.SetHand(Hand);
	if ( Hand == 1 )
		Mesh = mesh'AutoML';
	else
		Mesh = mesh'AutoMR';
}

simulated function PlayFiring()
{	
	PlayOwnedSound(FireSound, SLOT_None,1.0*Pawn(Owner).SoundDampening);
	bMuzzleFlash++;
	PlayAnim('Shoot', (6.0) + (6.0) * FireAdjust, PrimaryFireSpeed);
}

// Alt Firing Option
simulated function PlayRepeatFiring()
{
	if ( Affector != None )
		Affector.FireEffect();
		
	if ( PlayerPawn(Owner) != None )
	{
		PlayerPawn(Owner).ClientInstantFlash( -0.2, vect(325, 225, 95));
		PlayerPawn(Owner).ShakeView(ShakeTime, ShakeMag, ShakeVert);
	}
	
	bMuzzleFlash++;
	PlayOwnedSound(Sound'Botpack.enforcer.Reload', SLOT_None,1.0*Pawn(Owner).SoundDampening);
	PlayAnim('Shot2', 1.0 + 0.75 * FireAdjust, 0.05);
}


function ProcessTraceHit(Actor Other, Vector HitLocation, Vector HitNormal, Vector X, Vector Y, Vector Z)
{
	local vector realLoc;	
	realLoc = Owner.Location + CalcDrawOffset();
	
	if(choiceGT==0)
	{

		if (Other == Level)
		{
			Spawn(class'UT_RingExplosion5',,, HitLocation+HitNormal, Rotator(HitNormal));
		}
		else if ((Other != self) && (Other != Owner) && (Other != None) )
		{
			if ( FRand() < 0.2 )
				X *= 5;
			Other.TakeDamage(HitDamage, Pawn(Owner), HitLocation, 0.0*X, MyDamageType);
			
			if ( !Other.bIsPawn && !Other.IsA('Carcass') )
				spawn(class'UT_RingExplosion5',,,HitLocation+HitNormal*9);
			else
				Other.PlaySound(Sound 'ChunkHit',, 4.0,,100);
		}
		
	}
	else if(choiceGT==1)
	{
		EffectFire(Class'UnrealI.QueenShield', AltProjectileSpeed, bAltWarnTarget);
		PlayOwnedSound(Sound'UnrealShare.Teleport1', SLOT_Misc, 3.0*Pawn(Owner).SoundDampening);
	}
	else if(choiceGT==2)
	{	
		if(PlayerPawn(Owner).Health<2500)
		{
			PlayerPawn(Owner).Health+=25;			
			Spawn(class'ReSpawn');
		}
	}
	
}




function Fire(float Value)
{
	if ( AmmoType.UseAmmo(0) )
	{
		GotoState('NormalFire');
		bCanClientFire = true;
		bPointing=True;
		ClientFire(value);
			
		TraceFire(0.0);
	}
}


function AltFire( float Value )
{
	bPointing=True;
	bCanClientFire = true;
	AltAccuracy = 0.4;
	if ( AmmoType == None )
	{
		// ammocheck
		GiveAmmo(Pawn(Owner));
	}
	if (AmmoType.AmmoAmount>0)
	{
		ClientAltFire(value);
		GotoState('AltFiring');
	}
}


state AltFiring
{
	ignores Fire, AltFire, AnimEnd;
	
		function Timer()
		{

		}
		function EndState()
		{
			Super.EndState();
			//OldFlashCount = FlashCount;
		}
		
	Begin:
		FinishAnim();
		
	Repeater:	
		if (AmmoType.UseAmmo(0))
		{
			//FlashCount++;
			
			if (choiceGT==0)
			{
				choiceGT=1;
				PrimaryFireSpeed=1.0;
				PlayerPawn(Owner).ClientMessage("Graffiti Tool MODE - Shielder"); // Say next weapon
			}
			else if (choiceGT==1)
			{
				choiceGT=2;
				PrimaryFireSpeed=1.0;
				PlayerPawn(Owner).ClientMessage("Graffiti Tool MODE - Recovery"); // Say next weapon
			}
			else if (choiceGT==2)
			{
				choiceGT=0;
				PrimaryFireSpeed=0.2;
				PlayerPawn(Owner).ClientMessage("Graffiti Tool MODE - Normal"); // Say next weapon
			}
			
			
			//EffectFire(Class'UnrealI.QueenShield', AltProjectileSpeed, bAltWarnTarget);
			
			PlayRepeatFiring();
			FinishAnim();
		}
		
		

		if ( bIsSlave )
		{
			if ( (Pawn(Owner).bAltFire!=0)
			&& AmmoType.AmmoAmount>0 )
			Goto('Repeater');
		}
		else if ( bChangeWeapon )
			GotoState('DownWeapon');
		else if ( (Pawn(Owner).bAltFire!=0)
		&& AmmoType.AmmoAmount>0 )
		{
			if ( PlayerPawn(Owner) == None )
			Pawn(Owner).bAltFire = int( FRand() < AltReFireRate );
			Goto('Repeater');
		}
		
		PlayAnim('T2', 0.9, 0.05);
		FinishAnim();
		Finish();
}




function Effects EffectFire(class<effects> ProjClass, float ProjSpeed, bool bWarn)
{
	local Vector Start, X,Y,Z;
	local Pawn PawnOwner;
	
	PawnOwner = Pawn(Owner);
	Owner.MakeNoise(PawnOwner.SoundDampening);
	GetAxes(PawnOwner.ViewRotation,X,Y,Z);
	Start = Owner.Location + CalcDrawOffset() + FireOffset.X * X + FireOffset.Y * Y + FireOffset.Z * Z;
	AdjustedAim = PawnOwner.AdjustAim(ProjSpeed, Start, AimError, True, bWarn);
	return Spawn(ProjClass,,, Start,AdjustedAim);
}


// Took me hour to find this culprit function. Need it to disable double weapon wielding.
function bool HandlePickupQuery( inventory Item )
{
	local Pawn P;
	local Inventory Copy;

	if ( (Item.class == class) && (SlaveEnforcer == None) ) 
	{
		P = Pawn(Owner);
		AIRating = 0.4;
		if (Level.Game.LocalLog != None)
			Level.Game.LocalLog.LogPickup(Item, Pawn(Owner));
		if (Level.Game.WorldLog != None)
			Level.Game.WorldLog.LogPickup(Item, Pawn(Owner));
		return true;
	}
	return Super.HandlePickupQuery(Item);
}



// ========================
simulated event RenderOverlays(canvas Canvas)
{
	local PlayerPawn PlayerOwner;
	local int realhand;

	if ( (bMuzzleFlash > 0) && !Level.bDropDetail )
		MFTexture = MuzzleFlashVariations[Rand(5)];
	PlayerOwner = PlayerPawn(Owner);
	if ( PlayerOwner != None )
	{
		if ( PlayerOwner.DesiredFOV != PlayerOwner.DefaultFOV )
			return;
		realhand = PlayerOwner.Handedness;
		if (  (Level.NetMode == NM_Client) && (realHand == 2) )
		{
			bHideWeapon = true;
			return;
		}
		if ( !bHideWeapon )
		{
			if ( Mesh == mesh'AutoML' )
				PlayerOwner.Handedness = 1;
			/*else if ( bIsSlave || (SlaveEnforcer != None) )
				PlayerOwner.Handedness = -1;*/
		}
	}
	if ( (PlayerOwner == None) || (PlayerOwner.Handedness == 0) )
	{
		if ( AnimSequence == 'Shot2' )
		{
			FlashO = -2 * Default.FlashO;
			FlashY = Default.FlashY * 2.5;
		}
		else
		{
			FlashO = 1.9 * Default.FlashO;
			FlashY = Default.FlashY;
		}
	}
	else if ( AnimSequence == 'Shot2' )
	{
		FlashO = Default.FlashO * 0.3;
		FlashY = Default.FlashY * 2.5;
	}
	else
	{
		FlashO = Default.FlashO;
		FlashY = Default.FlashY;
	}

	Super.RenderOverlays(Canvas);

	if ( PlayerOwner != None )
		PlayerOwner.Handedness = realhand;
}



defaultproperties
{
	hitdamage=0
	ItemName="Graffiti Tool"
	PickupMessage="You got a Graffiti Tool. Drawing Time!!"
	FireSound=Sound'UnrealShare.ASMD.Vapour'
	
	MuzzleFlashVariations(0)=Texture'Botpack.ShockExplo.asmdex_a06'
	MuzzleFlashVariations(1)=Texture'Botpack.ShockExplo.asmdex_a07'
	MuzzleFlashVariations(2)=Texture'Botpack.ShockExplo.asmdex_a08'
	MuzzleFlashVariations(3)=Texture'Botpack.ShockExplo.asmdex_a09'
	MuzzleFlashVariations(4)=Texture'Botpack.ShockExplo.asmdex_a10'

	AutoSwitchPriority=3
	FiringSpeed=1.00000
	InventoryGroup=1
	
	WeaponDescription="A graffiti tool with other utilities."
	InstFlash=-0.200000
	InstFog=(X=325.000000,Y=225.000000,Z=95.000000)
	AmmoName=Class'Botpack.Miniammo'
	PickupAmmoCount=30
	bInstantHit=True
	bAltInstantHit=True
	
	FireOffset=(Y=-10.000000,Z=-4.000000)
	MyDamageType=shot
	shakemag=200.000000
	shakevert=4.000000
	AIRating=0.250000
	RefireRate=0.800000
	AltRefireRate=0.870000

	AltFireSound=Sound'UnrealShare.AutoMag.shot'
	CockingSound=Sound'Botpack.enforcer.Cocking'
	SelectSound=Sound'Botpack.enforcer.Cocking'

	NameColor=(R=200,G=200)
	bDrawMuzzleFlash=True
	MuzzleScale=1.000000
	FlashY=0.100000
	FlashO=0.020000
	FlashC=0.035000
	FlashLength=0.020000
	FlashS=128
	MFTexture=Texture'Botpack.Skins.Muz1'


	PlayerViewOffset=(X=3.300000,Y=-2.000000,Z=-3.000000)
	PlayerViewMesh=LodMesh'Botpack.AutoML'
	PickupViewMesh=LodMesh'Botpack.MagPick'
	ThirdPersonMesh=LodMesh'Botpack.AutoHand'
	StatusIcon=Texture'Botpack.Icons.UseAutoM'
	bMuzzleFlashParticles=True
	MuzzleFlashStyle=STY_Translucent

	MuzzleFlashScale=0.080000
	MuzzleFlashTexture=Texture'Botpack.Skins.Muzzy2'
	PickupSound=Sound'UnrealShare.Pickups.WeaponPickup'
	Icon=Texture'Botpack.Icons.UseAutoM'
	bHidden=True
	Mesh=LodMesh'Botpack.MagPick'
	bNoSmooth=False
	CollisionRadius=24.000000
	CollisionHeight=12.000000
	Mass=15.000000
}
