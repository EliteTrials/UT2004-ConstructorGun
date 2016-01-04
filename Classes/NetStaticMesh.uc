Class NetStaticMesh extends StaticMeshActor;

var int Brick,XPos,YPos,ZPos,VYaw,VPitch,VRoll,ThisActorNetcode,HeheeCode;
var Level ThisMapCode;
var bool bIBeenSent;
var ReplicationHandler MyHandler;
var byte D3DSize[3];
var NetAntiPortal MyPortal;
var ConstructData MyPalace;
var Actor VisualFX;

function UpdateNetClients( int BrickNum )
{
	local vector V;
	local rotator R;

	if( Level.NetMode==NM_StandAlone ) Return;
	Brick = BrickNum;
	V = Class'ConstructorInv'.Static.GetMiniVector(Location);
	XPos = V.X;
	YPos = V.Y;
	ZPos = V.Z;
	R = Class'ConstructorInv'.Static.CompressRotation(Rotation);
	if( DrawScale3D!=vect(1,1,1) ) // Dont replicate if size is 1
	{
		D3DSize[0] = DrawScale3D.X*5;
		D3DSize[1] = DrawScale3D.Y*5;
		D3DSize[2] = DrawScale3D.Z*5;
	}
	VYaw = R.Yaw;
	VPitch = R.Pitch;
	VRoll = R.Roll;
	CheckForMutator();
}
function CheckForMutator()
{
	local Mutator M;
	local ReplicationHandler RM;

	if( bIBeenSent ) Return;
	ThisActorNetcode = Class'NetStaticMesh'.Static.GetUniqueCode(XLevel);
	bIBeenSent = True;
	For( M=Level.Game.BaseMutator; M!=None; M=M.NextMutator )
	{
		if( ReplicationHandler(M)!=None )
		{
			MyHandler = ReplicationHandler(M);
			MyHandler.AddToReplicationList(Self);
			Return;
		}
	}
	RM = Spawn(class'ReplicationHandler');
	if( RM==None ) Return;
	RM.NextMutator = Level.Game.BaseMutator;
	Level.Game.BaseMutator = RM;
	RM.AddToReplicationList(Self);
	MyHandler = RM;
}
function AddAntiPortal( int Num )
{
	local ConvexVolume V;

	V = Class'ConstructorInv'.Static.IntToAntiPortal(Num);
	if( V==None ) Return;
	MyPortal = Spawn(class'NetAntiPortal',,,Location,Rotation);
	if( MyPortal==None ) Return;
	MyPortal.AntiPortal = V;
	if( DrawScale3D!=vect(1,1,1) )
		MyPortal.SetDrawScale3D(DrawScale3D);
}
// Used for identifing actors on clients.
Static function int GetUniqueCode( Level TheMap )
{
	if( Default.ThisMapCode!=TheMap )
	{
		Default.ThisMapCode = TheMap;
		Default.HeheeCode = 0;
		Return 0;
	}
	Default.HeheeCode++;
	Return Default.HeheeCode;
}
simulated function Destroyed()
{
	if( Level.NetMode!=NM_Client )
	{
		if( MyPalace!=None )
			MyPalace.DeleteBrickData(Self);
		if( MyHandler!=None )
			MyHandler.KillReplication(Self);
	}
	if( MyPortal!=None )
		MyPortal.Destroy();
	if( VisualFX!=None )
		VisualFX.Destroy();
}

defaultproperties
{
     bStatic=False
     RemoteRole=ROLE_None
     bMovable=False
}
