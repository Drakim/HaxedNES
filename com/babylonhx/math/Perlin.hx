package com.babylonhx.math;

/**
 * ...
 * @author Krtolica Vujadin
 */
class Perlin {

	private static var GRAD3:Array<Gradient> = [
		new Gradient(1, 1, 0), new Gradient( -1, 1, 0), new Gradient(1, -1, 0), new Gradient( -1, -1, 0),
		new Gradient(1, 0, 1), new Gradient( -1, 0, 1), new Gradient(1, 0, -1), new Gradient( -1, 0, -1),
		new Gradient(0, 1, 1), new Gradient(0, -1, 1), new Gradient(0, 1, -1), new Gradient(0, -1, -1)
	];

	private static var P:Array<Int> = [
		151, 160, 137, 91, 90, 15, 131, 13, 201, 95, 96, 53, 194, 233, 7, 225, 140, 36, 103, 30, 69, 142, 8, 99, 37, 240, 21, 10, 23,
		190, 6, 148, 247, 120, 234, 75, 0, 26, 197, 62, 94, 252, 219, 203, 117, 35, 11, 32, 57, 177, 33, 88, 237, 149, 56, 87, 174,
		20, 125, 136, 171, 168, 68, 175, 74, 165, 71, 134, 139, 48, 27, 166, 77, 146, 158, 231, 83, 111, 229, 122, 60, 211, 133, 230, 
		220, 105, 92, 41, 55, 46, 245, 40, 244, 102, 143, 54, 65, 25, 63, 161, 1, 216, 80, 73, 209, 76, 132, 187, 208, 89, 18, 169, 
		200, 196, 135, 130, 116, 188, 159, 86, 164, 100, 109, 198, 173, 186, 3, 64, 52, 217, 226, 250, 124, 123, 5, 202, 38, 147,
		118, 126, 255, 82, 85, 212, 207, 206, 59, 227, 47, 16, 58, 17, 182, 189, 28, 42, 223, 183, 170, 213, 119, 248, 152, 2, 44, 154, 
		163, 70, 221, 153, 101, 155, 167, 43, 172, 9, 129, 22, 39, 253, 19, 98, 108, 110, 79, 113, 224, 232, 178, 185, 112, 104, 218, 
		246, 97, 228, 251, 34, 242, 193, 238, 210, 144, 12, 191, 179, 162, 241, 81, 51, 145, 235, 249, 14, 239, 107, 49, 192, 214, 31, 
		181, 199, 106, 157, 184, 84, 204, 176, 115, 121, 50, 45, 127, 4, 150, 254, 138, 236, 205, 93, 222, 114, 67, 29, 24, 72, 243, 141, 
		128, 195, 78, 66, 215, 61, 156, 180
	];	
	
	private var perm:Array<Int>;
	private var gradP:Array<Gradient>;
	

	private function fade(t:Float):Float {
		return t * t * t * (t * (t * 6 - 15) + 10);
	}

	private function lerp(a:Float, b:Float, t:Float):Float {
		return (1 - t) * a + t * b;
	}

	public function new(_seed:Float) {
		perm = new Array<Int>();
		gradP = new Array<Gradient>();
		for (i in 0...512) {
			perm.push(0);
			gradP.push(null);
		}
		
		if (_seed > 0 && _seed < 1) {
            // Scale the seed out
            _seed *= 65536;
        }
		
        var seed = Math.floor(_seed);
        if (seed < 256) {
            seed |= seed << 8;
        }
		
		var v;
		for (i in 0...256) {
			if (i & 1 == 1) {
				v = P[i] ^ (seed & 255);
			}
			else {
				v = P[i] ^ ((seed >> 8) & 255);
			}
			
			perm[i] = perm[i + 256] = v;
			gradP[i] = gradP[i + 256] = GRAD3[v % 12];
		}
	}
	
	// Skewing and unskewing factors for 2, 3, and 4 dimensions
    var F2:Float = 0.5 * (Math.sqrt(3) - 1);
    var G2:Float = (3 - Math.sqrt(3)) / 6;

    var F3:Float = 1 / 3;
    var G3:Float = 1 / 6;

    // 2D simplex noise
    public function simplex2(xin:Float, yin:Float):Float {
        var n0:Float = 0;
		var n1:Float = 0;
		var n2:Float = 0; // Noise contributions from the three corners
		
        // Skew the input space to determine which simplex cell we're in
        var s:Float = (xin + yin) * F2; // Hairy factor for 2D
        var i:Int = Math.floor(xin + s);
        var j:Int = Math.floor(yin + s);
        var t:Float = (i + j) * G2;
        var x0:Float = xin - i + t; // The x,y distances from the cell origin, unskewed.
        var y0:Float = yin - j + t;
		
        // For the 2D case, the simplex shape is an equilateral triangle.
        // Determine which simplex we are in.
        var i1:Int = 0;
		var j1:Int = 0; // Offsets for second (middle) corner of simplex in (i,j) coords
        if (x0 > y0) { // lower triangle, XY order: (0,0)->(1,0)->(1,1)
            i1 = 1; 
			j1 = 0;
        } 
		else {    // upper triangle, YX order: (0,0)->(0,1)->(1,1)
            i1 = 0; 
			j1 = 1;
        }
		
        // A step of (1,0) in (i,j) means a step of (1-c,-c) in (x,y), and
        // a step of (0,1) in (i,j) means a step of (-c,1-c) in (x,y), where
        // c = (3-sqrt(3))/6
        var x1 = x0 - i1 + G2; // Offsets for middle corner in (x,y) unskewed coords
        var y1 = y0 - j1 + G2;
        var x2 = x0 - 1 + 2 * G2; // Offsets for last corner in (x,y) unskewed coords
        var y2 = y0 - 1 + 2 * G2;
		
        // Work out the hashed gradient indices of the three simplex corners
        i &= 255;
        j &= 255;
		
        var gi0 = gradP[i + perm[j]];
        var gi1 = gradP[i + i1 + perm[j + j1]];
        var gi2 = gradP[i + 1 + perm[j + 1]];
		
        // Calculate the contribution from the three corners
        var t0 = 0.5 - x0 * x0 - y0 * y0;
        if (t0 < 0) {
            n0 = 0;
        } 
		else {
            t0 *= t0;
            n0 = t0 * t0 * gi0.dot2(x0, y0);  // (x,y) of grad3 used for 2D gradient
        }
		
        var t1 = 0.5 - x1 * x1 - y1 * y1;
        if (t1 < 0) {
            n1 = 0;
        } 
		else {
            t1 *= t1;
            n1 = t1 * t1 * gi1.dot2(x1, y1);
        }
		
        var t2 = 0.5 - x2 * x2 - y2 * y2;
        if (t2 < 0) {
            n2 = 0;
        } 
		else {
            t2 *= t2;
            n2 = t2 * t2 * gi2.dot2(x2, y2);
        }
		
        // Add contributions from each corner to get the final noise value.
        // The result is scaled to return values in the interval [-1,1].
        return 70 * (n0 + n1 + n2);
    }

    // 3D simplex noise
    public function simplex3(xin:Float, yin:Float, zin:Float):Float {
        var n0:Float = 0;
		var n1:Float = 0;
		var n2:Float = 0;
		var n3:Float = 0; // Noise contributions from the four corners
		
        // Skew the input space to determine which simplex cell we're in
        var s:Float = (xin + yin + zin) * F3; // Hairy factor for 2D
        var i:Int = Math.floor(xin + s);
        var j:Int = Math.floor(yin + s);
        var k:Int = Math.floor(zin + s);
		
        var t:Float = (i + j + k) * G3;
        var x0:Float = xin - i + t; // The x,y distances from the cell origin, unskewed.
        var y0:Float = yin - j + t;
        var z0:Float = zin - k + t;
		
        // For the 3D case, the simplex shape is a slightly irregular tetrahedron.
        // Determine which simplex we are in.
        var i1:Int = 0; var j1:Int = 0; var k1:Int = 0; // Offsets for second corner of simplex in (i,j,k) coords
        var i2:Int = 0; var j2:Int = 0; var k2:Int = 0; // Offsets for third corner of simplex in (i,j,k) coords
        if (x0 >= y0) {
            if (y0 >= z0) { 
				i1 = 1; 
				j1 = 0; 
				k1 = 0; 
				i2 = 1; 
				j2 = 1; 
				k2 = 0; 
			}
            else if (x0 >= z0) { 
				i1 = 1; 
				j1 = 0; 
				k1 = 0; 
				i2 = 1; 
				j2 = 0; 
				k2 = 1;
			}
            else { 
				i1 = 0; 
				j1 = 0; 
				k1 = 1; 
				i2 = 1; 
				j2 = 0; 
				k2 = 1;
			}
        } 
		else {
            if (y0 < z0) { 
				i1 = 0; 
				j1 = 0; 
				k1 = 1; 
				i2 = 0; 
				j2 = 1; 
				k2 = 1; 
			}
            else if (x0 < z0) { 
				i1 = 0; 
				j1 = 1; 
				k1 = 0; 
				i2 = 0; 
				j2 = 1; 
				k2 = 1;
			}
            else { 
				i1 = 0; 
				j1 = 1; 
				k1 = 0; 
				i2 = 1; 
				j2 = 1; 
				k2 = 0;
			}
        }
		
        // A step of (1,0,0) in (i,j,k) means a step of (1-c,-c,-c) in (x,y,z),
        // a step of (0,1,0) in (i,j,k) means a step of (-c,1-c,-c) in (x,y,z), and
        // a step of (0,0,1) in (i,j,k) means a step of (-c,-c,1-c) in (x,y,z), where
        // c = 1/6.
        var x1 = x0 - i1 + G3; // Offsets for second corner
        var y1 = y0 - j1 + G3;
        var z1 = z0 - k1 + G3;
		
        var x2 = x0 - i2 + 2 * G3; // Offsets for third corner
        var y2 = y0 - j2 + 2 * G3;
        var z2 = z0 - k2 + 2 * G3;
		
        var x3 = x0 - 1 + 3 * G3; // Offsets for fourth corner
        var y3 = y0 - 1 + 3 * G3;
        var z3 = z0 - 1 + 3 * G3;
		
        // Work out the hashed gradient indices of the four simplex corners
        i &= 255;
        j &= 255;
        k &= 255;
        var gi0 = gradP[i + perm[j + perm[k]]];
        var gi1 = gradP[i + i1 + perm[j + j1 + perm[k + k1]]];
        var gi2 = gradP[i + i2 + perm[j + j2 + perm[k + k2]]];
        var gi3 = gradP[i + 1 + perm[j + 1 + perm[k + 1]]];
		
        // Calculate the contribution from the four corners
        var t0 = 0.6 - x0 * x0 - y0 * y0 - z0 * z0;
        if (t0 < 0) {
            n0 = 0;
        } 
		else {
            t0 *= t0;
            n0 = t0 * t0 * gi0.dot3(x0, y0, z0);  // (x,y) of grad3 used for 2D gradient
        }
		
        var t1 = 0.6 - x1 * x1 - y1 * y1 - z1 * z1;
        if (t1 < 0) {
            n1 = 0;
        } 
		else {
            t1 *= t1;
            n1 = t1 * t1 * gi1.dot3(x1, y1, z1);
        }
		
        var t2 = 0.6 - x2 * x2 - y2 * y2 - z2 * z2;
        if (t2 < 0) {
            n2 = 0;
        } 
		else {
            t2 *= t2;
            n2 = t2 * t2 * gi2.dot3(x2, y2, z2);
        }
		
        var t3 = 0.6 - x3 * x3 - y3 * y3 - z3 * z3;
        if (t3 < 0) {
            n3 = 0;
        } 
		else {
            t3 *= t3;
            n3 = t3 * t3 * gi3.dot3(x3, y3, z3);
        }
		
        // Add contributions from each corner to get the final noise value.
        // The result is scaled to return values in the interval [-1,1].
        return 32 * (n0 + n1 + n2 + n3);
    }
	
	private function n2d(x:Float, y:Float):Float {
		var X:Int = Math.floor(x);
		var Y:Int = Math.floor(y);
		
		x = x - X;
		y = y - Y;
		
		X = X & 255;
		Y = Y & 255;
		
		var n00:Float = gradP[X + perm[Y]].dot2(x, y);
		var n01:Float = gradP[X + perm[Y + 1]].dot2(x, y - 1);
		var n10:Float = gradP[X + 1 + perm[Y]].dot2(x - 1, y);
		var n11:Float = gradP[X + 1 + perm[Y + 1]].dot2(x - 1, y - 1);
		
		var u = fade(x);
		
		var result = lerp(lerp(n00, n10, u), lerp(n01, n11, u), fade(y));
		
		return result / (Math.sqrt(2) * 0.5); 
	}
	
	private function n3d(x:Float, y:Float, z:Float):Float {
		var X:Int = Math.floor(x);
		var Y:Int = Math.floor(y);
		var Z:Int = Math.floor(z);
		
		x = x - X;
		y = y - Y;
		z = z - Z;
		
		X = X & 255;
		Y = Y & 255;
		Z = Z & 255;
		
		var n000:Float = gradP[X + perm[Y + perm[Z]]].dot3(x, y, z);
		var n001:Float = gradP[X + perm[Y + perm[Z + 1]]].dot3(x, y, z - 1);
		var n010:Float = gradP[X + perm[Y + 1 + perm[Z]]].dot3(x, y - 1, z);
		var n011:Float = gradP[X + perm[Y + 1 + perm[Z + 1]]].dot3(x, y - 1, z - 1);
		var n100:Float = gradP[X + 1 + perm[Y + perm[Z]]].dot3(x - 1, y, z);
		var n101:Float = gradP[X + 1 + perm[Y + perm[Z + 1]]].dot3(x - 1, y, z - 1);
		var n110:Float = gradP[X + 1 + perm[Y + 1 + perm[Z]]].dot3(x - 1, y - 1, z);
		var n111:Float = gradP[X + 1 + perm[Y + 1 + perm[Z + 1]]].dot3(x - 1, y - 1, z - 1);
		
		var u:Float = fade(x);
		var v:Float = fade(y);
		var w:Float = fade(z);
		
		var result = lerp(
			lerp(lerp(n000, n100, u), lerp(n001, n101, u), w),
			lerp(lerp(n010, n110, u), lerp(n011, n111, u), w),
			v);
			
		return result / (Math.sqrt(3) * 0.5); 
	}

	/**
	 * 2d Perlin noise.
	 * @return Value in the range [-1, 1].
	 */
	public function noise2d(x:Float, y:Float, octaves:Int = 1, amplitude:Float = 1, persistence:Float = 0.9, lacunarity:Float = 2):Float {
		if (octaves == 1) {
			return amplitude * n2d(x, y);
		}
		
		var sum:Float = 0;
		
		for (i in 0...octaves) {
			sum += amplitude * n2d(x, y);
			amplitude *= persistence;
			
			x *= lacunarity;
			y *= lacunarity;
		}
		
		return sum;
	}

	/**
	 * 3d Perlin noise.
	 * @return Value in the range [-1, 1].
	 */
	public function noise3d(x:Float, y:Float, z:Float, octaves:Int = 1, amplitude:Float = 1, persistence:Float = 0.9, lacunarity:Float = 2):Float {
		if (octaves == 1) {
			return amplitude * n3d(x, y, z);
		}
		
		var sum:Float = 0;

		for (i in 0...octaves) {
			sum += amplitude * n3d(x, y, z);
			amplitude *= persistence;
			
			x *= lacunarity;
			y *= lacunarity;
		}
		
		return sum;
	}

}

class Gradient {
	
	public var x:Float;
	public var y:Float;
	public var z:Float;
	
	
	public function new(x:Float, y:Float, z:Float) {
		this.x = x;
		this.y = y;
		this.z = z;
	}

	public function dot2(x:Float, y:Float):Float {
		return this.x * x + this.y * y;
	}

	public function dot3(x:Float, y:Float, z:Float):Float {
		return this.x * x + this.y * y + this.z * z;
	}
	
}