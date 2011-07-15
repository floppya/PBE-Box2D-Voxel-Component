package com.snakedickgames.pbe.components.box2d 
{
	import com.pblabs.box2D.Box2DSpatialComponent;
	import com.pblabs.box2D.PolygonCollisionShape;
	import com.pblabs.rendering2D.spritesheet.SpriteSheetComponent;
	import flash.display.BitmapData;
	import flash.display.BitmapDataChannel;
	import flash.geom.Point;
	
	
	public class Box2DVoxelSpatialComponent extends Box2DSpatialComponent 
	{
		private var _voxelData:BitmapData;
		public var voxelSource:SpriteSheetComponent 
		public var numCellsX:int = 10;
		public var numCellsY:int = 10;
		public var alphaThreshold:int = 128;
		public var destructible:Boolean = true;
		
		override protected function onAdd():void
		{
			_voxelData = new BitmapData(voxelSource.imageData.width, voxelSource.imageData.height);
			_voxelData.copyChannel(
				voxelSource.imageData, voxelSource.image.image.getRect(voxelSource.image.image), 
				new Point(), BitmapDataChannel.ALPHA, BitmapDataChannel.ALPHA
			);
			_generateShapesFromVoxels();
			super.onAdd();
		}
		
		public function _generateShapesFromVoxels():void
		{
			collisionShapes = _marchingSquares();
		}
		
		public function _marchingSquares():Array
		{
			var shapes:Array = [];
			// minus one so we get the far right edge and bottom
			var sdx:Number = (_voxelData.width - 1) / numCellsX;
			var sdy:Number = (_voxelData.height - 1) / numCellsY;
			var sy:Number = 0;
			for (var cy:int = 0; cy < numCellsY; cy++) // (c)ell(y)
			{
				var sx:Number = 0;
				//var rowValues:Array = new Array(); // for debugging output
				for (var cx:int = 0; cx < numCellsX; cx++) // (c)ell(x)
				{
					var cellIndex:uint = 0;
					for (var csy:uint = 0; csy <= 1; csy++) // (c)ell(s)ample(y)
					{
						for (var csx:uint = 0; csx <= 1; csx++) // (c)ell(s)ample(x)
						{
							var pixel:uint = _voxelData.getPixel32(sx + csx * sdx, sy + csy * sdy);
							var alpha:uint = pixel >> 24 & 0xFF;
							if (alpha > alphaThreshold) 
							{
								cellIndex |= 1 << (2 * csy + csx); // accumulate cell index
							}
						}
					}
					//rowValues.push(cellIndex);
					if (cellIndex > 0)
					{
						var thisShape:PolygonCollisionShape = _marchingSquareIndexGeometry(cellIndex, cx, cy);
						if (thisShape != null) 
						{
							shapes.push(thisShape);
						}
					}
					sx += sdx; 
				}
				//trace(rowValues);
				sy += sdy;
			}
			return shapes
		}
		
		public function _marchingSquareIndexGeometry(index:uint, cellX:int, cellY:int):PolygonCollisionShape 
		{
			var shape:PolygonCollisionShape;
			// empty space
			if (index == 0)
				return null;
			// special case: saddle point
			if (index == 6 || index == 9)
				return null; // TODO: implement saddle point geometry
			
			var scaleX:Number = 2 / numCellsX;
			var scaleY:Number = 2 / numCellsY;
			var offsetX:Number = scaleX * (cellX - (numCellsX) * 0.5);
			var offsetY:Number = scaleY * (cellY - (numCellsY) * 0.5);
			var indexVerts:Array = Box2DVoxelSpatialComponent._marchingSquaresVertices[index];
			var verts:Array = new Array();
			var vert:Point;
			var thisVert:Point;
			for (var i:uint = 0; i < indexVerts.length; i++)
			{
				thisVert = indexVerts[i];
				vert = new Point(thisVert.x, thisVert.y);				
				vert.x *= scaleX;
				vert.y *= scaleY;
				vert.x += offsetX;
				vert.y += offsetY;
				verts.push(vert);
			}
			shape = new PolygonCollisionShape();
			shape.vertices = verts;
			return shape;
		}
		
		/* Index scheme:
		 * 1----2
		 * |    |
		 * 4----8
		 */
		static public var _marchingSquaresVertices:Array = [
			null, // case 0 is empty
			[new Point(0, 0), new Point(0.5, 0), new Point(0, 0.5)], // 1
			[new Point( 0.5, 0), new Point(1, 0), new Point(1, 0.5)], // 2
			[new Point( 0, 0), new Point(1, 0), new Point(1, 0.5), new Point( 0, 0.5)], // 3
			[new Point( 0, 0.5), new Point(0.5, 1), new Point( 0, 1)], // 4
			[new Point( 0, 0), new Point(0.5, 0), new Point(0.5, 1), new Point( 0, 1)], // 5
			null, // case 6 is a saddle point
			[new Point( 0, 0), new Point(1, 0), new Point(1, 0.5), new Point( 0.5, 1), new Point( 0, 1)], // 7
			[new Point( 0.5, 1), new Point(1, 0.5), new Point(1, 1)], // 8
			null, // case 9 is a saddle point
			[new Point( 0.5, 0), new Point(1, 0), new Point(1, 1), new Point( 0.5, 1)], // 10.5
			[new Point( 0, 0), new Point(1, 0), new Point(1, 1), new Point( 0.5, 1), new Point( 0, 0.5)], // 11
			[new Point( 0, 0.5), new Point(1, 0.5), new Point(1, 1), new Point( 0, 1)], // 12
			[new Point( 0, 0), new Point(0.5, 0), new Point(1, 0.5), new Point(1, 1), new Point( 0, 1)], // 13
			[new Point( 0.5, 0), new Point(1, 0), new Point(1, 1), new Point( 0, 1), new Point( 0, 0.5)], // 14
			[new Point( 0, 0), new Point(1, 0), new Point(1, 1), new Point( 0, 1)], // 15
		];
	}

}