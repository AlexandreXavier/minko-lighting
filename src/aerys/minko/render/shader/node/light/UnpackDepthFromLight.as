package aerys.minko.render.shader.node.light
{
	import aerys.minko.render.shader.node.Dummy;
	import aerys.minko.render.shader.node.IFragmentNode;
	import aerys.minko.render.shader.node.INode;
	import aerys.minko.render.shader.node.leaf.Constant;
	import aerys.minko.render.shader.node.leaf.Sampler;
	import aerys.minko.render.shader.node.operation.builtin.Texture;
	import aerys.minko.render.shader.node.operation.packing.UnpackColorIntoScalar;
	
	public class UnpackDepthFromLight extends Dummy implements IFragmentNode
	{
		public function UnpackDepthFromLight(lightIndex : uint, samplerStyleId : int)
		{
			var uv				: INode		= new UVFromLight(lightIndex);
			var sampler			: Sampler	= new Sampler(55555555 + lightIndex, Sampler.FILTER_LINEAR, Sampler.MIPMAP_DISABLE, Sampler.WRAPPING_CLAMP);
			var packedDepth		: INode		= new Texture(uv, sampler);
			
			var quarterMaxValue	: INode		= new Constant(400);
			var maxValue		: INode		= new Constant(1600);
			
			var unpackedDepth	: INode		= new UnpackColorIntoScalar(packedDepth, quarterMaxValue, maxValue);
			
			super(unpackedDepth);
		}
	}
}