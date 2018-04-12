//Returns a vector normal to the plane of the target's orbit.
function GetOrbitNormal
{
	parameter tgt.
	local v1 is tgt:prograde:vector.
	local v2 is tgt:position - ship:body:position.
	local normal_vector is vcrs(v1, v2).
	return normal_vector:normalized.
}

//Calculates the points of intersection between an orbital
//plane and the surface at a given latitude.
//will return an empty list if no solution
function CalcIntersection
{
	parameter normal_vector, latitude.
	local int_points to list().
	local Y is sin(latitude) * body:radius.
	local R is cos(latitude) * body:radius.
	local F is normal_vector:X.
	local G is normal_vector:Z.
	local H is normal_vector:Y.
	local A is (1+(F^2/G^2)).
	local B is (2*H*Y*F/G^2).
	local C is (H^2*Y^2/G^2)-R^2.
	if not (G = 0 or 4*A*C > B^2)
	{
		local x1 is (-B + sqrt(B^2 - 4*A*C))/(2*A).
		local x2 is (-B - sqrt(B^2 - 4*A*C))/(2*A).
		local z1 is (-H*Y - F*x1)/G.
		local z2 is (-H*Y - F*x2)/G.
		local v1 is V(x1, Y, z1).
		local v2 is V(x2, Y, z2).
		int_points:add(v1).
		int_points:add(v2).
	}
	return int_points.
}

//returns time to nearest launch window for rendezvous in seconds.
function TimeToLaunchWindow
{
	parameter tgt_normal, lat. 
		//making latitude a parameter because 
		//canaveral to the moon is just barely out of range
		//when I have time, I'll find the point of closest approach instead
		
	local int_points to CalcIntersection(tgt_normal, lat).
	local v1 to vcrs(V(0,1,0), -ship:body:position).
	local v2 to vcrs(V(0,1,0), int_points[0]).
	local v3 to vcrs(V(0,1,0), int_points[1]).
	local v4 to vcrs(V(0,1,0), v1).
	
	local angle1 is vang(v1, v2).
	if vang(v4, v2) < 90
	{
		set angle1 to 360 - angle1.
	}
	local angle2 is vang(v1, v3).
	if vang(v4, v3) < 90
	{
		set angle2 to 360 - angle2.
	}
	
	local intersect_eta is ship:body:rotationperiod / 360 * min(angle1, angle2).
	return intersect_eta.
}

function GetLaunchGuidanceVector
{
	parameter tgt_normal.
	local v1 is vcrs(up:vector, tgt_normal).
	return vxcl(up:vector, v1).	
}

function GetLaunchHeading
{
	parameter tgt_normal.
	local v1 is GetLaunchGuidanceVector(tgt_normal).
	local angle is vang(v1, north:vector).
	if vang(v1, heading(90, 0):vector) > 90
	{
		set angle to 360 - angle.
	}
	return angle.
}

function GetCurrentTgtAngle
{
	parameter tgt.
	local orbit_normal is GetOrbitNormal(tgt).
	local v1 is vxcl(orbit_normal, tgt:position-ship:body:position).
	local v2 is vxcl (orbit_normal, -ship:body:position).
	local v3 is vxcl (orbit_normal, vcrs(north:vector, up:vector)).
	local angle is vang(v1, v2).
	if vang(v1,v3) < 90
	{
		set angle to 360 - angle.
	}
	return angle.
}