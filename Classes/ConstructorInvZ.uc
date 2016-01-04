//=============================================================================
// Constructor Weapon Zoned
// Coded by .:..:
//=============================================================================
class ConstructorInvZ extends ConstructorInv;

replication
{
	// functions called by client on server
	reliable if( Role<ROLE_Authority )
		GiveVolumeFor,ClearVolume;
}

function ServerPlaceBrick( int BrickNum, int XPos, int YPos, int ZPos, int VYaw, int VPitch, int VRoll, CompressedDS Scale )
{
	local MiniVector M;
	local rotator R;
	local vector SP,D3DScale;
	local NetStaticMesh MyMesh;
	local PhysicsVolume P;

	M.X = XPos;
	M.Y = YPos;
	M.Z = ZPos;
	R.Yaw = VYaw;
	R.Pitch = VPitch;
	R.Roll = VRoll;
	SP = MiniToBig(M);
	if( !ValidVolume(FindVolumeFor(SP,Level,P)) )
	{
		Pawn(Owner).ClientMessage("You may not build there!");
		Return;
	}
	if( Scale.X==0 ) // Zero sized bricks arent allowed!
		Scale.X = 1;
	if( Scale.Y==0 )
		Scale.Y = 1;
	if( Scale.Z==0 )
		Scale.Z = 1;
	D3DScale = DecompressVect(Scale);
	R = DecompressRotation(R);
	MyMesh = Spawn(Class'NetStaticMesh',,,SP,R);
	if( BrickNum<0 || BrickNum>=Class'ConstructorInv'.Static.GetMeshListMaxLen() )
		BrickNum = 0;
	MyMesh.SetDrawScale3D(D3DScale);
	MyMesh.SetStaticMesh(Class'ConstructorInv'.Static.IntToMesh(BrickNum));
	if( Level.NetMode!=NM_DedicatedServer )
		MyMesh.AddAntiPortal(BrickNum);
	MyMesh.VisualFX = Class'ConstructorInv'.Static.GetFXEmitter(MyMesh,BrickNum,MyMesh.DrawScale3D.X);
	if( MyMesh.StaticMesh==None )
	{
		MyMesh.bUseCylinderCollision = True;
		MyMesh.SetCollision(True,False,False);
		MyMesh.bBlockNonZeroExtentTraces = False;
		MyMesh.KSetBlockKarma(False);
		MyMesh.SetCollisionSize(20*MyMesh.DrawScale3D.X,25*MyMesh.DrawScale3D.X);
	}
	MyMesh.UpdateNetClients(BrickNum);
	if( P!=None && PrivateBuildZone(P)!=None )
	{
		MyMesh.MyPalace = PrivateBuildZone(P).DataPool;
		if( MyMesh.MyPalace!=None )
			MyMesh.MyPalace.SaveBrickData(XPos,YPos,ZPos,VYaw,VPitch,BrickNum,Scale.X,Scale.Y,Scale.Z,MyMesh);
	}
}
Static function PhysicsVolume FindVolumeFor( vector Pos, LevelInfo XLev, optional out PhysicsVolume PHY )
{
	local PhysicsVolume P,PP;

	P = XLev.GetPhysicsVolume(Pos);
	PHY = P;
	if( P!=None && (P.IsA('PublicBuildZone') || P.IsA('PrivateBuildZone')) )
		Return P;
	P = XLev.GetPhysicsVolume(Pos+vect(0,0,32));
	PP = XLev.GetPhysicsVolume(Pos-vect(0,0,32));
	PHY = P;
	if( P==PP )
		Return P;
	PHY = None;
	Return None;
}
function bool ValidVolume( PhysicsVolume Other )
{
	if( Other==None ) Return False;
	if( Other.IsA('PublicBuildZone') )
		Return True;
	else if( Other.IsA('PrivateBuildZone') && PrivateBuildZone(Other).PlayerIsTheOwner(Instigator.Controller) )
		Return True;
	Return False;
}
simulated exec function GiveVolumeFor( int ID )
{
	local PlayerController C;
	local PrivateBuildZone PZ;

	if( Pawn(Owner).PlayerReplicationInfo==None || (!Pawn(Owner).PlayerReplicationInfo.bAdmin && Level.NetMode != NM_StandAlone) )
		Return;
	PZ = PrivateBuildZone(Owner.PhysicsVolume);
	if( PZ==None || PZ.DataPool==None )
	{
		Pawn(Owner).ClientMessage("Bad destination volume");
		Return;
	}
	C = FindPlayerByID(ID);
	if( C==None )
	{
		Pawn(Owner).ClientMessage("Missing player ID");
		Return;
	}
	PZ.PRIOwner = C.PlayerReplicationInfo;
	PZ.AddAnOwner(C);
	if( PZ.DataPool.AreaOwnerID=="" )
	{
		PZ.DataPool.AreaOwnerID = C.GetPlayerIDHash();
		PZ.DataPool.AreaOwnedName = C.PlayerReplicationInfo.PlayerName;
		PZ.DataPool.AreaOwnerIP = C.GetPlayerNetworkAddress();
		Pawn(Owner).ClientMessage("Gave this area for"@C.PlayerReplicationInfo.PlayerName);
	}
	else
	{
		PZ.DataPool.AddCoOwner(C.GetPlayerIDHash(),C.PlayerReplicationInfo.PlayerName);
		Pawn(Owner).ClientMessage("Added co-owner for this area, who is"@C.PlayerReplicationInfo.PlayerName);
	}
	PZ.DataPool.bDataChanged = True;
}
simulated exec function ClearVolume()
{
	local PrivateBuildZone PZ;

	if( Pawn(Owner).PlayerReplicationInfo==None || (!Pawn(Owner).PlayerReplicationInfo.bAdmin && Level.NetMode != NM_StandAlone) )
		Return;
	PZ = PrivateBuildZone(Owner.PhysicsVolume);
	if( PZ==None || PZ.DataPool==None )
	{
		Pawn(Owner).ClientMessage("Bad destination volume");
		Return;
	}
	if( PZ.DataPool.AreaOwnerID=="" )
	{
		Pawn(Owner).ClientMessage("Volume is already empty!");
		Return;
	}
	PZ.PRIOwner = None;
	Pawn(Owner).ClientMessage("Cleared"@PZ.DataPool.AreaOwnedName$"'s area");
	PZ.DataPool.ClearEverything();
}
simulated exec function CheckIDs()
{
	local PlayerReplicationInfo PRI;

	if( Pawn(Owner).PlayerReplicationInfo==None || (!Pawn(Owner).PlayerReplicationInfo.bAdmin && Level.NetMode != NM_StandAlone) )
		Return;
	Pawn(Owner).ClientMessage("Players ID list:");
	ForEach DynamicActors(class'PlayerReplicationInfo',PRI)
		Pawn(Owner).ClientMessage(PRI.PlayerName$"'s ID is"@PRI.PlayerID);
}
function PlayerController FindPlayerByID( int ID )
{
	local Controller C;

	For( C=Level.ControllerList; C!=None; C=C.NextController )
	{
		if( C.IsA('PlayerController') && C.PlayerReplicationInfo!=None && C.PlayerReplicationInfo.PlayerID==ID )
			Return PlayerController(C);
	}
	Return None;
}

// Ugly stuff on screen :D.
// Removed its useless people still ask the cmds... -.-
/*simulated event RenderOverlays( Canvas Canvas )
{
	Canvas.DrawColor.A = 255;
	Canvas.Font = Font'Engine.DefaultFont';
	if( Canvas.ViewPort.Actor.PlayerReplicationInfo!=None && (Canvas.ViewPort.Actor.PlayerReplicationInfo.bAdmin || Level.NetMode == NM_StandAlone) )
	{
		Canvas.SetPos(10,88);
		Canvas.SetDrawColor(255,150,150);
		Canvas.DrawText("Admins: Type 'GiveVolumeFor <ID>' to give current volume for a player! 'CheckIDs' to see full list of player ID's, 'ClearVolume' clear the current volumes data/owner.");
	}
	Canvas.SetPos(10,64);
	Canvas.SetDrawColor(255,255,255);
	super.RenderOverlays( Canvas );
}*/

defaultproperties
{
     PickupClass=Class'Constructor.ConstructorZ'
     ItemName="Constructor Gun Zoned"
}
