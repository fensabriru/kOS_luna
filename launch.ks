parameter dsd_alt, pitchover_angle, normal_vector is north:vector.

switch to 0. 

run once attitude.
run once pid.
run once rendezvous.
run once launch_lib.

function RollProgram
{
	local error is 0.
	if altitude > 1000 or verticalspeed > 10
	{
		if adi_pitch() > 85
		{
			set error to GetLaunchHeading(normal_vector) - adi_hdg().
			if error < -180
			{
				set error to error + 360.
			}
			if error > 180
			{
				set error to error - 360.
			}
		}
		else
		{
			set error to adi_roll().
		}
	}
	return error.
}

function YawProgram
{
	parameter err_func.
	local steer_vector is up:vector.
	if altitude < 30000
	{
		if altitude > 1000 or verticalspeed > 50
		{
			set steer_vector to heading(GetLaunchHeading(normal_vector), pitchover_angle):vector.
		}
		if altitude > 1000 or verticalspeed > 120
		{
			set steer_vector to ship:srfprograde:vector.
		}
	}
	else
	{
		set steer_vector to heading(GetLaunchHeading(normal_vector), err_func()):vector.
	}
	return GetYawError(steer_vector).
}

function PitchProgram
{
	parameter err_func.
	local steer_vector is up:vector.
	if altitude < 30000
	{ 
		if altitude > 1000 or verticalspeed > 50
		{
			set steer_vector to heading(GetLaunchHeading(normal_vector), pitchover_angle):vector.
		}
		
		if altitude > 1000 or verticalspeed > 150
		{
			set steer_vector to ship:srfprograde:vector.
		}	
	}
	else
	{
		set steer_vector to heading(GetLaunchHeading(normal_vector), err_func()):vector.
	}
	return GetPitchError(steer_vector).
}

lock throttle to 1.
print "Executing launch script".
LaunchCountdown().

//PID controller for steering angle
local PitchAnglePID is PIDInit(90, 0, 200, 1, pitch_angle_error_boost@, 10, 90, -90).
local pitch_angle_error is PID@:bind(PitchAnglePID).

//PID controllers for roll, pitch, and yaw
local RollPID is PIDInit(0.04, 0.0001, 0.1, 0, RollProgram@).
local YawPID is PIDInit(0.2, 0.001, 0.14, 0, YawProgram@:bind(pitch_angle_error)).
local PitchPID is PIDInit(0.2, 0.001, 0.14, 0, PitchProgram@:bind(pitch_angle_error)).

//turn on the integral gain after we pass our target to prevent overshoot
//and integral windup
when apoapsis > dsd_alt then 
{
	set PitchAnglePID[1] to 1.
	set PitchAnglePID[7] to 0.
}

//PID settings for circularization
when altitude > 1000 and eta:apoapsis < 2 then	
{
	set PitchAnglePID[0] to 1.
	set PitchAnglePID[1] to 0.01.
	set PitchAnglePID[2] to 1.
	set PitchAnglePID[3] to 0.
	set PitchAnglePID[7] to 0.
	set PitchAnglePID[8] to 500.
	set PitchAnglePID[4] to pitch_angle_error_circularize@.
}

//turn down pid parameters in the upper atmosphere due to higher TWR
when altitude > 30000 then 
{
	set RollPID[0] to 0.01.
	set RollPID[2] to 0.04.
	set YawPID[0] to 0.02.
	set YawPID[2] to 0.03.
	set PitchPID[0] to 0.02.
	set PitchPID[2] to 0.03.
}

//jettison fairings
local fairings is GetFairings().
when altitude > 100000 then
{
	JettisonFairings(fairings).
}

until OrbitAchieved(dsd_alt)
{
	set ship:control:roll to PID(RollPID).
	set ship:control:yaw to PID(YawPID).
	set ship:control:pitch to PID(PitchPID).
	if maxthrust = 0 and not stage:number = 0
	{
		NextStage().
	}
		for booster in SHIP:PARTSTAGGED("booster") {
 		if booster:HASSUFFIX("FLAMEOUT") and booster:FLAMEOUT {
			STAGE.
		}
	}
}
ShutdownEngines().
