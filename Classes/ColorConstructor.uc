//==============================================================================
// Coded by Eliot.
//==============================================================================
Class ColorConstructor Extends ConstructorInvZ;

var ColorModifier ColorMat;
var color CurrentColor;

Simulated Function PostNetBeginPlay()
{
	Super.PostNetBeginPlay();
	ColorMat = ColorModifier(Level.ObjectPool.AllocateObject( Class'ColorModifier' ));
}

Simulated Exec Function SetBrickColor( optional color NewColor )
{
	local int i;

	if( ColorMat != None && MeshActor != None )
	{
		if( MeshActor.Skins.Length == 0 )
			MeshActor.Skins.Length = 1;

		ColorMat.Color = NewColor;
		ColorMat.AlphaBlend = (NewColor.A < 255);
		ColorMat.RenderTwoSided = ColorMat.AlphaBlend;
		for( i = 0; i < MeshActor.Skins.Length; i ++ )
		{
			if( MeshActor.Skins[i] == None )
			{
				ColorMat.Material = MeshActor.Texture;
				MeshActor.Texture = ColorMat;
			}
			else
			{
				ColorMat.Material = MeshActor.Skins[i];
				MeshActor.Skins[i] = ColorMat;
			}
		}
		CurrentColor = NewColor;
	}
}

function ServerPlaceBrick( int BrickNum, int XPos, int YPos, int ZPos, int VYaw, int VPitch, int VRoll, CompressedDS Scale )
{
	local MiniVector M;
	local rotator R;
	local vector SP,D3DScale;
	local NetStaticMesh MyMesh;
	local PhysicsVolume P;
	local int i;

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
	if( ColorMat != None )
	{
		if( MyMesh.Skins.Length == 0 )
			MyMesh.Skins.Length = 1;
		for( i = 0; i < MyMesh.Skins.Length; i ++ )
		{
			if( MyMesh.Skins[i] == None )
			{
				ColorMat.Material = MyMesh.Texture;
				MyMesh.Texture = ColorMat;
			}
			else
			{
				ColorMat.Material = MyMesh.Skins[i];
				MyMesh.Skins[i] = ColorMat;
			}
		}
	}
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

DefaultProperties
{
	InventoryGroup=7
	ItemName="Color Constructor Zoned!"
}
