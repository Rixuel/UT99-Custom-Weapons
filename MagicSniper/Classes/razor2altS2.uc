//=============================================================================
// RazorBladeAlt.
//=============================================================================
class Razor2AltS2 extends Razor2;


simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	if ( Level.bDropDetail )
		LightType = LT_None;
}

auto state Flying
{
	simulated function ProcessTouch (Actor Other, Vector HitLocation)
	{
		local RipperPulse s;

		if ( Other != Instigator ) 
		{
			if ( Role == ROLE_Authority )
			{
				Other.TakeDamage(damage, instigator,HitLocation,
					(MomentumTransfer * Normal(Velocity)), MyDamageType );
			}
			s = spawn(class'RipperPulse',,,HitLocation);	
 			s.RemoteRole = ROLE_None;
			MakeNoise(1.0);
 			Destroy();
		}
	}

	simulated function HitWall (vector HitNormal, actor Wall)
	{
		Super(Projectile).HitWall( HitNormal, Wall );
	}

	simulated function Explode(vector HitLocation, vector HitNormal)
	{
		local RipperPulse s;

		s = spawn(class'RipperPulse',,,HitLocation + HitNormal*16);	
 		s.RemoteRole = ROLE_None;
		BlowUp(HitLocation);

 		Destroy();
	}

	function BlowUp(vector HitLocation)
	{
		local actor Victims;
		local float damageScale, dist;
		local vector dir;

		if( bHurtEntry )
			return;

		bHurtEntry = true;
		foreach VisibleCollidingActors( class 'Actor', Victims, 180, HitLocation )
		{
			if( Victims != self )
			{
				dir = Victims.Location - HitLocation;
				dist = FMax(1,VSize(dir));
				dir = dir/dist;
				dir.Z = FMin(0.45, dir.Z); 
				damageScale = 1 - FMax(0,(dist - Victims.CollisionRadius)/180);
				Victims.TakeDamage
				(
					damageScale * Damage,
					Instigator, 
					Victims.Location - 0.5 * (Victims.CollisionHeight + Victims.CollisionRadius) * dir,
					damageScale * MomentumTransfer * dir,
					MyDamageType
				);
			} 
		}
		bHurtEntry = false;
		MakeNoise(1.0);
	}
}

defaultproperties
{
	speed=3500.000000
	MaxSpeed=3650.000000
	Damage=134.000000
	DrawScale=1.850000
	MomentumTransfer=87000
	MyDamageType=RipperAltDeath
	SpawnSound=Sound'Botpack.ripper.RazorAlt'
	ExplosionDecal=Class'Botpack.RipperMark'
	SoundRadius=12
	SoundVolume=80
	SoundPitch=100
	LightType=LT_Steady
	LightEffect=LE_NonIncidence
	LightBrightness=255
	LightHue=23
	LightRadius=3
}
