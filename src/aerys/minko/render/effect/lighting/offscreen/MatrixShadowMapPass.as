package aerys.minko.render.effect.lighting.offscreen
{
	import aerys.minko.render.RenderTarget;
	import aerys.minko.render.effect.lighting.LightingProperties;
	import aerys.minko.render.shader.ShaderSettings;
	import aerys.minko.render.shader.ShaderInstance;
	import aerys.minko.render.shader.Shader;
	import aerys.minko.render.shader.SFloat;
	import aerys.minko.render.shader.part.animation.VertexAnimationShaderPart;
	import aerys.minko.type.enum.Blending;
	
	public class MatrixShadowMapPass extends Shader
	{
		private var _vertexAnimationPart	: VertexAnimationShaderPart;
		
		private var _lightId		: uint;
		private var _priority		: Number;
		private var _renderTarget	: RenderTarget;
		
		private var _vertexPosition	: SFloat;
		
		public function MatrixShadowMapPass(lightId			: uint,
											priority		: Number,
											renderTarget	: RenderTarget)
		{
			_vertexAnimationPart	= new VertexAnimationShaderPart(this);
			
			_lightId				= lightId;
			_priority				= priority;
			_renderTarget			= renderTarget;
		}
		
		override protected function initializeSettings(passConfig : ShaderSettings) : void
		{
			passConfig.blending		= Blending.NORMAL;
			passConfig.priority		= _priority;
			passConfig.renderTarget = _renderTarget;
			
			passConfig.enabled = 
				meshBindings.getConstant(LightingProperties.CAST_SHADOWS, true);
		}
		
		override protected function getVertexPosition() : SFloat
		{
			_vertexPosition = _vertexAnimationPart.getAnimatedVertexPosition();
			
			var worldPosition		: SFloat = localToWorld(_vertexPosition);
			var worldToLightScreen	: SFloat = sceneBindings.getParameter('lightWorldToLightScreen' + _lightId, 16);
			var clipSpacePosition	: SFloat = multiply4x4(worldPosition, worldToLightScreen);
			
			return clipSpacePosition;
		}
		
		override protected function getPixelColor() : SFloat
		{
			var worldPosition		: SFloat = localToWorld(interpolate(_vertexPosition));
			var worldToLightScreen	: SFloat = sceneBindings.getParameter('lightWorldToLightScreen' + _lightId, 16);
			var clipSpacePosition	: SFloat = multiply4x4(worldPosition, worldToLightScreen);
			var depth				: SFloat = divide(clipSpacePosition.zzz, clipSpacePosition.www);
			
			return float4(depth.xxx, 1);
//			return pack(depth);
		}
	}
}
