package aerys.minko.render.shader.node.light
{
	import aerys.minko.render.effect.animation.AnimationStyle;
	import aerys.minko.render.effect.basic.BasicStyle;
	import aerys.minko.render.effect.lighting.LightingStyle;
	import aerys.minko.render.shader.node.IFragmentNode;
	import aerys.minko.render.shader.node.INode;
	import aerys.minko.render.shader.node.animation.AnimatedNormal;
	import aerys.minko.render.shader.node.animation.MorphedNormal;
	import aerys.minko.render.shader.node.leaf.Attribute;
	import aerys.minko.render.shader.node.leaf.Constant;
	import aerys.minko.render.shader.node.leaf.StyleParameter;
	import aerys.minko.render.shader.node.leaf.WorldParameter;
	import aerys.minko.render.shader.node.operation.builtin.Absolute;
	import aerys.minko.render.shader.node.operation.builtin.DotProduct3;
	import aerys.minko.render.shader.node.operation.builtin.Multiply;
	import aerys.minko.render.shader.node.operation.builtin.Negate;
	import aerys.minko.render.shader.node.operation.builtin.Normalize;
	import aerys.minko.render.shader.node.operation.builtin.Power;
	import aerys.minko.render.shader.node.operation.builtin.Saturate;
	import aerys.minko.render.shader.node.operation.builtin.Substract;
	import aerys.minko.render.shader.node.operation.manipulation.Interpolate;
	import aerys.minko.render.shader.node.operation.math.Product;
	import aerys.minko.render.shader.node.operation.math.Sum;
	import aerys.minko.scene.data.CameraData;
	import aerys.minko.scene.data.LightData;
	import aerys.minko.scene.data.StyleData;
	import aerys.minko.type.animation.AnimationMethod;
	import aerys.minko.type.stream.format.VertexComponent;
	
	public class DirectionalLightNode extends Saturate implements IFragmentNode
	{
		
		// clean this!
		public function DirectionalLightNode(lightIndex : uint,
											 lightData 	: LightData,
											 styleStack : StyleData)
		{
			super(initialize(lightIndex, lightData, styleStack));
		}
		
		private function initialize(lightIndex	: uint,
									lightData 	: LightData,
									styleStack 	: StyleData) : INode
		{
			var position	: INode 	= new Interpolate(new Attribute(VertexComponent.XYZ));
			var normal		: INode 	= getNormal(styleStack);
			
			var lightDirection : INode = 
				new WorldParameter(3, LightData, LightData.LOCAL_DIRECTION, lightIndex);
			
			var lightSurfaceSaturatedCosine : INode = new Saturate(
				new Negate(
					new DotProduct3(lightDirection, normal)
				)
			);
			
			// light strength
			var lightStrength : Vector.<INode> = new Vector.<INode>();
			
			// calculate diffuse light value.
			if (!isNaN(lightData.diffuse) && lightData.diffuse != 0)
			{
				lightStrength.push(
					new Product(
						new WorldParameter(3, LightData, LightData.PREMULTIPLIED_DIFFUSE_COLOR, lightIndex),
						lightSurfaceSaturatedCosine
					)
				);
			}
			
			// calculate specular light value.
			if (!isNaN(lightData.specular) && lightData.specular != 0)
			{
				var viewDirection : INode = new Normalize(
					new Substract(position, new WorldParameter(3, CameraData, CameraData.LOCAL_POSITION))
				);
				
				var reflectionVector : INode = new Normalize(
					new Substract( 
						new Product(lightSurfaceSaturatedCosine, new Constant(2), normal),
						lightDirection
					)
				);
				
				lightStrength.push(
					new Multiply(
						new WorldParameter(3, LightData, LightData.PREMULTIPLIED_SPECULAR_COLOR, lightIndex),
						new Power(
							new Saturate(new Negate(new DotProduct3(reflectionVector, viewDirection))),
							new WorldParameter(1, LightData, LightData.PREMULTIPLIED_SHININESS, lightIndex)
						)
					)
				);
			}
			
			return Sum.fromVector(lightStrength);
		}
		
		private function getNormal(styleStack : StyleData) : INode
		{
			var normal	: INode	= new AnimatedNormal(
				styleStack.get(AnimationStyle.METHOD, AnimationMethod.DISABLED) as uint,
				styleStack.get(AnimationStyle.MAX_INFLUENCES, 0) as uint,
				styleStack.get(AnimationStyle.NUM_BONES, 0) as uint
			);
			
			return new Interpolate(
				new Multiply(
					normal,
					new StyleParameter(1, BasicStyle.NORMAL_MULTIPLIER)
				)
			);
		}
	}
}