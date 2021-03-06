package aerys.minko.scene.node.light
{
	import aerys.minko.ns.minko;
	import aerys.minko.scene.data.LightData;
	import aerys.minko.scene.data.TransformData;
	import aerys.minko.type.math.Matrix4x4;
	import aerys.minko.type.math.Vector4;
	
	use namespace minko;
	
	public class PointLight extends AbstractLight
	{
		protected var _position			: Vector4;
		protected var _distance			: Number;
		protected var _diffuse			: Number;
		protected var _specular			: Number;
		protected var _shininess		: Number;
		protected var _shadowMapSize	: uint;
		
		public function get position()		: Vector4	{ return _position;			}
		public function get distance()		: Number	{ return _distance;			}
		public function get diffuse()		: Number	{ return _diffuse;			}
		public function get specular()		: Number	{ return _specular;			} 
		public function get shininess()		: Number	{ return _shininess;		}
		public function get shadowMapSize()	: uint		{ return _shadowMapSize;	}

		public function set position		(value : Vector4)	: void	{ _position	= value;		}
		public function set distance		(value : Number)	: void	{ _distance	= value;		}
		public function set diffuse			(value : Number)	: void	{ _diffuse	= value;		}
		public function set specular		(value : Number)	: void	{ _specular = value;		}
		public function set shininess		(value : Number)	: void	{ _shininess = value;		}
		public function set shadowMapSize	(value : uint) 		: void	{ _shadowMapSize = value;	}
		
		public function PointLight(color			: uint		= 0xFFFFFF,
								   diffuse			: Number	= .6,
								   specular			: Number	= .8,
								   shininess		: Number	= 64,
								   position			: Vector4 	= null,
								   distance			: Number	= 0,
								   group			: uint		= 0x1)
		{
			super(color, group); 
			
			_position		= position || new Vector4();
			_distance		= distance;
			_diffuse		= diffuse;
			_specular		= specular;
			_shininess		= shininess;
			_shadowMapSize	= 0;
		}
		
		override public function getLightData(transformData : TransformData) : LightData
		{
			if ((isNaN(_diffuse) || _diffuse == 0) && (isNaN(_specular) || _specular == 0))
				return null;
			
			// compute world space position
			var worldMatrix 	: Matrix4x4	= transformData.world;
			var worldPosition 	: Vector4 	= worldMatrix.transformVector(_position);
			
			// fill LightData object
			var ld : LightData = LIGHT_DATA.create(true) as LightData;
			
			ld.reset();
			ld._group			= _group;
			ld._type			= LightData.TYPE_POINT;
			ld._position		= worldPosition;
			ld._color			= _color;
			ld._distance		= _distance;
			ld._diffuse			= _diffuse;
			ld._specular		= _specular;
			ld._shininess		= _shininess;
			ld._shadowMapSize	= _shadowMapSize;
			ld._outerRadius		= 0;
			
			return ld;
		}
		
	}
}
