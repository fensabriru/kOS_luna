//Setup a list with all our PID parameters and data members
function PIDInit
{
	parameter pGain.
	parameter iGain.
	parameter dGain.
	parameter setPoint.
	parameter errorFunc.
	parameter i_limit is 0.
	parameter u_limit is 0.
	parameter l_limit is 0.
	
	set pid_params to list().
	pid_params:add(pGain).  	//0 proportional gain
	pid_params:add(iGain).  	//1 integral gain
	pid_params:add(dGain).  	//2 derivative gain
	pid_params:add(setPoint).	//3 set point
	pid_params:add(errorFunc).	//4 error function delegate
	pid_params:add(0). 			//5 timestamp for computing derivative
	pid_params:add(0). 			//6 old error
	pid_params:add(0). 			//7 integral sum
	pid_params:add(i_limit). 	//8 integral limit
	pid_params:add(u_limit). 	//9 upper error limit
	pid_params:add(l_limit). 	//10 lower error limit
	
	return pid_params.
}

//PID control loop
function PID
{
	parameter pid_params.
	if not pid_params:length = 8
	{
		print "PID: invalid parameters".
		return.
	}
	
	local timestamp is time:seconds().
	local deltaT is timestamp - pid_params[5].	//deltaT = current time - old time

	if pid_params[5] = 0 or deltaT = 0
	{
		set pid_params[5] to timestamp.
		wait 0.001.
		set timestamp to time:seconds().
		set deltaT to timestamp - pid_params[5].
	}
	
	local error is pid_params[3] - pid_params[4](). //error = setpoint - process variable
	set pid_params[7] to pid_params[7] + (error * deltaT). //update integral
	if not (pid_params[8] = 0)
	{
		if pid_params[7] > pid_params[8]
		{
			set pid_params[7] to pid_params[8].
		}
			else if pid_params[7] < -pid_params[8]
		{
			set pid_params[7] to -pid_params[8].
		}
	}
	local pOut is pid_params[0] * error.
	local iOut is pid_params[1] * pid_params[7].
	local dOut is pid_params[2] * (error - pid_params[6]) / deltaT.
	local output is pOut + iOut + dOut.
	set pid_params[5] to timestamp.
	set pid_params[6] to error.
	if output > pid_params[9] and not (pid_params[9] = 0)
	{
		set output to pid_params[9].
	}
	if output < pid_params[10] and not (pid_params[10] = 0)
	{
		set output to pid_params[10].
	}
	return output.
}