// just a test.
Class BrushConstructorInv Extends ConstructorInv;

var NetBrush ClientBrush;

Replication
{
	reliable if( Role < ROLE_Authority )
		ServerPlaceBrush;
}

Simulated Function PostNetBeginPlay()
{
	Super(Weapon).PostNetBeginPlay();
	if( Level.NetMode != NM_DedicatedServer )
		ClientBrush = Spawn( Class'NetBrush', Self );
}

Simulated Event ClientStartFire( int Mode )
{
	if( Mode == 0 )
		bClientFire = True;
	else bClientAltFire = True;

	if( Mode == 0 )
		ServerPlaceBrush();
}

Simulated Function ServerPlaceBrush()
{
	local NetBrush CSG;

	CSG = Spawn( Class'NetBrush', Self,, MiniToBig( PlaceLocation ), Instigator.Rotation );
}

Simulated Event RenderOverlays( Canvas Canvas )
{
	local MiniVector OldPos;

	if( ClientBrush == None )return;
	Canvas.SetDrawColor( 255, 255, 255 );
	Canvas.DrawColor.A = 255;
	Canvas.SetPos( Canvas.ClipX - Canvas.ClipX/1.5, Canvas.ClipY - 128 );
	Canvas.Font = Font'UT2003Fonts.jFontSmallText800x600';
	Canvas.DrawText( "Distance:"@DistanceFromPlayer@"Grid:"@GridSize );
	Canvas.SetPos( Canvas.ClipX - Canvas.ClipX/1.5, Canvas.ClipY - 112 );
	Canvas.DrawText( "Location:"@ClientBrush.Location@"Rotation:"@ClientBrush.Rotation );
	OldPos = PlaceLocation;
	PlaceLocation = BigToMini( Instigator.Location+vector(Instigator.Controller.Rotation)*DistanceFromPlayer );
	if( OldPos != PlaceLocation )
		ClientBrush.SetLocation( MiniToBig( PlaceLocation ) );;
	Super(Weapon).RenderOverlays( Canvas );
}

DefaultProperties
{
	InventoryGroup=6
	ItemName="Brush Constructor"
}
