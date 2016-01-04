//=============================================================================
// Constructor Weapon
// Coded by .:..:/Eliot
//=============================================================================
class ConstructorInv extends Weapon
	Config(User);

#exec obj load file="ConstDefaultMeshes.usx" Package="Constructor"
#exec obj load file="..\StaticMeshes\X_AW-MechMeshes.usx"
#exec obj load file="..\StaticMeshes\X_cp_Evil.usx"
#exec obj load file="..\StaticMeshes\skyline-meshes-epic.usx"
#exec obj load file="..\StaticMeshes\Pipe_Static.usx"
#exec obj load file="..\StaticMeshes\ArboreaHardware.usx"
#exec obj load file="..\StaticMeshes\Albatross_architecture.usx"
#exec obj load file="..\System\ConstConvexMeshes.u"
#exec obj load file="..\StaticMeshes\BarrenHardware.usx"
#exec obj load file="..\StaticMeshes\BarrenHardware-epic.usx"
#exec obj load file="..\StaticMeshes\Egypt_techmeshes_Epic.usx"
#exec obj load file="UT2003Fonts.utx"

var bool bMeshSelection,bClientFire,bClientAltFire;
var byte CurrentMode;
struct BuildingType
{
	var() StaticMesh StaticM;
	var() ConvexVolume Convex;
	var() class<Actor> EmitterType;
	var() sound BuildSound;
};
var() array<BuildingType> MeshesType;
var Texture ImportedData;
var int CurrentMesh;
struct MiniVector
{
	var int X,Y,Z;
};
struct CompressedDS
{
	var byte X,Y,Z;
};
Const RotCompressKey=2048;
var() globalconfig bool bDontMouseScroll;
var() globalconfig float DistanceFromPlayer;
var RenderActor MeshActor;
var MiniVector PlaceLocation;
var rotator PlaceRot,PLInitRot,CompressedRot;
var vector ChosenScale,OrginalPositions,ChangingPos;
var Level LoadedOnMap;
var bool bWasWalking;
// be build later...
/*var() globalconfig enum EBuildSet
{
	BS_Mesh,
	BS_Emitter,
	BS_Light,
	BS_Sound,
} BuildSet;*/
var vector OldLocation;
var() globalconfig float GridSize;

replication
{
	// functions called by client on server
	reliable if( Role<ROLE_Authority )
		ServerPlaceBrick;
	reliable if( Role==ROLE_Authority )
		ToggleMeshS,SetDist, SetGridSize;
}

simulated function PostNetBeginPlay()
{
	if( Level.NetMode!=NM_DedicatedServer )
	{
		MeshActor = Spawn(class'RenderActor',Self);
		MeshActor.bUnlit = True;
	}
	Super.PostNetBeginPlay();
}
simulated function Destroyed()
{
	if( MeshActor!=None )
		MeshActor.Destroy();
}
simulated function bool HasAmmo()
{
	return True; // Unlimited ammo.
}
simulated exec function ToggleMeshS()
{
	bDontMouseScroll = !bDontMouseScroll;
	if( bDontMouseScroll )
		Instigator.ClientMessage("Alt fire does now switch directly between meshes");
	else Instigator.ClientMessage("Alt fire does now switch indirectly meshes");
	SaveConfig();
}
simulated exec function ResetAlign()
{
	ChosenScale = Default.ChosenScale;
	PlaceRot = Default.PlaceRot;
	MeshActor.SetRotation(rot(0,0,0));
	Instigator.ClientMessage("Mesh scaling/rotation has been reset to default now.");
}
simulated exec function SetSize( vector V )
{
	if( V.X==0 )
		V.X = ChosenScale.X;
	if( V.Y==0 )
		V.Y = ChosenScale.Y;
	if( V.Z==0 )
		V.Z = ChosenScale.Z;
	ChosenScale = DecompressVect(CompressVect(V)); // Normalize the vector for display.
	Instigator.ClientMessage("You have chosen mesh scale to:"@ChosenScale);
}
simulated exec function SetDist( float D )
{
	DistanceFromPlayer = D;
	SaveConfig();
}

Simulated Exec Function SetGridSize( float Grid )
{
	GridSize = Grid;
	Default.GridSize = Grid;
	SaveConfig();
}

Simulated Function RenderSelectedMesh( Canvas C )
{
/*	local int i, j;
	local array<NetStaticMesh> RMA;
	local int PosY;

    C.Font = Font'Engine.DefaultFont';
    C.DrawColor = C.Default.DrawColor;
	C.SetPos( C.ClipX-4, 0 );
	C.DrawTile( Texture'InterfaceContent.Menu.BorderBoxD', 2, C.ClipY, 0, 0, 64, 2 );
	C.DrawTile( Material'HudContent.Generic.HUD', C.ClipX-5, C.ClipY, 79, 223, 37, 41 );
	PosY = 16;
	for( i = 0; i < 10; i ++ )
	{
		C.SetPos( C.ClipX-8, PosY );
		RMA[j].SetStaticMesh( IntToMesh( i ) );
		RMA[j].SetDrawScale( 0.25 );
		if( j == MeshToInt( RMA[j].StaticMesh ) )
		{
			SelectedMeshMat.Material = RMA[j].Skins[0];
			SelectedMeshMat.Color.R = 0;
			SelectedMeshMat.Color.G = 0;
			RMA[j].Skins[0] = SelectedMeshMat;
		}
		C.DrawActor( RMA[j], False );
		PosY += 32;
		j ++;
	}
	C.SetPos( C.ClipX-68, 0 );
	C.DrawTile( Texture'InterfaceContent.Menu.BorderBoxD', 2, C.ClipY, 0, 0, 64, 2 );*/
}

Simulated Function WeaponTick( float dt )
{
	Super.WeaponTick(dt);
	// Avoid player from moving.
	if( Instigator != None )
	{
		if( CurrentMode == 1 )
		{
			if( !Instigator.bIsWalking && !Instigator.bIsCrouched && Instigator.Location != OldLocation )
			{
				Instigator.SetLocation( OldLocation );
				Instigator.Velocity = Instigator.Default.Velocity;
			}
			else if( Instigator.bIsWalking || Instigator.bIsCrouched )
				OldLocation = Instigator.Location;
		}
	}
}

simulated event RenderOverlays( Canvas Canvas )
{
	local MiniVector OldPos;
	local rotator RCh;

	if( MeshActor == None )return;
	//RenderSelectedMesh( Canvas );
	Canvas.SetDrawColor(255,255,255);
	Canvas.DrawColor.A = 255;
	// Draw Mesh info.
	Canvas.SetPos( Canvas.ClipX - Canvas.ClipX/1.5, Canvas.ClipY - 128 );
	Canvas.Font = Font'UT2003Fonts.jFontSmallText800x600';
	Canvas.DrawText( "Brick:"@MeshActor.StaticMesh@"Num:"@CurrentMesh );
	Canvas.SetPos( Canvas.ClipX - Canvas.ClipX/1.5, Canvas.ClipY - 112 );
	Canvas.DrawText( "Location:"@MeshActor.Location@"Rotation:"@MeshActor.Rotation );
	Canvas.SetPos( Canvas.ClipX - Canvas.ClipX/1.25, Canvas.ClipY - 82 );
	if( CurrentMode==0 )
	{
		if( bMeshSelection )
			Canvas.DrawText("Tip: Use NextWeapon/PrevWeapon to scroll between meshes");
		else Canvas.DrawText("Tip: Hit [Fire] to control mesh location, [AltFire] to select mesh.");
	}
	else if( CurrentMode==1 )
		Canvas.DrawText("Tip: Use mouse to rotate around the mesh. Hit [Fire] to place this brick, [AltFire] to cancel this brick, [Crouch] to rotate the Roll component, [Walk] to move it around or turn around without affecting the rotation.");
	if( Instigator!=None && Instigator.Controller!=None  )
	{
		if( CurrentMode==0 )
		{
			OldPos = PlaceLocation;
			PlaceLocation = BigToMini(Instigator.Location+vector(Instigator.Controller.Rotation)*DistanceFromPlayer);
			if( OldPos!=PlaceLocation )
			{
				MeshActor.SetLocation(MiniToBig(PlaceLocation));
				ChangingPos = MeshActor.Location;
			}
		}
		else if( CurrentMode==1 )
		{
			if( bWasWalking!=Instigator.bIsWalking )
			{
				OrginalPositions = Instigator.Location;
				bWasWalking = Instigator.bIsWalking;
			}
			if( !bWasWalking && Instigator.Controller.Rotation!=PLInitRot )
			{
				RCh = (Instigator.Controller.Rotation-PLInitRot);
				PlaceRot.Yaw+=RCh.Yaw;
				if( Instigator.bIsCrouched )
					PlaceRot.Roll+=RCh.Pitch;
				else PlaceRot.Pitch+=RCh.Pitch;
				PlaceRot.Yaw = PlaceRot.Yaw & 65535;
				PlaceRot.Pitch = PlaceRot.Pitch & 65535;
				PlaceRot.Roll = PlaceRot.Roll & 65535;
				CompressedRot = DecompressRotation(CompressRotation(PlaceRot));
				MeshActor.SetRotation(CompressedRot);
				Instigator.Controller.SetRotation(PLInitRot);
			}
			if( bWasWalking && OrginalPositions!=Instigator.Location )
			{
				PLInitRot = Instigator.Controller.Rotation;
				ChangingPos+=(Instigator.Location-OrginalPositions);
				OrginalPositions = Instigator.Location;
				OldPos = PlaceLocation;
				PlaceLocation = BigToMini(ChangingPos);
				if( OldPos!=PlaceLocation )
					MeshActor.SetLocation(MiniToBig(PlaceLocation));
			}
		}
		if( CurrentMesh<Class'ConstructorInv'.Static.GetMeshListMaxLen() )
		{
			if( MeshActor.StaticMesh!=Class'ConstructorInv'.Default.MeshesType[CurrentMesh].StaticM )
				MeshActor.SetStaticMesh(Class'ConstructorInv'.Default.MeshesType[CurrentMesh].StaticM);
		}
		else if( MeshActor.StaticMesh!=None )
			MeshActor.SetStaticMesh(None);
		if( MeshActor.DrawScale3D!=ChosenScale )
		{
			MeshActor.SetDrawScale3D(ChosenScale);
			if( MeshActor.DeEmitter!=None )
				UpdateFXEmitter(MeshActor,MeshActor.DeEmitter,CurrentMesh,ChosenScale.X);
		}
		if( MeshActor.DeEmitter!=None && MeshActor.DeEmitter.Location!=MeshActor.Location )
			MeshActor.DeEmitter.SetLocation(MeshActor.Location);
		if( MeshActor.bHidden )
		{
			MeshActor.bHidden = False;
			PutNextMesh(0);
		}
		MeshActor.SetTimer(0.5,False);
	}
	super.RenderOverlays( Canvas );
}
// Mini vector follows 32 units grid.
simulated function MiniVector BigToMini( vector V )
{
	local MiniVector V2;

	V2.X = V.X/GridSize;
	V2.Y = V.Y/GridSize;
	V2.Z = V.Z/GridSize;
	Return V2;
}
simulated function vector MiniToBig( MiniVector V )
{
	local vector V2;

	V2.X = V.X*GridSize;
	V2.Y = V.Y*GridSize;
	V2.Z = V.Z*GridSize;
	Return V2;
}
// Compress vector for DrawScale 3D
simulated function CompressedDS CompressVect( vector V )
{
	local CompressedDS V2;

	V2.X = V.X*5;
	V2.Y = V.Y*5;
	V2.Z = V.Z*5;
	Return V2;
}
simulated function vector DecompressVect( CompressedDS V )
{
	local vector V2;

	V2.X = float(V.X)/5;
	V2.Y = float(V.Y)/5;
	V2.Z = float(V.Z)/5;
	Return V2;
}
// Normalize rotation (compress)
static simulated function rotator CompressRotation( rotator R )
{
	R.Yaw/=RotCompressKey;
	R.Pitch/=RotCompressKey;
	R.Roll/=RotCompressKey;
	Return R;
}
static simulated function rotator DecompressRotation( rotator R )
{
	R.Yaw*=RotCompressKey;
	R.Pitch*=RotCompressKey;
	R.Roll*=RotCompressKey;
	Return R;
}
// Alternative compression
static function vector GetMiniVector( vector V )
{
	local int i;
	i = V.X/Default.GridSize;
	V.X = i;
	i = V.Y/Default.GridSize;
	V.Y = i;
	i = V.Z/Default.GridSize;
	V.Z = i;
	Return V;
}
static function vector GetBigVector( vector V )
{
	V.X*=Default.GridSize;
	V.Y*=Default.GridSize;
	V.Z*=Default.GridSize;
	Return V;
}
static function int MeshToInt( StaticMesh SM )
{
	local int i,j;

	j = Default.MeshesType.Length;
	For( i=0; i<j; i++ )
	{
		if( Default.MeshesType[i].StaticM==SM )
			Return i;
	}
	Return 0;
}
static function StaticMesh IntToMesh( int i )
{
	if( i>=Default.MeshesType.Length )
		Return None;
	Return Default.MeshesType[i].StaticM;
}
static function Sound IntToSound( int i )
{
	if( i>=Default.MeshesType.Length )
		Return None;
	Return Default.MeshesType[i].BuildSound;
}
static function Actor GetFXEmitter( Actor Generator, int i, float ParticlesSize )
{
	local Actor NE;
	local Emitter E;

	if( i>=Default.MeshesType.Length || Default.MeshesType[i].EmitterType==None )
		Return None;
	NE = Generator.Spawn(Default.MeshesType[i].EmitterType);
	if( NE==None )
		Return None;
	E = Emitter(NE);
	if( E!=None )
	{
		For( i=0; i<E.Emitters.Length; i++ )
		{
			E.Emitters[i].StartSizeRange.X.Min*=ParticlesSize;
			E.Emitters[i].StartSizeRange.X.Max*=ParticlesSize;
			E.Emitters[i].StartSizeRange.Y.Min*=ParticlesSize;
			E.Emitters[i].StartSizeRange.Y.Max*=ParticlesSize;
			E.Emitters[i].StartSizeRange.Z.Min*=ParticlesSize;
			E.Emitters[i].StartSizeRange.Z.Max*=ParticlesSize;
		}
	}
	else NE.SetDrawScale(ParticlesSize);
	NE.RemoteRole = ROLE_None;
	Return NE;
}
static function int GetMeshListMaxLen()
{
	Return Default.MeshesType.Length;
}
static function bool UpdateFXEmitter( Actor Spawner, out Actor NE, int i, float ParticlesSize )
{
	local Actor A;
	local Emitter E;

	if( i>=Default.MeshesType.Length || Default.MeshesType[i].EmitterType==None )
		Return False;
	if( NE==None || NE.Class!=Default.MeshesType[i].EmitterType )
	{
		A = NE;
		NE = GetFXEmitter(Spawner,i,ParticlesSize);
		if( A!=None )
			A.Destroy();
		Return True;
	}
	E = Emitter(NE);
	if( E!=None )
	{
		For( i=0; i<E.Emitters.Length; i++ )
		{
			E.Emitters[i].StartSizeRange.X.Min*=ParticlesSize;
			E.Emitters[i].StartSizeRange.X.Max*=ParticlesSize;
			E.Emitters[i].StartSizeRange.Y.Min*=ParticlesSize;
			E.Emitters[i].StartSizeRange.Y.Max*=ParticlesSize;
			E.Emitters[i].StartSizeRange.Z.Min*=ParticlesSize;
			E.Emitters[i].StartSizeRange.Z.Max*=ParticlesSize;
		}
	}
	Return True;
}
static function ConvexVolume IntToAntiPortal( int i )
{
	if( i>=Default.MeshesType.Length )
		Return None;
	Return Default.MeshesType[i].Convex;
}
simulated function vector GetEffectStart()
{
	local Vector X,Y,Z, Offset;
	local float Extra;

	// 1st person
	if ( Instigator.IsFirstPerson() )
	{
		if ( WeaponCentered() )
			return CenteredEffectStart();

		GetViewAxes(X, Y, Z);
		if ( class'PlayerController'.Default.bSmallWeapons )
			Offset = SmallEffectOffset;
		else
			Offset = EffectOffset;

		if ( Hand == 0 )
		{
			if ( bUseOldWeaponMesh )
				Offset.Z -= 10;
			else
				Offset.Z -= 14;
			Extra = 3;
		}
		else if ( !bUseOldWeaponMesh )
			Offset.Z -= 10;

		return (Instigator.Location + Instigator.CalcDrawOffset(self) + Offset.X * X  + (Offset.Y * Hand + Extra) * Y + Offset.Z * Z);
    }
    else
    {
        return (Instigator.Location +
            Instigator.EyeHeight*Vect(0,0,0.5) +
            Vector(Instigator.Rotation) * 40.0);
    }
}
function bool ConsumeAmmo(int Mode, float load, optional bool bAmountNeededIsMax)
{
	return true;
}
// --- jdf
simulated event ClientStartFire(int Mode)
{
	local MiniVector M;
	local rotator MR;

	if( Mode==0 )
		bClientFire = True;
	else bClientAltFire = True;
	if( Mode==1 )
	{
		if( CurrentMode==0 )
		{
			if( bDontMouseScroll )
			{
				Instigator.PlaySound(Sound'msfxUp');
				PutNextMesh(1);
			}
			else bMeshSelection = True;
		}
		else if( CurrentMode==1 )
			CurrentMode = 0;
	}
	else
	{
		if( CurrentMode==0 )
		{
			bWasWalking = False;
			CurrentMode++;
			bMeshSelection = False;
			PLInitRot = Instigator.Controller.Rotation;
			OldLocation = Instigator.Location;
		}
		else if( CurrentMode==1 )
		{
			M = PlaceLocation;
			MR = CompressRotation(PlaceRot);
			ServerPlaceBrick(CurrentMesh,M.X,M.Y,M.Z,MR.Yaw,MR.Pitch,MR.Roll,CompressVect(ChosenScale));
			CurrentMode = 0;
		}
	}
}
function ServerPlaceBrick( int BrickNum, int XPos, int YPos, int ZPos, int VYaw, int VPitch, int VRoll, CompressedDS Scale )
{
	local MiniVector M;
	local rotator R;
	local vector SP,D3DScale;
	local NetStaticMesh MyMesh;

	M.X = XPos;
	M.Y = YPos;
	M.Z = ZPos;
	R.Yaw = VYaw;
	R.Pitch = VPitch;
	R.Roll = VRoll;
	SP = MiniToBig(M);
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
	{
		MyMesh.AddAntiPortal(BrickNum);
		if( Instigator != None )
			Instigator.PlayOwnedSound( IntToSound( BrickNum ),, 255 );
	}
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
}
simulated function bool StartFire(int Mode)
{
	Return True;
}
simulated event ClientStopFire(int Mode)
{
	if( Mode==0 )
		bClientFire = False;
	else bClientAltFire = False;
	if( Mode==1 )
		bMeshSelection = False;
}
simulated function Weapon NextWeapon(Weapon CurrentChoice, Weapon CurrentWeapon)
{
	if( bMeshSelection )
	{
		Instigator.PlaySound(Sound'msfxUp');
		PutNextMesh(1);
		Return None;
	}
	else if( Pawn(Owner).Weapon==Self ) DistanceFromPlayer+=100;
	else Return Super.NextWeapon(CurrentChoice,CurrentWeapon);
}
simulated function Weapon PrevWeapon(Weapon CurrentChoice, Weapon CurrentWeapon)
{
	if( bMeshSelection )
	{
		Instigator.PlaySound(Sound'msfxDown');
		PutNextMesh(-1);
		Return None;
	}
	else if( Pawn(Owner).Weapon==Self ) DistanceFromPlayer-=100;
	else Return Super.PrevWeapon(CurrentChoice,CurrentWeapon);
}
simulated function PutNextMesh( int Adding )
{
	CurrentMesh+=Adding;
	if( Adding<0 && CurrentMesh<0 )
		CurrentMesh = Class'ConstructorInv'.Static.GetMeshListMaxLen()-1;
	else if( Adding>0 && CurrentMesh>=Class'ConstructorInv'.Static.GetMeshListMaxLen() )
		CurrentMesh = 0;
	if( MeshActor!=None )
	{
		if( !Class'ConstructorInv'.Static.UpdateFXEmitter(MeshActor,MeshActor.DeEmitter,CurrentMesh,MeshActor.DrawScale3D.X) && MeshActor.DeEmitter!=None )
			MeshActor.DeEmitter.Destroy();
	}
}
event ServerStartFire(byte Mode)
{
	if( Instigator.IsLocallyControlled() )
		ClientStartFire(Mode);
}
simulated function Fire(float F)
{
	if( Level.NetMode==NM_Client || Instigator.IsLocallyControlled() )
		ClientStartFire(0);
}
simulated function AltFire(float F)
{
	if( Level.NetMode==NM_Client || Instigator.IsLocallyControlled() )
		ClientStartFire(1);
}
simulated function ClientWeaponSet(bool bPossiblySwitch)
{
	Instigator = Pawn(Owner);

	bPendingSwitch = bPossiblySwitch;

	if( Instigator == None )
	{
		GotoState('PendingClientWeaponSet');
		return;
	}

	ClientState = WS_Hidden;
	GotoState('Hidden');

	if( Level.NetMode == NM_DedicatedServer || !Instigator.IsHumanControlled() )
		return;

	if( Instigator.Weapon == self || Instigator.PendingWeapon == self ) // this weapon was switched to while waiting for replication, switch to it now
	{
		if (Instigator.PendingWeapon != None)
			Instigator.ChangedWeapon();
		else
			BringUp();
		return;
	}

	if( Instigator.PendingWeapon != None && Instigator.PendingWeapon.bForceSwitch )
		return;

	if( Instigator.Weapon == None )
	{
		Instigator.PendingWeapon = self;
		Instigator.ChangedWeapon();
	}
	else if ( bPossiblySwitch && !Instigator.Weapon.IsFiring() )
	{
		if ( PlayerController(Instigator.Controller) != None && PlayerController(Instigator.Controller).bNeverSwitchOnPickup )
			return;
		if ( Instigator.PendingWeapon != None )
		{
			if ( RateSelf() > Instigator.PendingWeapon.RateSelf() )
			{
				Instigator.PendingWeapon = self;
				Instigator.Weapon.PutDown();
			}
		}
		else if ( RateSelf() > Instigator.Weapon.RateSelf() )
		{
			Instigator.PendingWeapon = self;
			Instigator.Weapon.PutDown();
		}
	}
}
simulated function BringUp(optional Weapon PrevWeapon)
{
	if ( ClientState == WS_Hidden )
	{
		PlayOwnedSound(SelectSound, SLOT_Interact,,,,, false);
		ClientPlayForceFeedback(SelectForce);  // jdf

		if ( Instigator.IsLocallyControlled() )
		{
			if ( (Mesh!=None) && HasAnim(SelectAnim) )
				PlayAnim(SelectAnim, SelectAnimRate, 0.0);
		}

		ClientState = WS_BringUp;
		SetTimer(BringUpTime, false);
	}
	if ( (PrevWeapon != None) && PrevWeapon.HasAmmo() && !PrevWeapon.bNoVoluntarySwitch )
		OldWeapon = PrevWeapon;
	else OldWeapon = None;
}
simulated function Tick( float Delta )
{
	if( !bClientFire && !bClientAltFire ) Return;
	if( Instigator==None || Instigator.Controller==None ) Return;
	if( bClientFire && Instigator.Controller.bFire==0 )
		ClientStopFire(0);
	if( bClientAltFire && Instigator.Controller.bAltFire==0 )
		ClientStopFire(1);
}
simulated function Timer()
{
	local float OldDownDelay;

	OldDownDelay = DownDelay;
	DownDelay = 0;

	if (ClientState == WS_BringUp)
	{
		PlayIdle();
		ClientState = WS_ReadyToFire;
	}
	else if (ClientState == WS_PutDown)
	{
		if ( OldDownDelay > 0 )
		{
			if ( HasAnim(PutDownAnim) )
				PlayAnim(PutDownAnim, PutDownAnimRate, 0.0);
			SetTimer(PutDownTime, false);
			return;
		}
		if ( Instigator.PendingWeapon == None )
		{
			PlayIdle();
			ClientState = WS_ReadyToFire;
		}
		else
		{
			ClientState = WS_Hidden;
			Instigator.ChangedWeapon();
			if ( Instigator.Weapon == self )
			{
				PlayIdle();
				ClientState = WS_ReadyToFire;
			}
		}
    }
}
simulated function bool PutDown()
{
	if (ClientState == WS_BringUp || ClientState == WS_ReadyToFire)
	{
		if (Instigator.IsLocallyControlled())
		{
			if (  DownDelay <= 0 )
			{
				if ( ClientState == WS_BringUp )
					TweenAnim(SelectAnim,PutDownTime);
				else if ( HasAnim(PutDownAnim) )
					PlayAnim(PutDownAnim, PutDownAnimRate, 0.0);
			}
		}
		ClientState = WS_PutDown;
		if ( Level.GRI.bFastWeaponSwitching )
			DownDelay = 0;
		if ( DownDelay > 0 )
			SetTimer(DownDelay, false);
		else SetTimer(PutDownTime, false);
	}
	Instigator.AmbientSound = None;
	OldWeapon = None;
	return true; // return false if preventing weapon switch
}
Static function AddFXMeshType( Level XMap, StaticMesh SM, ConvexVolume ConvX, Class<Actor> EClass )
{
	local int i;

	if( Default.LoadedOnMap==None || Default.LoadedOnMap!=XMap )
	{
		Default.LoadedOnMap = XMap;
		Default.MeshesType.Length = 0;
	}
	i = Default.MeshesType.Length;
	Default.MeshesType.Length = i+1;
	Default.MeshesType[i].StaticM = SM;
	Default.MeshesType[i].Convex = ConvX;
	Default.MeshesType[i].EmitterType = EClass;
}

defaultproperties
{
	GridSize=16
     ImportedData=Texture'ConstConvexMeshes.BindMe'
     DistanceFromPlayer=500.000000
     ChosenScale=(X=1.000000,Y=1.000000,Z=1.000000)
     PutDownAnim="PutDown"
     SelectSound=Sound'NewWeaponSounds.NewLinkSelect'
     SelectForce="SwitchToLinkGun"
     CurrentRating=0.680000
     bMatchWeapons=True
     Description="Build those houses and stuff with this shit!"
     DisplayFOV=60.000000
     Priority=7
     HudColor=(R=255,G=255,B=0,A=255)
     InventoryGroup=5
     PickupClass=Class'Constructor.Constructor'
     BobDamping=1.575000
     AttachmentClass=Class'XWeapons.LinkAttachment'
     IconMaterial=Texture'HUDContent.Generic.HUD'
     IconCoords=(X1=169,Y1=78,X2=244,Y2=124)
     ItemName="Constructor Gun"
}
