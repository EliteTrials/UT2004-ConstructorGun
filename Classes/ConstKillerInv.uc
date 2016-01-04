//=============================================================================
// ConstKillerInv
//=============================================================================
class ConstKillerInv extends ShockRifle;

simulated function bool HasAmmo()
{
	return True; // Unlimited ammo
}

defaultproperties
{
     FireModeClass(0)=Class'Constructor.ConstBeamFire'
     FireModeClass(1)=Class'Constructor.ConstBeamFire'
     Description="Use it to kill those construction those noobs builded MOUHAHAHAHA...."
     PickupClass=Class'Constructor.ConstKiller'
     ItemName="Construction Killer!"
}
