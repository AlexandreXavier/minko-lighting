package aerys.minko.render.effect.reflection.offscreen
{
	import aerys.minko.render.effect.SinglePassRenderingEffect;
	import aerys.minko.render.effect.basic.BasicStyle;
	import aerys.minko.render.effect.reflection.ReflectionStyle;
	import aerys.minko.render.renderer.RendererState;
	import aerys.minko.render.shader.IShader;
	import aerys.minko.render.target.AbstractRenderTarget;
	import aerys.minko.scene.data.StyleData;
	import aerys.minko.scene.data.TransformData;
	import aerys.minko.type.enum.TriangleCulling;
	
	import flash.utils.Dictionary;
	
	public class PlanarReflectionMapPass extends SinglePassRenderingEffect
	{
		public function PlanarReflectionMapPass(reflectionId : uint, 
												priority:Number=0.0, 
												renderTarget:AbstractRenderTarget=null)
		{
			var shader : IShader = new PlanarReflectionMapShader(reflectionId);
			
			super(shader, priority, renderTarget);
		}
		
		override public function fillRenderState(state:RendererState, styleData:StyleData, transformData:TransformData, worldData:Dictionary):Boolean
		{
			if (styleData.get(ReflectionStyle.CAST, 0) == 0)
				return false;
			styleData.set(BasicStyle.TRIANGLE_CULLING, TriangleCulling.DISABLED);
			
			return super.fillRenderState(state, styleData, transformData, worldData);
		}
	}
}