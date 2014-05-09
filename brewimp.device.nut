//Configure Pins
hardware.spi189.configure(MSB_FIRST | CLOCK_IDLE_LOW , 1000);
hardware.pin8.configure(DIGITAL_OUT); //chip select
hardware.pinD.configure(DIGITAL_OUT); //chip select
// assign mash and strike pins to a global variable
mash <- hardware.pinB;
strike <- hardware.pinC;
// configure LED pin for DIGITAL_OUTPUT
mash.configure(DIGITAL_OUT);
strike.configure(DIGITAL_OUT);

// global variable to track current state of Mash and strike pins
state <- 1;
// set Relay's pin to initial value (0 = on 1 = off)
mash.write(state);
strike.write(state);
// define variables
temp32 <- 0;
farenheit <- 0;
celcius <- 0;

//Define functions
function readMash189(){
        //Get SPI data 
    hardware.pin8.write(0); //pull CS low to start the transmission of temp data  
      //0[31..24],1[23..16],2[15..8],3[7..0]
        temp32=hardware.spi189.readblob(4);//SPI read is totally completed here
    hardware.pin8.write(1); // pull CS high
        // Begin converting Binary data for chip 1
    local tc = 0;
    if ((temp32[1] & 1) ==1){
        //Error bit is set
		local errorcode = (temp32[3] & 7);// 7 is B00000111
		local TCErrCount = 0;
		if (errorcode>0){
			//One or more of the three error bits is set
			//B00000001 open circuit
			//B00000010 short to ground
			//B00000100 short to VCC
			switch (errorcode){            
            case 1:
                server.log("TC open circuit");
			    break;
			case 2:         
                server.log("TC short to ground");
			    break;           
            case 3:          
                server.log("TC open circuit and short to ground")
                break;
			case 4:         
                server.log("TC short to VCC");
			    break;
			default:           
                //Bad coding error if you get here
			    break;
			}
			TCErrCount+=1;
			//if there is a fault return this number, or another number of your choice
			 tc= 67108864; 
		}
	    else
        {
             server.log("error in SPI read");
        }      
	} 
	else //No Error code raised
	{
		local highbyte =(temp32[0]<<6); //move 8 bits to the left 6 places
		local lowbyte = (temp32[1]>>2);	//move to the right two places	
		tc = highbyte | lowbyte; //now have right-justifed 14 bits but the 14th digit is the sign    
		//Shifting the bits to make sure negative numbers are handled
        //Get the sign indicator into position 31 of the signed 32-bit integer
        //Then, scale the number back down, the right-shift operator of squirrel/impOS
        tc = ((tc<<18)>>18); 
        // Convert to Celcius
		    celcius = (1.0* tc/4.0);
        // Convert to Farenheit
        farenheit = (((celcius*9)/5)+32);
        server.log(celcius + "°C");
        server.log(farenheit + "°F");
        //agent.send("Xively", farenheit);
        imp.wakeup(10, readMash189); //Wakeup every 10 second and read data.
	}
}

function readStrike189(){
        //Get SPI data 
    hardware.pinD.write(0); //pull CS low to start the transmission of temp data  
      //0[31..24],1[23..16],2[15..8],3[7..0]
        temp32=hardware.spi189.readblob(4);//SPI read is totally completed here
    hardware.pinD.write(1); // pull CS high
        // Begin converting Binary data for chip 1
    local tc = 0;
    if ((temp32[1] & 1) ==1){
        //Error bit is set
		local errorcode = (temp32[3] & 7);// 7 is B00000111
		local TCErrCount = 0;
		if (errorcode>0){
			//One or more of the three error bits is set
			//B00000001 open circuit
			//B00000010 short to ground
			//B00000100 short to VCC
			switch (errorcode){            
            case 1:
                server.log("TC open circuit");
			    break;
			case 2:         
                server.log("TC short to ground");
			    break;           
            case 3:          
                server.log("TC open circuit and short to ground")
                break;
			case 4:         
                server.log("TC short to VCC");
			    break;
			default:           
                //Bad coding error if you get here
			    break;
			}
			TCErrCount+=1;
			//if there is a fault return this number, or another number of your choice
			 tc= 67108864; 
		}
	    else
        {
             server.log("error in SPI read");
        }      
	} 
	else //No Error code raised
	{
		local highbyte =(temp32[0]<<6); //move 8 bits to the left 6 places
		local lowbyte = (temp32[1]>>2);	//move to the right two places	
		tc = highbyte | lowbyte; //now have right-justifed 14 bits but the 14th digit is the sign    
		//Shifting the bits to make sure negative numbers are handled
        //Get the sign indicator into position 31 of the signed 32-bit integer
        //Then, scale the number back down, the right-shift operator of squirrel/impOS
        tc = ((tc<<18)>>18); 
        // Convert to Celcius
		    celcius = (1.0* tc/4.0);
        // Convert to Farenheit
        farenheit = (((celcius*9)/5)+32);
        server.log(celcius + "°C");
        server.log(farenheit + "°F");
        //agent.send("Xively", farenheit);
        imp.wakeup(10, readStrike189); //Wakeup every 10 second and read data.
	}
}

// function to turn on Mash
function mashon() {
  // flip the state variable
  if (state == 1) {
    state = 0;
  }
  mash.write(state);         // turn on mash heat
  imp.wakeup(0.1, mashon);
}

// function to turn off Mash
function mashoff() {
  // flip the state variable
  if (state == 0) {
    state = 1;
  }
  mash.write(state);         // turn on mash heat
  imp.wakeup(0.1, mashoff);
}

// function to turn on Strike
function strikeon() {
  // flip the state variable
  if (state == 1) {
    state = 0;
  }
  strike.write(state);         // turn on mash heat
  imp.wakeup(0.1, strikeon);
}

// function to turn off Strike
function strikeoff() {
  // flip the state variable
  if (state == 0) {
    state = 1;
  }
  strike.write(state);         // turn on mash heat
  imp.wakeup(0.1, strikeoff);
}

//Begin executing program
hardware.pin8.write(1); //Set the Chip Select pin to HIGH prior to SPI read
readMash189();          //Read SPI data
hardware.pinD.write(1); //Set the Chip Select pin to HIGH prior to SPI read
readStrike189();          //Read SPI data

mashon(); //turn mash on
strikeon(); //turn mash on

if 