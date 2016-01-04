//=============================================================================
// EmitA.
//=============================================================================
class EmitA extends NetCEmitter;

defaultproperties
{
     Begin Object Class=SpriteEmitter Name=SpriteEmitter1
         FadeOut=True
         FadeIn=True
         UniformSize=True
         UseRandomSubdivision=True
         Acceleration=(Z=5.000000)
         FadeOutStartTime=0.300000
         FadeInEndTime=0.250000
         StartLocationRange=(X=(Min=-25.000000,Max=25.000000),Y=(Min=-25.000000,Max=25.000000))
         StartSizeRange=(X=(Min=35.000000,Max=20.000000))
         Texture=Texture'EmitterTextures.MultiFrame.smoke_a'
         TextureUSubdivisions=4
         TextureVSubdivisions=4
         StartVelocityRange=(X=(Min=-5.000000,Max=5.000000),Y=(Min=-5.000000,Max=5.000000),Z=(Max=25.000000))
     End Object
     Emitters(0)=SpriteEmitter'Constructor.EmitA.SpriteEmitter1'

}
