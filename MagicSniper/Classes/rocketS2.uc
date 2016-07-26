class rocketS2 extends Projectile;

var Actor Seeking;
var float MagnitudeVel,Count,SmokeRate;
var vector InitialDir;
var bool bRing,bHitWater,bWaterStart;
var int NumExtraRockets;

simulated function PostBeginPlay()
{
	Count = -0.1;
	if (Level.bHighDetailMode) SmokeRate = 0.035;
		else SmokeRate = 0.15;
}

simulated function Tick(float DeltaTime)
{
	//local RingExplosion4 b;
	local ShockBeam b;
	local supershockbeam bb;
	
	if (bHitWater)
	{
		Disable('Tick');
		Return;
	}
	
	Count += DeltaTime;
	if ( (Count>(SmokeRate+FRand()*(SmokeRate+NumExtraRockets*0.035))) && (Level.NetMode!=NM_DedicatedServer) )
	{
		b = Spawn(class'ShockBeam');
		b.RemoteRole = ROLE_None;
		bb = Spawn(class'supershockbeam');
		bb.RemoteRole = ROLE_None;
		Count=0.0;
	}
}

auto state Flying
{
	simulated function ZoneChange( Zoneinfo NewZone )
	{
	local waterring w;
	if (!NewZone.bWaterZone || bHitWater) Return;
	bHitWater = True;
	Disable('Tick');
	if ( Level.NetMode != NM_DedicatedServer )
	{
	w = Spawn(class'WaterRing',,,,rot(16384,0,0));
	w.DrawScale = 0.2;
	w.RemoteRole = ROLE_None;
	PlayAnim( 'Still', 3.0 );
	}
	Velocity=0.6*Velocity;
	}

	simulated function ProcessTouch (Actor Other, Vector HitLocation)
	{
	if ((Other != instigator) && (Rocket(Other) == none))
	Explode(HitLocation,Normal(HitLocation-Other.Location));
	}

	function BlowUp(vector HitLocation, RingExplosion r)
	{
		if ( Level.Game.IsA('DeathMatchGame') ) //bigger damage radius
			HurtRadius(0.9 * Damage,240.0, 'exploded', MomentumTransfer, HitLocation );
		else
			HurtRadius(Damage,200.0, 'exploded', MomentumTransfer, HitLocation );
			
		MakeNoise(1.0);
		if ( r != None )
			r.PlaySound(r.ExploSound,,5);
	}

	simulated function Explode(vector HitLocation, vector HitNormal)
	{
		//local SpriteBallExplosion s;
		local EnergyBurst s;
		local RingExplosion3 r;
		
		s = spawn(class'EnergyBurst',,,HitLocation + HitNormal*16);
		s.RemoteRole = ROLE_None;
		
		if (bRing)
		{
			r = Spawn(class'RingExplosion3',,,HitLocation + HitNormal*16,rotator(HitNormal));
			r.RemoteRole = ROLE_None;
		}
		BlowUp(HitLocation, r);
		Destroy();
	}

	function BeginState()
	{
		initialDir = vector(Rotation);
		if ( Role == ROLE_Authority )
		Velocity = speed*initialDir;
		Acceleration = initialDir*50;
		PlaySound(SpawnSound, SLOT_None, 2.3);
		PlayAnim( 'Armed', 0.2 );
		if (Region.Zone.bWaterZone)
		{
		bHitWater = True;
		Velocity=0.6*Velocity;
		}
	}
}

defaultproperties
{
	speed=3600.000000
	MaxSpeed=3600.000000
	Damage=85.000000
	MomentumTransfer=80000
	SpawnSound=Sound'UnrealShare.Pickups.FSHLITE2'

	RemoteRole=ROLE_SimulatedProxy
	LifeSpan=6.000000
	AnimSequence=Armed
	AmbientSound=Sound'UnrealShare.General.Brufly1'
	Skin=FireTexture'UnrealShare.Effect16.fireeffect16'
	Mesh=LodMesh'UnrealShare.RocketM'
	DrawScale=0.100000
	AmbientGlow=96
	bUnlit=True
	SoundRadius=6
	SoundVolume=50
	LightType=LT_Steady
	LightEffect=LE_NonIncidence
	LightBrightness=100
	LightHue=28
	LightSaturation=64
	LightRadius=6
	bCorona=True
	bBounce=True
}