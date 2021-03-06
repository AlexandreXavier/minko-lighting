package aerys.minko.render.shader.node.light
{
	import aerys.minko.render.effect.animation.AnimationStyle;
	import aerys.minko.render.effect.basic.BasicStyle;
	import aerys.minko.render.effect.lighting.LightingStyle;
	import aerys.minko.render.shader.node.Dummy;
	import aerys.minko.render.shader.node.IFragmentNode;
	import aerys.minko.render.shader.node.INode;
	import aerys.minko.render.shader.node.animation.AnimatedNormal;
	import aerys.minko.render.shader.node.animation.MorphedNormal;
	import aerys.minko.render.shader.node.leaf.Attribute;
	import aerys.minko.render.shader.node.leaf.Constant;
	import aerys.minko.render.shader.node.leaf.StyleParameter;
	import aerys.minko.render.shader.node.leaf.WorldParameter;
	import aerys.minko.render.shader.node.operation.builtin.Absolute;
	import aerys.minko.render.shader.node.operation.builtin.Add;
	import aerys.minko.render.shader.node.operation.builtin.DotProduct3;
	import aerys.minko.render.shader.node.operation.builtin.Multiply;
	import aerys.minko.render.shader.node.operation.builtin.Negate;
	import aerys.minko.render.shader.node.operation.builtin.Normalize;
	import aerys.minko.render.shader.node.operation.builtin.Power;
	import aerys.minko.render.shader.node.operation.builtin.Reciprocal;
	import aerys.minko.render.shader.node.operation.builtin.Saturate;
	import aerys.minko.render.shader.node.operation.builtin.SetIfGreaterEqual;
	import aerys.minko.render.shader.node.operation.builtin.SetIfLessThan;
	import aerys.minko.render.shader.node.operation.builtin.Substract;
	import aerys.minko.render.shader.node.operation.manipulation.Interpolate;
	import aerys.minko.render.shader.node.operation.math.Product;
	import aerys.minko.render.shader.node.operation.math.Sum;
	import aerys.minko.scene.data.CameraData;
	import aerys.minko.scene.data.LightData;
	import aerys.minko.scene.data.StyleData;
	import aerys.minko.type.animation.AnimationMethod;
	import aerys.minko.type.stream.format.VertexComponent;
	
	import flash.utils.Dictionary;
	
	public class SpotLightNode extends Dummy implements IFragmentNode
	{
		public static const NO_LIGHT_DEPTH_SAMPLER	: uint	= 0xffffffff;
		
		public function SpotLightNode(lightIndex			: uint, 
									  styleStack			: StyleData, 
									  worldData				: Dictionary, 
									  lightDepthSampler		: uint)
		{
			var lightData			: LightData = worldData[LightData].getItem(lightIndex);
			
			var vertexPosition		: INode = new Interpolate(new Attribute(VertexComponent.XYZ));
			var lightPosition		: INode = new WorldParameter(3, LightData, LightData.LOCAL_POSITION, lightIndex);
			var lightToPoint		: INode = new Substract(vertexPosition, lightPosition);
			var normal				: INode = getNormal(styleStack);
			var lightDirection		: INode	= new WorldParameter(3, LightData, LightData.LOCAL_DIRECTION, lightIndex);
			var localLightDirection	: INode = new Normalize(lightToPoint);
			var lightSurfaceCosine	: INode = new DotProduct3(localLightDirection, new Negate(normal));
			var lightStrength		: Sum	= new Sum();
			
			// calculate diffuse light value.
			if (!isNaN(lightData.diffuse) && lightData.diffuse != 0)
			{
				lightStrength.addTerm(
					new Multiply(
						new WorldParameter(3, LightData, LightData.PREMULTIPLIED_DIFFUSE_COLOR, lightIndex),
						new Saturate(lightSurfaceCosine)
					)
				);
			}
			
			// calculate specular light value.
			if (!isNaN(lightData.specular) && lightData.specular != 0)
			{
				var viewDirection : INode = new Normalize(
					new Substract(vertexPosition, new WorldParameter(3, CameraData, CameraData.LOCAL_POSITION))
				);
				
				var reflectionVector : INode = new Normalize(
					new Substract( // faux!!
						new Product(new Constant(2), lightSurfaceCosine, normal),
						localLightDirection
					)
				);
				
				lightStrength.addTerm(
					new Multiply(
						new WorldParameter(3, LightData, LightData.PREMULTIPLIED_SPECULAR_COLOR, lightIndex),
						new Power(
							new Saturate(new Negate(new DotProduct3(reflectionVector, viewDirection))),
							new WorldParameter(1, LightData, LightData.SHININESS, lightIndex)
						)
					)
				);
			}
			
			var lightAttenuation : Vector.<INode> = new Vector.<INode>();
			
			// cone attenuation
			if (!isNaN(lightData.outerRadius) && lightData.outerRadius != 0)
			{
				var coneAttenuation : INode;
				if (isNaN(lightData.innerRadius) || lightData.outerRadius == lightData.innerRadius)
				{
					coneAttenuation = new SetIfGreaterEqual(
						new DotProduct3(localLightDirection, lightDirection),
						new WorldParameter(1, LightData, LightData.OUTER_RADIUS_COSINE, lightIndex)
					);
				}
				else
				{
					coneAttenuation = new Saturate(
						new Add(
							new WorldParameter(1, LightData, LightData.RADIUS_INTERPOLATION_1, lightIndex),
							new Multiply(
								new WorldParameter(1, LightData, LightData.RADIUS_INTERPOLATION_2, lightIndex),
								new DotProduct3(localLightDirection, lightDirection)
							)
						)
					);
				}
				lightAttenuation.push(coneAttenuation);
			}
			
			// distance attenuation
			if (!isNaN(lightData.distance) && lightData.distance != 0)
			{
				lightAttenuation.push(
					new Saturate(
						new Multiply(
							new WorldParameter(1, LightData, LightData.SQUARE_LOCAL_DISTANCE, lightIndex),
							new Reciprocal(new DotProduct3(lightToPoint, lightToPoint))
						)
					)
				);
			}
			
			// shadows
			var receiveShadows : Boolean = styleStack.get(LightingStyle.RECEIVE_SHADOWS, false)
										   && lightDepthSampler != NO_LIGHT_DEPTH_SAMPLER
							   			   && Boolean(styleStack.get(LightingStyle.SHADOWS_ENABLED))
										   && lightData.castShadows;
			
			if (receiveShadows)
			{
				// compute current depth from light, and retrieve the precomputed value from a depth map
				var precomputedDepth	: INode = new UnpackDepthFromLight(lightIndex, lightDepthSampler);
				var currentDepth		: INode = new DepthFromLight(lightIndex);
				
				currentDepth = new Substract(currentDepth, new StyleParameter(1, LightingStyle.SHADOWS_BIAS, 0.5));
				
				// get the delta between both values, and see if it's small enought
				var willNotShadowMap	: INode = new SetIfLessThan(currentDepth, precomputedDepth);
				lightAttenuation.push(willNotShadowMap);
			}
			
			var result : INode = lightStrength;
			if (lightAttenuation.length != 0)
			{
				result = new Multiply(Product.fromVector(lightAttenuation), result);
			}
			
			super(result);
			
			if (result == null)
				throw new Error('This light\'s data is empty, it should not be in the LightData.DATA style.');
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