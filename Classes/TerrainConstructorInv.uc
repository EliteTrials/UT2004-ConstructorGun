// just a test.
Class TerrainConstructorInv Extends ConstructorInv;

Replication
{
	reliable if( Role < Role_Authority )
		ServerPokeTerrain;
}

Simulated Function PostNetBeginPlay()
{
	Super(Weapon).PostNetBeginPlay();
}

Simulated Function Weapon NextWeapon( Weapon CurrentChoice, Weapon CurrentWeapon )
{
	if( Instigator.Weapon == Self )
		DistanceFromPlayer += 25;
	else return Super(Weapon).NextWeapon(CurrentChoice,CurrentWeapon);
}

Simulated Function Weapon PrevWeapon( Weapon CurrentChoice, Weapon CurrentWeapon )
{
	if( Instigator.Weapon == Self )
		DistanceFromPlayer -= 25;
	else return Super(Weapon).PrevWeapon(CurrentChoice,CurrentWeapon);
}

Simulated Event ClientStartFire( int Mode )
{
	local TerrainInfo Terr;

	if( Mode == 0 )
		bClientFire = True;
	else bClientAltFire = True;

	ForEach AllActors( Class'TerrainInfo', Terr )
		ServerPokeTerrain( Mode, Terr );
}

Simulated Function ServerPokeTerrain( int Mode, TerrainInfo Terr )
{
	if( Terr != None )
	{
		if( Mode == 0 )
			Terr.PokeTerrain( GetEffectStart(), DistanceFromPlayer, GridSize );
		else Terr.PokeTerrain( GetEffectStart(), DistanceFromPlayer, -GridSize );

		Log( string( Mode )@DistanceFromPlayer@GridSize, Self.Name );
	}
}

Simulated Event RenderOverlays( Canvas Canvas )
{
	Canvas.SetDrawColor(255,255,255);
	Canvas.DrawColor.A = 255;
	Canvas.SetPos( Canvas.ClipX - Canvas.ClipX/1.5, Canvas.ClipY - 128 );
	Canvas.Font = Font'UT2003Fonts.jFontSmallText800x600';
	Canvas.DrawText( "Radius:"@DistanceFromPlayer@"Power:"@GridSize );
	Canvas.SetPos( Canvas.ClipX - Canvas.ClipX/1.5, Canvas.ClipY - 112 );
	Canvas.DrawText( "Location:"@GetEffectStart() );
	Super(Weapon).RenderOverlays( Canvas );
}

DefaultProperties
{
	InventoryGroup=6
}
