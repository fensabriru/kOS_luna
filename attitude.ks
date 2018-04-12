function adi_pitch
{
	set pitchAngle to 90 - vang(up:vector, ship:facing:vector).
	return pitchAngle.
}

function adi_roll
{
	if adi_pitch() > 85 or adi_pitch() < -85
	{
		set RollAngle to 0.
	}
	else 
	{
		set v1 to vcrs(up:vector, ship:facing:vector).
		set rollAngle to vang(v1, ship:facing:starvector).
		if vang(ship:facing:upvector, v1) > 90
		{
			set rollAngle to -1 * rollAngle.
		}
	}
	return rollAngle.
}

function adi_hdg
{
	if adi_pitch() > 85
	{
		set v1 to vcrs(ship:facing:starvector, up:vector).
		set v2 to vcrs(up:vector, v1).
		set hdg to vang(v1, north:vector).
		if vang(v2, north:vector) < 90
		{
			set hdg to 360 - hdg.
		}
	}
	else if adi_pitch() < -85
	{
		set v1 to vcrs(up:vector, ship:facing:starvector).
		set v2 to vcrs(up:vector, v1).		
		set hdg to vang(v1, north:vector).
		if vang(v2, north:vector) < 90
		{
			set hdg to 360 - hdg.
		}		
	}
	else
	{
		set v1 to vcrs(up:vector, ship:facing:vector).
		set v2 to vcrs(v1, up:vector).
		set hdg to vang(v2, north:vector).
		if vang(v1, north:vector) < 90
		{
			set hdg to 360 - hdg.
		}
	}
	return hdg.
}