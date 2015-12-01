/**************************************************************************************************
 *                         Точка с целочисленными координатами                                    *
 **************************************************************************************************

ОПИСАНИЕ:
  Трехмерная точка с целочисленными координатами

*/

class Point3D
{
  	public int x, y, z;

  	public Point3D()
  	{
  		x=0; y=0; z=0;
  	}

  	public Point3D(int x, int y, int z)
  	{
  		this.x=x;
  		this.y=y;
  		this.z=z;
  	}

  	public Point3D(Point3D other)
  	{
  		x=other.x;
  		y=other.y;
  		z=other.z;
  	}

}