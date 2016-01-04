//=============================================================================
// EmitC.
//=============================================================================
class EmitC extends NetCEmitter;

defaultproperties
{
     Begin Object Class=SpriteEmitter Name=SpriteEmitter3
         FadeOut=True
         FadeIn=True
         SpinParticles=True
         UniformSize=True
         UseRandomSubdivision=True
         Acceleration=(Z=5.000000)
         ColorMultiplierRange=(X=(Min=0.750000,Max=0.750000),Y=(Min=0.000000,Max=0.000000))
         FadeOutStartTime=0.150000
         FadeInEndTime=0.150000
         MaxParticles=15
         StartSpinRange=(X=(Min=0.375000,Max=0.375000))
         StartSizeRange=(X=(Min=35.000000,Max=20.000000))
         Texture=Texture'EmitterTextures.MultiFrame.LargeFlames-grey'
         TextureUSubdivisions=4
         TextureVSubdivisions=4
         LifetimeRange=(Min=1.500000,Max=0.500000)
         StartVelocityRange=(Z=(Min=75.000000,Max=50.000000))
     End Object
     Emitters(0)=SpriteEmitter'Constructor.EmitC.SpriteEmitter3'

}
