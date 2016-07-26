//=============================================================================
// UTTeleEffect2.
//=============================================================================
class UTTeleEffect2 extends Effects;

function PostBeginPlay()
{
	Super.PostBeginPlay();
	LoopAnim('Teleport', 2.0, 0.0);
}

defaultproperties
{
     RemoteRole=ROLE_SimulatedProxy
     LifeSpan=0.500000
     DrawType=DT_Mesh
     Style=STY_Translucent
     Mesh=LodMesh'Botpack.Tele2'
     bUnlit=True
}