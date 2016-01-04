class ConstBeamFireZ extends ConstBeamFire;

function DoTrace(Vector Start, Rotator Dir)
{
	local Vector X, End, HitLocation, HitNormal, RefNormal;
	local Actor Other;
	local int Damage;
	local bool bDoReflect;
	local int ReflectNum;

	MaxRange();

	ReflectNum = 0;
	while (true)
	{
		bDoReflect = false;
		X = Vector(Dir);
		End = Start + TraceRange * X;

		Other = Weapon.Trace(HitLocation, HitNormal, End, Start, true);

		if ( Other != None && (Other != Instigator || ReflectNum > 0) )
		{
			if (bReflective && Other.IsA('xPawn') && xPawn(Other).CheckReflect(HitLocation, RefNormal, DamageMin*0.25))
			{
				bDoReflect = true;
				HitNormal = Vect(0,0,0);
			}
			else if( Other.IsA('NetStaticMesh') && MayDestroy(Other) )
				Other.Destroy();
			else if ( !Other.bWorldGeometry )
			{
				Damage = DamageMin;
				if ( (DamageMin != DamageMax) && (FRand() > 0.5) )
				Damage += Rand(1 + DamageMax - DamageMin);
				Damage = Damage * DamageAtten;

				// Update hit effect except for pawns (blood) other than vehicles.
				if ( Other.IsA('Vehicle') || (!Other.IsA('Pawn') && !Other.IsA('HitScanBlockingVolume')) )
					WeaponAttachment(Weapon.ThirdPersonActor).UpdateHit(Other, HitLocation, HitNormal);

				Other.TakeDamage(Damage, Instigator, HitLocation, Momentum*X, DamageType);
				HitNormal = Vect(0,0,0);
			}
			else if ( WeaponAttachment(Weapon.ThirdPersonActor) != None )
				WeaponAttachment(Weapon.ThirdPersonActor).UpdateHit(Other,HitLocation,HitNormal);
		}
		else
		{
			HitLocation = End;
			HitNormal = Vect(0,0,0);
			WeaponAttachment(Weapon.ThirdPersonActor).UpdateHit(Other,HitLocation,HitNormal);
		}
		SpawnBeamEffect(Start, Dir, HitLocation, HitNormal, ReflectNum);

		if (bDoReflect && ++ReflectNum < 4)
		{
			//Log("reflecting off"@Other@Start@HitLocation);
			Start = HitLocation;
			Dir = Rotator(RefNormal); //Rotator( X - 2.0*RefNormal*(X dot RefNormal) );
		}
		else break;
	}
}
function bool MayDestroy( Actor Other )
{
	local PhysicsVolume P;

	if( Pawn(Weapon.Owner).PlayerReplicationInfo!=None && Pawn(Weapon.Owner).PlayerReplicationInfo.bAdmin )
		Return True;
	P = Other.PhysicsVolume;
	if( !P.IsA('PrivateBuildZone') && !P.IsA('PublicBuildZone') )
		P = Class'ConstructorInvZ'.Static.FindVolumeFor(Other.Location,Level);
	if( P==None ) Return False;
	if( P.IsA('PublicBuildZone') )
		Return True;
	else if( P.IsA('PrivateBuildZone') && PrivateBuildZone(P).PlayerIsTheOwner(Instigator.Controller) )
		Return True;
	Return False;
}

defaultproperties
{
}
