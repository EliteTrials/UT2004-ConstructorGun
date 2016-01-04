class AreaOwnedMSGr extends Trigger;

var() edfindable PrivateBuildZone TheVolume;

function Actor SpecialHandling(Pawn Other)
{
	return None;
}
function bool IsRelevant( actor Other )
{
	Return (Other.IsA('Pawn'));
}
function Touch( actor Other )
{
	local string S;

	if( IsRelevant( Other ) )
	{
		if ( ReTriggerDelay > 0 )
		{
			if ( Level.TimeSeconds - TriggerTime < ReTriggerDelay )
				return;
			TriggerTime = Level.TimeSeconds;
		}
		if( (TheVolume!=None) && (Other.Instigator != None) )
		{
			if( TheVolume.DataPool!=None && TheVolume.DataPool.AreaOwnedName!="" )
				S = TheVolume.DataPool.AreaOwnedName;
			else S = "Nobody";
			Other.Instigator.ClientMessage(S$Message);
		}

		if( bTriggerOnceOnly )
			SetCollision(False);
		else if ( RepeatTriggerTime > 0 )
			SetTimer(RepeatTriggerTime, false);
	}
}

defaultproperties
{
     Message="'s area"
}
