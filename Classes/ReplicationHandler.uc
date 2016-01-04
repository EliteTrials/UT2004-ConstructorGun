//=============================================================================
// ReplicationHandler.						Coded by .:..:
//=============================================================================
class ReplicationHandler extends Mutator
	Config(ConstructedData)
	PerObjectConfig;

var array<NetStaticMesh> ReplicationList;
struct ReplicationData
{
	var ClientReplic ClientR;
	var PlayerController RealClient;
	var bool bInReplication;
};
var array<ReplicationData> SendFor;
var array<PrivateBuildZone> TheZones;
var() globalconfig float AutoSaveMinutes;
struct sMeshConfigType
{
	var() globalconfig string ConvexMeshName,StaticMeshName,EmitterClassName;
	var() globalconfig string BuildSound;
};
var() globalconfig array<sMeshConfigType> MeshNames;
struct LoadedMeshesType
{
	var ConvexVolume Convex;
	var StaticMesh StaticM;
	var class<Actor> EffectClass;
	var sound BuildSound;
};
var array<LoadedMeshesType> LoadedMeshes;

function PostBeginPlay()
{
	local Controller C;

	InitilizeMeshTypes();
	For( C=Level.ControllerList; C!=None; C=C.NextController )
	{
		if( C.IsA('PlayerController') && !C.IsA('UTServerAdminSpectator') )
			AddReplicationFor(PlayerController(C),True);
	}
	SetTimer(AutoSaveMinutes*60,True);
}
function AddToReplicationList( NetStaticMesh SMesh )
{
	local int i,j;

	i = ReplicationList.Length;
	ReplicationList.Length = i+1;
	ReplicationList[i] = SMesh;
	j = SendFor.Length;
	For( i=0; i<j; i++ )
	{
		if( SendFor[i].RealClient!=None && !SendFor[i].bInReplication )
		{
			if( SMesh.DrawScale3D==vect(1,1,1) )
				SendFor[i].ClientR.ClientAddBrick(SMesh.Brick,SMesh.XPos,SMesh.YPos,SMesh.ZPos,SMesh.VYaw,SMesh.VPitch,SMesh.VRoll,SMesh.ThisActorNetcode);
			else SendFor[i].ClientR.ClientAddBrick(SMesh.Brick,SMesh.XPos,SMesh.YPos,SMesh.ZPos,SMesh.VYaw,SMesh.VPitch,SMesh.VRoll,SMesh.ThisActorNetcode,SMesh.D3DSize[0],SMesh.D3DSize[1],SMesh.D3DSize[2]);
		}
	}
}
function AddToNotifyList( PrivateBuildZone Other )
{
	local int i;

	i = TheZones.Length;
	TheZones.Length = (i+1);
	TheZones[i] = Other;
}
function KillReplication( NetStaticMesh SMesh )
{
	local int i,j,d;

	j = SendFor.Length;
	For( i=0; i<j; i++ )
	{
		if( SendFor[i].RealClient!=None )
			SendFor[i].ClientR.ClientRemoveBrick(SMesh.ThisActorNetcode);
	}
	j = ReplicationList.Length;
	For( i=0; i<j; i++ )
	{
		if( ReplicationList[i]==SMesh )
		{
			For( d=0; d<SendFor.Length; d++ )
				if( SendFor[d].RealClient!=None )
					SendFor[d].ClientR.NotifyBrickDeleted(i);
			ReplicationList.Remove(i,1);
			Return;
		}
	}
}
function int AddReplicationClient( PlayerController PC, ClientReplic CR )
{
	local int i;

	i = SendFor.Length;
	SendFor.Length = i+1;
	SendFor[i].RealClient = PC;
	SendFor[i].ClientR = CR;
	Return i;
}
function RemoveReplicationClient( ClientReplic CR )
{
	local int i,j;

	j = SendFor.Length;
	For( i=0; i<j; i++ )
	{
		if( SendFor[i].ClientR==CR )
		{
			j--;
			SendFor.Remove(i,1);
			Break;
		}
	}
	j = SendFor.Length;
	For( i=0; i<j; i++ )
	{
		if( SendFor[i].ClientR!=None )
			SendFor[i].ClientR.SlotNum = i;
	}
}
function bool CheckReplacement(Actor Other, out byte bSuperRelevant)
{
	if( Other.IsA('PlayerController') && !Other.IsA('UTServerAdminSpectator') )
		AddReplicationFor(PlayerController(Other),True);
	return true;
}
function AddReplicationFor( PlayerController PC, bool bLogin )
{
	local ClientReplic C;

	C = Spawn(class'ClientReplic',PC);
	C.Master = Self;
	C.SlotNum = AddReplicationClient(PC,C);
	if( bLogin )
		C.SendAllToClient();
	else C.SetTimer(5,True);
}
function ScanForOwner( PlayerController PC, ClientReplic Rep )
{
	local string ID,IP;
	local int i,j;

	j = TheZones.Length;
	if( j!=0 )
	{
		ID = PC.GetPlayerIDHash();
		IP = PC.GetPlayerNetworkAddress();
	}
	For( i=0; i<j; i++ )
	{
		if( TheZones[i].DataPool!=None && TheZones[i].DataPool.AreaOwnerID!="" && TheZones[i].DataPool.PlayerIsAnOwner(ID,PC.PlayerReplicationInfo.PlayerName,IP) )
		{
			if( TheZones[i].DataPool.AreaOwnerID~=ID )
				TheZones[i].PRIOwner = PC.PlayerReplicationInfo;
			TheZones[i].AddAnOwner(PC);
			TheZones[i].PostNetReceive();
			if( Rep!=None )
				Rep.VisualizeArea(TheZones[i]);
		}
	}
}
function Timer()
{
	local int i,j;

	j = TheZones.Length;
	For( i=0; i<j; i++ )
	{
		if( TheZones[i]!=None && TheZones[i].DataPool!=None && TheZones[i].DataPool.bDataChanged )
		{
			TheZones[i].DataPool.SaveConfig();
			TheZones[i].DataPool.bDataChanged = False;
		}
	}
}
function InitilizeMeshTypes()
{
	local int i,j;
	local StaticMesh SMA;
	local ConvexVolume CA;
	local class<Actor> AC;
	local sound BS;

	Log("Initilizing meshes",'Constructor');
	For( i=0; i<MeshNames.Length; i++ )
	{
		SMA = None;
		if( MeshNames[i].StaticMeshName!="" )
			SMA = StaticMesh(DynamicLoadObject(MeshNames[i].StaticMeshName,Class'StaticMesh',True));
		CA = None;
		if( SMA!=None && MeshNames[i].ConvexMeshName!="" )
			CA = ConvexVolume(DynamicLoadObject(MeshNames[i].StaticMeshName,Class'ConvexVolume',True));
		AC = None;
		if( SMA==None && MeshNames[i].EmitterClassName!="" )
			AC = Class<Actor>(DynamicLoadObject(MeshNames[i].EmitterClassName,Class'Class',True));
		if( BS==None && MeshNames[i].BuildSound!="" )
			BS = Sound(DynamicLoadObject(MeshNames[i].BuildSound,Class'Class',True));
		if( SMA!=None || AC!=None )
		{
			LoadedMeshes.Length = j+1;
			LoadedMeshes[j].Convex = CA;
			LoadedMeshes[j].StaticM = SMA;
			LoadedMeshes[j].EffectClass = AC;
			LoadedMeshes[j].BuildSound = BS;
			Class'ConstructorInv'.Static.AddFXMeshType(XLevel,SMA,CA,AC);
			j++;
		}
	}
	Log("Initilizing finished, got"@j@"mesh types",'Constructor');
}

DefaultProperties
{
	AutoSaveMinutes=2.000000
	MeshNames(0)=(StaticMeshName="Constructor.Floor")
	MeshNames(1)=(StaticMeshName="Constructor.Wall")
	MeshNames(2)=(StaticMeshName="Constructor.Stair")
	MeshNames(3)=(StaticMeshName="Constructor.Block")
	MeshNames(4)=(StaticMeshName="Constructor.Pillar")
	MeshNames(5)=(StaticMeshName="Constructor.DoubleGlass")
}
