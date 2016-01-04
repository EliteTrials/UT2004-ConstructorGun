//=============================================================================
// Private build area, where only the area owned may mess around in!
//=============================================================================
class PrivateBuildZone extends PhysicsVolume;

var PlayerReplicationInfo PRIOwner;
var array<Controller> ZoneOwner;
var ConstructData DataPool;
var float LastMessageTime;

replication
{
	// Stuff sent for client
	reliable if( bNetDirty && Role==ROLE_Authority )
		PRIOwner;
}

simulated function PostNetReceive()
{
	if( PRIOwner==None )
		LocationName = Default.LocationName;
	else LocationName = PRIOwner.PlayerName$"'s construct area";
}
simulated event PawnEnteredVolume(Pawn Other)
{
	if( Level.NetMode!=NM_Client && (LastMessageTime<Level.TimeSeconds) && DataPool!=None )
	{
		LastMessageTime = Level.TimeSeconds+3;
		if( DataPool.AreaOwnedName!="" )
			Other.ClientMessage("Entered"@GetOwnerNames()$"'s private property");
		else Other.ClientMessage("Entered an empty private property");
	}
}
function string GetOwnerNames()
{
	local string S;
	local int i;

	S = DataPool.AreaOwnedName;
	if( DataPool.CoOwner.Length==0 )
		Return S;
	S = S@"(Co-Owners: ";
	For( i=0; i<DataPool.CoOwner.Length; i++ )
	{
		if( i==0 )
			S = S$DataPool.CoOwner[i].OwnerName;
		else S = S$"/"$DataPool.CoOwner[i].OwnerName;
	}
	Return S$")";
}
function bool PlayerIsTheOwner( Controller Other )
{
	local int i;

	if( Other==None ) Return False;
	For( i=0; i<ZoneOwner.Length; i++ )
	{
		if( ZoneOwner[i]==Other )
			Return True;
	}
	Return False;
}
function AddAnOwner( Controller Other )
{
	local int i;

	For( i=0; i<ZoneOwner.Length; i++ )
	{
		if( ZoneOwner[i]==None )
		{
			ZoneOwner[i] = Other;
			Return;
		}
	}
	i = ZoneOwner.Length;
	ZoneOwner.Length = i+1;
	ZoneOwner[i] = Other;
}

defaultproperties
{
     LocationName="Private construct area"
     bStatic=False
     bNetNotify=True
}
