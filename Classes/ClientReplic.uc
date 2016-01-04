//=============================================================================
// ClientReplic.
//=============================================================================
class ClientReplic extends Info;

var ReplicationHandler Master;
var int SlotNum,Count,NumBricksDownloading,NumDLEdNow,NumMeshesNow,NumMeshDLs,ExpectedPacketNum;

replication
{
	// Functions server can call.
	reliable if( Role==ROLE_Authority )
		ClientAddBrick,ClientRemoveBrick,VisualizeArea,NumBricksDownloading,ClientDLBrick,NumMeshDLs,ClientDLMeshName;
	reliable if( Role<ROLE_Authority )
		ServerMissedAPacket,SendServerAReplyFM;
}

simulated function ClientDLBrick( int Num, int PN, int X, int Y, int Z, int Ya, int P, int Ro, int N, optional byte DX, optional byte DY, optional byte DZ )
{
	local PlayerController PC;

	if( Level.NetMode!=NM_Client ) Return;
	ClientAddBrick(Num,X,Y,Z,Ya,P,Ro,N,DX,DY,DZ);
	PC = Level.GetLocalPlayerController();
	if( PC!=None )
		PC.ReceiveLocalizedMessage(Class'DLMeshesMessage',,,,Self);
	if( Num<ExpectedPacketNum )
		Return; // A resend of an old packet
	While( ExpectedPacketNum<Num )
	{
		ServerMissedAPacket(ExpectedPacketNum);
		ExpectedPacketNum++;
	}
	ExpectedPacketNum++;
}
simulated function ClientAddBrick( int Num, int X, int Y, int Z, int Ya, int P, int Ro, int N, optional byte DX, optional byte DY, optional byte DZ )
{
	local NetStaticMesh NM;
	local bool bFound;
	local vector V,S;
	local rotator R;

	if( Level.NetMode!=NM_Client ) Return;
	bFound = False;
	ForEach DynamicActors(class'NetStaticMesh',NM)
	{
		if( NM.ThisActorNetcode==N )
		{
			bFound = True;
			Break;
		}
	}
	R.Yaw = Ya;
	R.Pitch = P;
	R.Roll = Ro;
	V.X = X;
	V.Y = Y;
	V.Z = Z;
	if( DX==0 )
		DX = 5;
	if( DY==0 )
		DY = 5;
	if( DZ==0 )
		DZ = 5;
	S.X = float(DX)/5;
	S.Y = float(DY)/5;
	S.Z = float(DZ)/5;
	if( !bFound || NM==None )
		NM = Spawn(class'NetStaticMesh',,,Class'ConstructorInv'.Static.GetBigVector(V),Class'ConstructorInv'.Static.DecompressRotation(R));
	if( NM!=None )
	{
		NM.ThisActorNetcode = N;
		NM.SetStaticMesh(Class'ConstructorInv'.Static.IntToMesh(Num));
		NM.VisualFX = Class'ConstructorInv'.Static.GetFXEmitter(NM,Num,S.X);
		NM.SetDrawScale3D(S);
		NM.AddAntiPortal(Num);
		if( NM.StaticMesh==None )
			NM.SetCollision(False,False,False);
	}
	if( !bFound )
		NumDLEdNow++;
}
simulated function ClientDLMeshName( int MNum, optional string SMName, optional string AntiP, optional string EClass )
{
	local StaticMesh SMA;
	local ConvexVolume CA;
	local class<Actor> AC;
	local PlayerController PC;

	if( Level.NetMode!=NM_Client ) Return;
	if( MNum==(NumMeshesNow-1) )
	{
		SendServerAReplyFM(MNum);
		Return;
	}
	if( SMName!="" )
		SMA = StaticMesh(DynamicLoadObject(SMName,Class'StaticMesh',True));
	if( SMA!=None && AntiP!="" )
		CA = ConvexVolume(DynamicLoadObject(AntiP,Class'ConvexVolume',True));
	if( SMA==None && EClass!="" )
		AC = Class<Actor>(DynamicLoadObject(EClass,Class'Class',True));
	Class'ConstructorInv'.Static.AddFXMeshType(XLevel,SMA,CA,AC);
	NumMeshesNow++;
	PC = Level.GetLocalPlayerController();
	if( PC!=None )
		PC.ReceiveLocalizedMessage(Class'DLMeshTypesMessage',,,,Self);
	SendServerAReplyFM(MNum);
}
function ServerMissedAPacket( int PacketNum );
function SendServerAReplyFM( int Num );
simulated function VisualizeArea( Volume Other )
{
	Other.bHidden = False;
	Other.SetDrawType(DT_Brush);
	ConsoleCommand("Flush");
}
simulated function ClientRemoveBrick( int N )
{
	local NetStaticMesh NM;

	if( Level.NetMode!=NM_Client ) Return;
	ForEach DynamicActors(class'NetStaticMesh',NM)
	{
		if( NM.ThisActorNetcode==N )
			NM.Destroy();
	}
}
function SendAllToClient()
{
	Master.SendFor[SlotNum].bInReplication = True;
	GoToState('Replicating');
}
function NotifyBrickDeleted( int BRNum );

State Replicating
{
	function EndState()
	{
		if( Master!=None )
			Master.SendFor[SlotNum].bInReplication = False;
	}
	function SendServerAReplyFM( int Num )
	{
		if( Count==Num )
			GoToState('Replicating','KeepDownloadingMeshes');
	}
	function ServerMissedAPacket( int PacketNum )
	{
		if( PacketNum<Master.ReplicationList.Length )
		{
			if( Master.ReplicationList[PacketNum].DrawScale3D==vect(1,1,1) )
				ClientDLBrick(Master.ReplicationList[PacketNum].Brick,PacketNum,Master.ReplicationList[PacketNum].XPos,Master.ReplicationList[PacketNum].YPos,Master.ReplicationList[PacketNum].ZPos,Master.ReplicationList[PacketNum].VYaw,Master.ReplicationList[PacketNum].VPitch,Master.ReplicationList[PacketNum].VRoll,Master.ReplicationList[PacketNum].ThisActorNetcode);
			else ClientDLBrick(Master.ReplicationList[PacketNum].Brick,PacketNum,Master.ReplicationList[PacketNum].XPos,Master.ReplicationList[PacketNum].YPos,Master.ReplicationList[PacketNum].ZPos,Master.ReplicationList[PacketNum].VYaw,Master.ReplicationList[PacketNum].VPitch,Master.ReplicationList[PacketNum].VRoll,Master.ReplicationList[PacketNum].ThisActorNetcode,Master.ReplicationList[PacketNum].D3DSize[0],Master.ReplicationList[PacketNum].D3DSize[1],Master.ReplicationList[PacketNum].D3DSize[2]);
		}
	}
	function NotifyBrickDeleted( int BRNum )
	{
		if( Count>BRNum )
			Count--;
	}
Begin:
	Sleep(5);
	Timer();
	Master.ScanForOwner(PlayerController(Owner),Self);
	Sleep(6);
	Timer();
	NumMeshDLs = Master.LoadedMeshes.Length;
	For( Count=0; Count<Master.LoadedMeshes.Length; Count++ )
	{
RetryDL2:
		Timer();
		if( Master.LoadedMeshes[Count].StaticM!=None )
		{
			if( Master.LoadedMeshes[Count].Convex!=None )
				ClientDLMeshName(Count,string(Master.LoadedMeshes[Count].StaticM),string(Master.LoadedMeshes[Count].Convex));
			else ClientDLMeshName(Count,string(Master.LoadedMeshes[Count].StaticM));
		}
		else ClientDLMeshName(Count,,,string(Master.LoadedMeshes[Count].EffectClass));
		Sleep(1);
		GoTo'RetryDL2';
KeepDownloadingMeshes:
		Sleep(0.01);
	}
	Sleep(1);
	For( Count=0; Count<Master.ReplicationList.Length; Count++ )
	{
		NumBricksDownloading = Master.ReplicationList.Length;
		Timer();
		if( Master.ReplicationList[Count].DrawScale3D==vect(1,1,1) )
			ClientDLBrick(Master.ReplicationList[Count].Brick,Count,Master.ReplicationList[Count].XPos,Master.ReplicationList[Count].YPos,Master.ReplicationList[Count].ZPos,Master.ReplicationList[Count].VYaw,Master.ReplicationList[Count].VPitch,Master.ReplicationList[Count].VRoll,Master.ReplicationList[Count].ThisActorNetcode);
		else ClientDLBrick(Master.ReplicationList[Count].Brick,Count,Master.ReplicationList[Count].XPos,Master.ReplicationList[Count].YPos,Master.ReplicationList[Count].ZPos,Master.ReplicationList[Count].VYaw,Master.ReplicationList[Count].VPitch,Master.ReplicationList[Count].VRoll,Master.ReplicationList[Count].ThisActorNetcode,Master.ReplicationList[Count].D3DSize[0],Master.ReplicationList[Count].D3DSize[1],Master.ReplicationList[Count].D3DSize[2]);
		Sleep(0.02);
	}
	if( Master!=None )
		Master.SendFor[SlotNum].bInReplication = False;
	SetTimer(4,True);
	GoToState('');
}
Auto state SecondObjective
{
Begin:
	Sleep(5);
	Timer();
	Master.ScanForOwner(PlayerController(Owner),Self);
	SetTimer(4,True);
	GoToState('');
}
function Timer()
{
	if( Owner==None )
		Destroy();
}
function Destroyed()
{
	Master.RemoveReplicationClient(Self);
	Master = None;
}
simulated function string GetDLingMessageStr()
{
	if( NumDLEdNow>=NumBricksDownloading )
		Return "Finished downloading!";
	Return "Downloading bricks..."@int((float(NumDLEdNow)/float(NumBricksDownloading))*100.f)@"% ("$NumDLEdNow$"/"$NumBricksDownloading$")";
}
simulated function string GetDLingMessageStrFM()
{
	if( NumDLEdNow>=NumMeshDLs )
		Return "Finished downloading meshes!";
	Return "Downloading meshes..."@int((float(NumMeshesNow)/float(NumMeshDLs))*100.f)@"% ("$NumMeshesNow$"/"$NumMeshDLs$")";
}

defaultproperties
{
     RemoteRole=ROLE_SimulatedProxy
}
