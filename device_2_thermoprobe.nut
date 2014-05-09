// Read data from MAX31855 chip on Adafruit breakout boards
// This uses an IMP MODULE with 12 pins! If you use an Imp card
// you will need to change the pin configuration.

//Configure Pins
// Configure the UART port
port0 <- hardware.uart6E;
port0.configure(9600, 8, PARITY_NONE, 1, NO_CTSRTS);
hardware.spi257.configure(MSB_FIRST | CLOCK_IDLE_LOW , 1000);
hardware.pinD.configure(DIGITAL_OUT); //chip select
hardware.pin7.configure(DIGITAL_OUT); //chip select

probe1temp <- 0;
probe2temp <- 0;
probe1reftemp <- 0;
probe2reftemp <- 0;
//farenheit <- 0;
//celcius <- 0;
probe1 <- 0;
probe2 <- 0;
probedata <- {};
trigger1Min <- -1;
trigger1Max <- 90;
trigger2Min <- -1;
trigger2Max <- 90;
chargeState <- "N";
signal <- "unset";
bars <- [0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0];

agent.on("Trigger1Min", function(data) {
  //do something with data.. maybe write out to pins or something
  trigger1Min = (data.trigger1min);
  server.log("trigger1min set to " + data.trigger1min);
});
agent.on("Trigger1Max", function(data) {
  //do something with data.. maybe write out to pins or something
  trigger1Max = (data.trigger1max);
  server.log("trigger1max set to " + data.trigger1max);
});
agent.on("Trigger2Min", function(data) {
  //do something with data.. maybe write out to pins or something
  trigger2Min = (data.trigger2min);
  server.log("trigger1min set to " + data.trigger2min);
});
agent.on("Trigger2Max", function(data) {
  //do something with data.. maybe write out to pins or something
  trigger2Max = (data.trigger2max);
  server.log("trigger2max set to " + data.trigger2max);
});

function readChip257(temp32){
        
    local tc = 0;
    if ((temp32[1] & 1) ==1){
    	local errorcode = (temp32[3] & 7);// 7 is B00000111
		local TCErrCount = 0;
		if (errorcode>0){
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
			    break;
			}
			TCErrCount+=1;
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
		local lowbyte = (temp32[1]>>2);		
		tc = highbyte | lowbyte; //now have right-justifed 14 bits but the 14th digit is the sign
        tc = ((tc<<18)>>18); 
        local refhighbyte = (temp32[2]<<2);
        local reflowbyte = (temp32[3]>>4);
        local rtc = refhighbyte | reflowbyte;
        rtc = ((rtc<<18)>>18);
        local refcelcius = (1.0*rtc/4.0);
        local reffarenheit = (((refcelcius*9)/5)+32);
		local celcius = (1.0* tc/4.0);
        local farenheit = (((celcius*9)/5)+32);
        //server.log(farenheit);
        local data = {"reftemp":reffarenheit, "temp":farenheit};
        return data;
	}
}

// Read Probe 1
function probe1() {
    hardware.pinD.write(0); //pull CS low to start the transmission of temp data  
    imp.sleep(0.05);
    local temp32=hardware.spi257.readblob(4);//SPI read is totally completed here
    hardware.pinD.write(1); // pull CS high
    local probe1data = readChip257(temp32);
    probe1temp = probe1data.temp.tofloat();
    probe1temp = probe1temp-0;                    //Use this to calibrate your thermocouple
    probe1reftemp = probe1data.reftemp.tofloat();


    if (probe1temp >= trigger1Max.tofloat()) {
        agent.send("Probe1", probe1temp);
    }
    else if (probe1temp <= trigger1Min.tofloat()) {
        agent.send("Probe1", probe1temp);
    }
}
// Read Probe 2
function probe2() {   
    hardware.pin7.write(0);
    imp.sleep(0.05);
    local temp32=hardware.spi257.readblob(4);
    hardware.pin7.write(1);
    local probe2data = readChip257(temp32);
    probe2temp = probe2data.temp.tofloat();
    probe2temp = probe2temp-0;                   //Use this to calibrate your thermocouple
    probe2reftemp = probe2data.reftemp.tofloat();

    //server.log("Probe 2 Reference Temperature: " + probe2reftemp + "ºF");
    //server.log("Probe 2 Probe Temperature: " + probe2temp + "ºF");
    if (probe2temp >= trigger2Max.tofloat()) {
        agent.send("Probe2", probe2temp);
    }
    else if (probe2temp <= trigger2Min.tofloat()) {
        agent.send("Probe2", probe2temp);
    } 
}

//Disconnect before taking the first reading on cold boot - implicit server.disconnect()
if (server.isconnected()) {
    server.expectonlinein(30);
}
degree <- [0xe,0xa,0xe,0x0,0x0,0x0,0x0, 0x0];
screen <- SerLCD(port0);        //instantiate a screen object
screen.createChar(1, degree);

hardware.pin7.write(1);         //set chip select pin high
hardware.pinD.write(1);         //set chip select pin high    

//Take first temperature readings
probe1();
probe2();

server.log("Probe:1 | Probe:2"); //Bring WiFi back up
local probetemps = {"probe1temp" : probe1temp , "probe1reftemp" : probe1reftemp, "probe2temp" : probe2temp, "probe2reftemp" : probe2reftemp};

agent.send("Xively", probetemps)
//ReportRSSI();

imp.onidle(function() {
    server.expectonlinein(12);
    imp.deepsleepfor(11);
});