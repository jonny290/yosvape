#include "Adafruit_MAX31855.h"
#include <LiquidCrystal.h>
#include <PID_v1.h>
#include <phi_big_font.h>
//declare pins
const int thermoCLK = A5;
const int thermoCS = A4;
const int thermoDO = A3;
const int SW_LO = A0;
const int SW_HI = A1;
const int POT = A2;
const int BLK_L = 9;
const int BLK_R = 8;
const int RED_L = 13;
const int RED_R = 12;
const int HEATER = 10;
const int FAN = 11;
//these don't change
const int STAND_BY = 0;
const int PRE_HEAT = 1;
const int GET_BLAZED = 2;
const int COOL_DOWN = 4;
const double cooldownpwm = 0;
const double standbypwm = 32;
const double preheattemp = 340;
const double aggKp=10, aggKi=1, aggKd=0.5;
const double consKp=6, consKi=0.5, consKd=0.5;
//global variables
double avg[10];
double outtemp;
double lasttemp;
double tempreading;
double currenttemp;
unsigned long temptime, screentime, preheattime, cooldowntime, datatime, heatertime, buttontime, splashtime,logtime, nowtime, fantime;
int last_blk_l, last_blk_r, last_red_l, last_red_r, last_sw_hi, last_sw_lo;
char inmode;
//vars with a default value
unsigned int knobreading = 0;
unsigned int lowlimit = 340;
unsigned int highlimit = 420;
unsigned int fan_idle = 128;
unsigned int fan_low = 204;
unsigned int fan_high = 255;
unsigned int fanpwm;
double setpoint = 0;
int mode = 0;
double heaterpwm = 0;
//create objects
Adafruit_MAX31855 thermocouple(thermoCLK, thermoCS, thermoDO);
LiquidCrystal lcd(7, 6, 5, 4, 3, 2);
PID yosPID(&currenttemp,&heaterpwm,&setpoint, consKp, consKi, consKd, DIRECT);

void setup() {
	init_big_font(&lcd);
	Serial.begin(9600);
	lcd.begin(20, 2);
	TCCR1B = TCCR1B & 0b11111000 | 0x05; //sets heater PWM frequency to 31 hz
        TCCR2B = TCCR2B & 0b11111000 | 0x06; //sets fan PWM frequency to 244 hz-
	pinMode(10, OUTPUT);
	digitalWrite(10, LOW);
        pinMode(FAN,OUTPUT);
	pinMode(SW_LO,INPUT);
	pinMode(SW_HI,INPUT);
	pinMode(BLK_L,INPUT);
	pinMode(BLK_R,INPUT);
	pinMode(RED_L,INPUT);
	pinMode(RED_R,INPUT);
	delay(2000);
	yosPID.SetSampleTime(200);
	yosPID.SetOutputLimits(0,240);
	standby();
	currenttemp = readtemp();
	lasttemp = currenttemp;
	nowtime = millis();
	temptime = nowtime;
	screentime = nowtime;
	datatime = nowtime;
	heatertime = nowtime;
	buttontime = nowtime;
	splashtime = nowtime;
        logtime = nowtime;
        fantime = nowtime;
	splash();
	modechangescreen();
}

void loop() {
	nowtime = millis();
	if (nowtime - buttontime > 50) //poll button
	{
		buttoncheck();
		buttontime = millis();
	}
	if (nowtime - temptime > 100) //poll sensor
	{
		currenttemp = readtemp();
		temptime = millis();
	}
        if (millis() - fantime > 500) //set fan
        {
                setfan();
                fantime = millis();
        }      
	if (nowtime - screentime > 100) //draw screen
	{
		drawscreen();
		screentime = millis();
	}
	if (mode | 3) { //are we in a PID mode?
		yosPID.Compute();
	}
	if (millis() - heatertime > 100) //set heater
	{
		settemp();
	        analogWrite(HEATER, heaterpwm);
		heatertime = millis();
	}
        if (millis() - logtime > 1000) //send log
	{
		statuslog();
		logtime = millis();
	}
 }


void splash() {
	lcd.clear();
	lcd.setCursor(0,0);
	lcd.print("\"What's in the box?\"");
	delay(3000);
	lcd.clear();
	delay(2000);
	lcd.setCursor(7,1);
	lcd.print("\"Weed.\"");
	delay(3000);
	lcd.clear();
	char yospos[9] = " YOSPOS ";
	char bitch[6] = "BITCH";
	lcd.clear();
	for (int i = 0;i < 7;i++) {
		lcd.setCursor(2+i,0);
		lcd.print(yospos[i]);
		lcd.setCursor(3+i,1);
		lcd.print(yospos[i+1]);
		delay(500);
	}
	lcd.clear();
	delay(1000);
	for(int i = 0; i<10 ;i++) {
		invert_big_font(true);
		render_big_msg("BITCH",0,0);
		delay(300);
		invert_big_font(false);
		render_big_msg("BITCH",0,0);
		delay(300);
	}
	lcd.clear();
}

void drawscreen(){
	if (millis() - splashtime > 2000) 
	{
		if (abs(currenttemp - lasttemp) > 0) {
			if (int(outtemp) > 99)
			{
				render_big_number(int(outtemp),9,0);   
			}
			else
			{
				render_big_number(0,9,0);
				render_big_number(int(outtemp),13,0);     
			}
			lasttemp = currenttemp;
		}
		lcd.setCursor(0,0);
		lcd.print("         ");
		lcd.setCursor(0,1);
		lcd.print("         ");
		lcd.setCursor(0,0);
		lcd.print(map(heaterpwm,0,255,0,100));
		lcd.setCursor(2,0);
		lcd.print("%    F");
		lcd.setCursor(0,1);
		switch (mode) {
		case STAND_BY:
			lcd.print("STBY");
			break;
		case PRE_HEAT:
			lcd.print("WARM");
			break;
		case GET_BLAZED:
			lcd.print("SMOK");
			break;
		case COOL_DOWN:
			lcd.print("COOL");
			break;
		}
		lcd.setCursor(4,0);
		lcd.print(map(analogRead(POT),0,1023,lowlimit,highlimit));
                lcd.setCursor(5,1);
                lcd.print(map(fanpwm,0,255,0,100));
	}
}

void modechangescreen() {
	lcd.clear();
	switch (mode) {
	case STAND_BY:
		lcd.setCursor(3,0);
		lcd.print("Your Navigator");
		lcd.setCursor(4,1);
		lcd.print("has awakened.");
		break;
	case PRE_HEAT:
		lcd.setCursor(3,0);
		lcd.print("Holtzman Drive");
		lcd.setCursor(7,1);
		lcd.print("ONLINE");
		break;
	case GET_BLAZED:
		lcd.setCursor(3,0);
		lcd.print("SPACEFOLDING.");
		break;
	case COOL_DOWN:
		lcd.setCursor(5,0);
		lcd.print("Cooldown.");
		break;
	}
	splashtime = millis();
}

double readtemp() {
	tempreading = thermocouple.readFarenheit();
	outtemp = avg[0];
	for (int i = 0; i < 8; i++) 
	{
		outtemp += avg[i+1];
		avg[i+1] = avg[i]; 
	}
	avg[0] = tempreading;
	outtemp += avg[0];
	outtemp *= 0.1;
	return outtemp;
}

void buttoncheck() {
	knobreading = analogRead(POT);
	int current_red_r = digitalRead(RED_R);
	if (current_red_r == 0 && current_red_r != last_red_r) //right red button has come down since we last checked
	{
		delay(10);
		if (digitalRead(RED_R) == current_red_r) {      
			modecycle();    
		}
	}
	last_red_r = current_red_r;
	int current_red_l = digitalRead(RED_L);
	if (current_red_l == 0 && current_red_l != last_red_l) //right red button has come down since we last checked
	{
		delay(10);
		if (digitalRead(RED_L) == current_red_l) {      
			modecycle();    //sdfdsfdsfsf
		}
	}
	last_red_l = current_red_l;
	int current_blk_r = digitalRead(BLK_R);
	if (current_blk_r == 0 && current_blk_r != last_blk_r) //right blk button has come down since we last checked
	{
		delay(10);
		if (digitalRead(RED_R) == current_blk_r) {      
			modecycle();    
		}
	}
	last_blk_r = current_blk_r;
	int current_blk_l = digitalRead(BLK_L);
	if (current_blk_l == 0 && current_blk_l != last_blk_l) //right blk button has come down since we last checked
	{
		delay(10);
		if (digitalRead(BLK_L) == current_blk_l) {      
			modecycle();    
		}
	}
	last_blk_l = current_blk_l;


}

void modecycle() {
	switch (mode) {
	case STAND_BY:
		mode = PRE_HEAT;
		
		preheat();
		break;
	case PRE_HEAT:
		mode = GET_BLAZED;
		
		break;
	case GET_BLAZED:
		mode = COOL_DOWN;
		
		cooldown();
		break;
	case COOL_DOWN:
		mode = STAND_BY;
		
		standby();
		break;    
	}
	modechangescreen();

}  

void settemp() {
	switch (mode) {
	case STAND_BY:
		heaterpwm = standbypwm;
		break;
	case PRE_HEAT:
		setpoint = preheattemp;
		break;
	case GET_BLAZED:
		setpoint = map(knobreading,0,1023,lowlimit,highlimit);
		break;
	case COOL_DOWN:
		heaterpwm = cooldownpwm;
		break;
	}

}

void setfan() {
	switch (mode) {
	case STAND_BY:
                fanpwm = fan_idle;
		break;
	case PRE_HEAT:
              if (millis() - preheattime < 60000) {
               fanpwm = fan_high; 
              }else  if (millis() - preheattime > 110000){
               fanpwm = fan_low; 
              } else {
               fanpwm = 255 - ((millis() - preheattime - 60000) / 1000  ) ;
              }
		break;
	case GET_BLAZED:
                if (digitalRead(SW_LO) == 1) //right red button has come down since we last checked
	{
			fanpwm = fan_low;    
	}
	
	else if (digitalRead(SW_HI) == 1) //right red button has come down since we last checked
	{
			fanpwm = fan_high;    
	}
        else  {
              if (outtemp > 400) {
                  fanpwm = fan_high;
              } else {
                fanpwm = fan_low;
              }
                
        }
		break;
	case COOL_DOWN:
             if (outtemp > 250) {
             fanpwm = fan_high;  
             } else if (outtemp > 150) {
              fanpwm = fan_low; 
             } else {
               fanpwm = fan_idle;
             }
		break;
	}
        analogWrite(FAN, fanpwm);
        	

}




void standby() {
	yosPID.SetMode(MANUAL);
	heaterpwm = standbypwm;
}

void preheat(){
	yosPID.SetMode(AUTOMATIC);
	yosPID.SetTunings(consKp, consKi, consKd);
	setpoint = preheattemp;
        preheattime = millis();
}

void getblazed(){
	yosPID.SetMode(AUTOMATIC);
	yosPID.SetTunings(aggKp, aggKi, aggKd);
}

void cooldown() {
	yosPID.SetMode(MANUAL);
	heaterpwm = cooldownpwm;
        cooldowntime = millis();
}

void statuslog() {
unsigned long nowtime = millis() / 1000;
Serial.print(nowtime);	
Serial.print(",");
	switch (mode) {
		case STAND_BY:
			Serial.print("S");
			break;
		case PRE_HEAT:
			Serial.print("P");



			break;
		case GET_BLAZED:
			Serial.print("G");
			break;
		case COOL_DOWN:
			Serial.print("C");
			break;
	}
	Serial.print(",");
	Serial.print(int(heaterpwm));
	Serial.print(",");
	Serial.print(int(currenttemp));
	Serial.print(",");
	Serial.print(int(setpoint));
	Serial.print("\n");
if (Serial.available() > 0) {
   inmode = Serial.read();
   switch (inmode) {
   case 'C':
    mode = COOL_DOWN;
    modecycle();
    break;
  case 'S':
    mode = STAND_BY;
    modecycle();
    break;
  case 'P':
    mode = PRE_HEAT;
    modecycle();
    break;
  case 'G':
    mode = GET_BLAZED;
     modecycle();
    break;   
   }
}
}

