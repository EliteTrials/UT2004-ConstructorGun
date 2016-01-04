Class RenderActor extends Actor;

var Actor DeEmitter;

simulated function Timer()
{
	bHidden = True;
	if( DeEmitter!=None )
		DeEmitter.Destroy();
}
simulated function Destroyed()
{
	if( DeEmitter!=None )
		DeEmitter.Destroy();
}

defaultproperties
{
     DrawType=DT_StaticMesh
     bHidden=True
     RemoteRole=ROLE_None
}
