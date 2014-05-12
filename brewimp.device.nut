// assign hardware.pin5 to a global variable
therm <- hardware.pin8;
therm2 <- hardware.pin9;
// configure pin5 to be an ANALOG_IN
therm.configure(ANALOG_IN);
therm2.configure(ANALOG_IN);

// these constants are particular to the thermistor we're using
// check your datasheet for what values you should be using
const b_therm = 3977.0;
const t0_therm = 298.15;
 
// the resistor in the circuit (10KΩ)
const R2 = 10000.0;

//set relay variables to off
relaystrikeState <- false;
relaymashState <- false;

function MashTemp_F() {
  local Vin = hardware.voltage();
 
  local Vout = Vin * therm.read() / 65535.0;
  local R_Therm = (R2*Vin / Vout) - R2;
  
  local ln_therm = math.log(10000.0 / R_Therm);
  local temp_K = (t0_therm * b_therm) / (b_therm - t0_therm*ln_therm);
  
  local temp_C = temp_K - 273.15;
  local mashtemp_F = temp_C * 9.0 / 5.0 + 32.0;
  
  return mashtemp_F;
}
function StrikeTemp_F() {
  local Vin = hardware.voltage();
 
  local Vout = Vin * therm2.read() / 65535.0;
  local R_Therm = (R2*Vin / Vout) - R2;
  
  local ln_therm = math.log(10000.0 / R_Therm);
  local temp_K = (t0_therm * b_therm) / (b_therm - t0_therm*ln_therm);
  
  local temp_C = temp_K - 273.15;
  local striketemp_F = temp_C * 9.0 / 5.0 + 32.0;
  
  return striketemp_F;
}

function startWarmup() {
  // Get and log Fahrenheit temperature
	local mashtemp = MashTemp_F();
	local striketemp = StrikeTemp_F();
	server.log(mashtemp + " F");
	server.log(striketemp + " F");
	targetMashTemp <- 163; //Target Mash Temperature
	targetStrikeTemp <- 168; //Target Strike Temperature
	targeHyst <- 0.2; //Hysteresis to avoid Relay jitter
	
	if (striketemp < (targetStrikeTemp-targeHyst))  //Turn on Strike heat
	{
		if (!relaystrikeState)
		{
			relaystrikeState = true;
			server.log("Strike Relay Off");
		}
	}
		else if (striketemp > (targetStrikeTemp-targeHyst))  //Turn off Strike heat
	{
		if (relaystrikeState = false);
		server.log("Strike Relay On");
		}
		
	if (mashtemp < (targetMashTemp-targeHyst))  //Turn on Mash circulation pump
	{
		if (!relaymashState)
		{
			relaymashState = true;
			server.log("Mash Relay Off");
		}
	}
		else if (mashtemp > (targetMashTemp-targeHyst))  //Turn off Strike heat
	{
		if (relaymashtate = false);
		server.log("Mash Relay On");
		}
		
	mashrelay <- hardware.pinB;
	strikerelay <- hardware.pinC;
	// configure LED pin for DIGITAL_OUTPUT
	mashrelay.configure(DIGITAL_OUT);
	strikerelay.configure(DIGITAL_OUT);
	hardware.pinB.write(relaystrikeState?1:0);
	hardware.pinC.write(relaymashState?1:0);

		
	// wakeup in 5 seconds and read the value again:
	imp.wakeup(5.0, startWarmup);
}
 
startWarmup()