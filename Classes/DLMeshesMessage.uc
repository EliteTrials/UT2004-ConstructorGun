class DLMeshesMessage extends CriticalEventPlus
	abstract;
	
static function string GetString(
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1, 
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object OptionalObject
    )
{
	if( OptionalObject==None || ClientReplic(OptionalObject)==None )
		Return "";
	else Return ClientReplic(OptionalObject).GetDLingMessageStr();
}

defaultproperties
{
     bIsConsoleMessage=False
     DrawColor=(B=0,G=0,R=255)
     StackMode=SM_Down
     PosY=0.150000
}
