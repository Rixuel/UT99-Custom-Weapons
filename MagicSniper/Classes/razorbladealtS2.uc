//=============================================================================
// RazorBladeAlt.
//=============================================================================
class RazorBladeAltS2 extends RazorBlade;

var int NumWallHits;
var bool bCanHitInstigator, bHitWater;

/////////////////////////////////////////////////////
auto state Flying
{
	simulated function ProcessTouch (Actor Other, Vector HitLocation)
	{
		if ( bCanHitInstigator || (Other != Instigator) ) 
		{
			if ( Role == ROLE_Authority )
			{
				if ( Other.IsA('Pawn') && (HitLocation.Z - Other.Location.Z > 0.62 * Other.CollisionHeight)
					&& (instigator.IsA('PlayerPawn') || (instigator.skill > 1))
					&& (!Other.IsA('ScriptedPawn') || !ScriptedPawn(Other).bIsBoss) )
					Other.TakeDamage(3.5 * damage, instigator,HitLocation,
						(MomentumTransfer * Normal(Velocity)), 'decapitated' );
				else			 
					Other.TakeDamage(damage, instigator,HitLocation,
						(MomentumTransfer * Normal(Velocity)), 'shredded' );
			}
			if ( Other.IsA('Pawn') )
				PlaySound(MiscSound, SLOT_Misc, 2.0);
			else
				PlaySound(ImpactSound, SLOT_Misc, 2.0);
			destroy();
		}
	}

	simulated function ZoneChange( Zoneinfo NewZone )
	{
		local Splash w;
		
		if (!NewZone.bWaterZone || bHitWater) Return;

		bHitWater = True;
		w = Spawn(class'Splash',,,,rot(16384,0,0));
		w.DrawScale = 0.5;
		w.RemoteRole = ROLE_None;
		Velocity=0.6*Velocity;
	}

	simulated function SetRoll(vector NewVelocity) 
	{
		local rotator newRot;	
	
		newRot = rotator(NewVelocity);	
		SetRotation(newRot);	
	}

	simulated function HitWall (vector HitNormal, actor Wall)
	{
		
		bCanHitInstigator = true;
		PlaySound(ImpactSound, SLOT_Misc, 2.0);
		LoopAnim('Spin',1.0);
		if ( (Mover(Wall) != None) && Mover(Wall).bDamageTriggered )
		{
			if ( Role == ROLE_Authority )
				Wall.TakeDamage( Damage, instigator, Location, MomentumTransfer * Normal(Velocity), '');
			Destroy();
			return;
		}
		NumWallHits++;
		SetTimer(0, False);
		MakeNoise(0.3);
		if ( NumWallHits > 0 )
			Destroy();
		Velocity -= 2 * ( Velocity dot HitNormal) * HitNormal;  
		SetRoll(Velocity);
	}

	function SetUp()
	{
		local vector X;

		X = vector(Rotation);	
		Velocity = Speed * X;     // Impart ONLY forward vel
		if (Instigator.HeadRegion.Zone.bWaterZone)
			bHitWater = True;	
		PlaySound(SpawnSound, SLOT_None,4.2);
	}

	simulated function BeginState()
	{
		SetTimer(0.2, false);
		SetUp();

		if ( Level.NetMode != NM_DedicatedServer )
		{
			LoopAnim('Spin',1.0);
			if ( Level.NetMode == NM_Standalone )
				SoundPitch = 200 + 50 * FRand();
		}			
	}

	simulated function Timer()
	{
		bCanHitInstigator = true;
	}
}

defaultproperties
{
	speed=3600.000000
	MaxSpeed=3700.000000
	DrawScale=1.850000
	bNetTemporary=False
	SpawnSound=Sound'UnrealI.General.Bulletr2'
	SoundRadius=12
	SoundVolume=80
	SoundPitch=100
}
