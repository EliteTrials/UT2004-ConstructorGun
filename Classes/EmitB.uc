//=============================================================================
// EmitB.
//=============================================================================
class EmitB extends NetCEmitter;

defaultproperties
{
     Begin Object Class=SpriteEmitter Name=SpriteEmitter2
         FadeOut=True
         FadeIn=True
         SpinParticles=True
         UniformSize=True
         UseRandomSubdivision=True
         Acceleration=(Z=5.000000)
         FadeOutStartTime=0.150000
         FadeInEndTime=0.100000
         StartSpinRange=(X=(Min=0.375000,Max=0.375000))
         StartSizeRange=(X=(Min=45.000000,Max=20.000000))
         Texture=Texture'EmitterTextures.MultiFrame.LargeFlames'
         TextureUSubdivisions=4
         TextureVSubdivisions=4
         LifetimeRange=(Min=0.850000,Max=0.350000)
         StartVelocityRange=(Z=(Min=80.000000,Max=50.000000))
     End Object
     Emitters(0)=SpriteEmitter'Constructor.EmitB.SpriteEmitter2'

}
