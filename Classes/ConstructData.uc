Class ConstructData extends Object
	Config(ConstructedData)
	PerObjectConfig;

var() config string AreaOwnerID,AreaOwnedName,AreaOwnerIP;
struct PlacedBricks
{
	var() config byte SX,SY,SZ,MID;
	var() config int PX,PY,PZ,RYaw,RPitch;
};
var() config array<PlacedBricks> Brick;
struct CoOwnersType
{
	var() config string OwnerID,OwnerName;
};
var() config array<CoOwnersType> CoOwner;
var array<NetStaticMesh> ActiveMesh;
var bool bDataChanged;
var PrivateBuildZone TheZoneOwner;

Static function ConstructData LoadVolumeData( PrivateBuildZone Other )
{
	local ConstructData CD;
	local string S;

	S = string(Other);
	S = Left(S,InStr(S,"."))$"_"$string(Other.Name);
	CD = ConstructData(FindObject("Package."$S, Default.Class));
	if( CD==None )
		CD = new(None, S) Default.Class;
	CD.TheZoneOwner = Other;
	Return CD;
}
function SaveBrickData( int XPos, int YPos, int ZPos, int Yaw, int Pitch, byte MeshID, byte SizeX, byte SizeY, byte SizeZ, NetStaticMesh TheSavedOne )
{
	local int i;

	i = Brick.Length;
	Brick.Length = (i+1);
	ActiveMesh.Length = (i+1);
	Brick[i].SX = SizeX;
	Brick[i].SY = SizeY;
	Brick[i].SZ = SizeZ;
	Brick[i].MID = MeshID;
	Brick[i].PX = XPos;
	Brick[i].PY = YPos;
	Brick[i].PZ = ZPos;
	Brick[i].RYaw = Yaw;
	Brick[i].RPitch = Pitch;
	ActiveMesh[i] = TheSavedOne; // Temp data, never saved.
	bDataChanged = True;
}
function DeleteBrickData( NetStaticMesh Other )
{
	local int i,j;

	j = Brick.Length;
	For( i=0; i<j; i++ )
	{
		if( ActiveMesh[i]!=None && ActiveMesh[i]==Other )
		{
			j--;
			Brick.Remove(i,1);
			ActiveMesh.Remove(i,1);
			Break;
		}
	}
	bDataChanged = True;
}
function LoadUpData( LevelInfo Other ) // Loadup everything!
{
	local int i,j;
	local vector V;
	local rotator R;

	j = Brick.Length;
	For( i=0; i<j; i++ )
	{
		V.X = Brick[i].PX;
		V.Y = Brick[i].PY;
		V.Z = Brick[i].PZ;
		V = Class'ConstructorInv'.Static.GetBigVector(V);
		R.Yaw = Brick[i].RYaw;
		R.Pitch = Brick[i].RPitch;
		R = Class'ConstructorInv'.Static.DecompressRotation(R);
		ActiveMesh[i] = Other.Spawn(Class'NetStaticMesh',,,V,R);
		V.X = float(Brick[i].SX)/5;
		V.Y = float(Brick[i].SY)/5;
		V.Z = float(Brick[i].SZ)/5;
		ActiveMesh[i].SetDrawScale3D(V);
		ActiveMesh[i].SetStaticMesh(Class'ConstructorInv'.Static.IntToMesh(Brick[i].MID));
		if( Other.NetMode!=NM_DedicatedServer )
		{
			ActiveMesh[i].AddAntiPortal(Brick[i].MID);
			ActiveMesh[i].VisualFX = Class'ConstructorInv'.Static.GetFXEmitter(ActiveMesh[i],Brick[i].MID,ActiveMesh[i].DrawScale3D.X);
		}
		if( ActiveMesh[i].StaticMesh==None )
		{
			ActiveMesh[i].bUseCylinderCollision = True;
			ActiveMesh[i].SetCollision(True,False,False);
			ActiveMesh[i].bBlockNonZeroExtentTraces = False;
			ActiveMesh[i].KSetBlockKarma(False);
			ActiveMesh[i].SetCollisionSize(20*ActiveMesh[i].DrawScale3D.X,25*ActiveMesh[i].DrawScale3D.X);
		}
		ActiveMesh[i].UpdateNetClients(Brick[i].MID);
		ActiveMesh[i].MyPalace = Self;
	}
}
function ClearEverything()
{
	local int i,j;

	j = ActiveMesh.Length;
	For( i=0; i<j; i++ )
	{
		if( ActiveMesh[i]!=None )
			ActiveMesh[i].Destroy();
	}
	Brick.Length = 0;
	ActiveMesh.Length = 0;
	AreaOwnerID = "";
	AreaOwnedName = "";
	AreaOwnerIP = "";
	CoOwner.Length = 0;
	if( TheZoneOwner!=None )
		TheZoneOwner.ZoneOwner.Length = 0;
	bDataChanged = True;
}
function bool PlayerIsAnOwner( string PLId, string PLName, string PLIP )
{
	local int i;

	if( AreaOwnerID~=PLId )
	{
		if( AreaOwnedName!=PLName || AreaOwnerIP!=PLIP )
		{
			AreaOwnedName = PLName;
			AreaOwnerIP = PLIP;
			bDataChanged = True;
		}
		Return True;
	}
	For( i=0; i<CoOwner.Length; i++ )
	{
		if( CoOwner[i].OwnerID~=PLId )
		{
			if( CoOwner[i].OwnerName!=PLName )
			{
				CoOwner[i].OwnerName = PLName;
				bDataChanged = True;
			}
			Return True;
		}
	}
	Return False;
}
function AddCoOwner( string PLID, string PLName )
{
	local int i;

	i = CoOwner.Length;
	CoOwner.Length = i+1;
	CoOwner[i].OwnerName = PLName;
	CoOwner[i].OwnerID = PLID;
	bDataChanged = True;
}

defaultproperties
{
}
