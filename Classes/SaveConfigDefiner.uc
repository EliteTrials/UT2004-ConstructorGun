Class SaveConfigDefiner extends Info
	Placeable;

var() class<ConstructData> SaveDataObject;
var ReplicationHandler TheMute;
var() array<ReplicationHandler.sMeshConfigType> MeshesList;
var() bool bCreateIniFile;

function PreBeginPlay()
{
	local PrivateBuildZone PR;

	CheckForMutator();
	ForEach DynamicActors(class'PrivateBuildZone',PR)
	{
		PR.DataPool = SaveDataObject.Static.LoadVolumeData(PR);
		PR.DataPool.LoadUpData(Level);
		TheMute.AddToNotifyList(PR);
	}
}
function CheckForMutator()
{
	local Mutator M;
	local ReplicationHandler RM;

	For( M=Level.Game.BaseMutator; M!=None; M=M.NextMutator )
	{
		if( ReplicationHandler(M)!=None )
		{
			TheMute = ReplicationHandler(M);
			Return;
		}
	}
	RM = Spawn(class'ReplicationHandler');
	if( RM==None ) Return;
	if( bCreateIniFile && Level.NetMode == NM_StandAlone )
	{
		RM.MeshNames = MeshesList;
		RM.SaveConfig();
	}
	RM.NextMutator = Level.Game.BaseMutator;
	Level.Game.BaseMutator = RM;
	TheMute = RM;
}

defaultproperties
{
	SaveDataObject=Class'Constructor.ConstructData'
	bStatic=True
	DrawScale=2.000000
    MeshesList(0)=(StaticMeshName="Constructor.Floor")
	MeshesList(1)=(StaticMeshName="Constructor.Wall")
	MeshesList(2)=(StaticMeshName="Constructor.Stair")
	MeshesList(3)=(StaticMeshName="Constructor.Block")
	MeshesList(4)=(StaticMeshName="Constructor.Pillar")
	MeshesList(5)=(StaticMeshName="Constructor.DoubleGlass")
}
