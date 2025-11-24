#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <SoftwareSerial.h>
#include <NewPing.h>

#define TURBID_PIN A0
#define YL69_PIN A1
#define OPTIONAL_LEVEL_PIN A2
#define RES_TRIG 2
#define RES_ECHO 3
#define HOUSE_TRIG 4
#define HOUSE_ECHO 5
#define RELAY_PUMP1 6
#define RELAY_PUMP2 7
#define RELAY_PUMP3 8
#define BUZZER_PIN 9
#define BUTTON_ACK 10
#define ESP_RX 11
#define ESP_TX 12

// Thresholds 
int turbidity_clean_threshold = 400;
int yl69_filter_full_threshold = 1200;

int optional_threshold_analog = 90;

int res_dist_empty = 10;   
int res_dist_full  = 5.5;  

int house_dist_empty = 9;  
int house_dist_full  = 5;
#define MAX_DISTANCE 15  

// Initialize objects
LiquidCrystal_I2C lcd(0x27, 16, 2);
SoftwareSerial EspSerial(ESP_RX, ESP_TX);  
NewPing sonarReservoir(RES_TRIG, RES_ECHO, MAX_DISTANCE);
NewPing sonarHouse(HOUSE_TRIG, HOUSE_ECHO, MAX_DISTANCE);

// Global variables
int storedTurbidity = 0;
bool storedTurbidityValid = false;
bool buzzerOn = false;
bool notifSentEmpty = false;
bool notifResEmptyWhileFilling = false;
unsigned long lastSend = 0;
const unsigned long SEND_INTERVAL = 1500;  

void stopPump(int pin) { digitalWrite(pin, HIGH); } 
void startPump(int pin) { digitalWrite(pin, LOW); }

int mapLevelPercent(long measured, long fullDist, long emptyDist) {
  if (measured >= emptyDist) return 0;
  if (measured <= fullDist) return 100;
  float pct = (float)(emptyDist - measured) / (emptyDist - fullDist) * 100.0;
  return constrain((int)pct, 0, 100);
}


void buzzerOnFn() {
  if (!buzzerOn) {
    tone(BUZZER_PIN, 2000);
    buzzerOn = true;
    EspSerial.println("BUZZER:ON");
  }
}
void buzzerOffFn() {
  if (buzzerOn) {
    noTone(BUZZER_PIN);
    buzzerOn = false;
    EspSerial.println("BUZZER:OFF");
  }
}


void setup() {
  Serial.begin(9600);
  EspSerial.begin(9600);  

  pinMode(RELAY_PUMP1, OUTPUT);
  pinMode(RELAY_PUMP2, OUTPUT);
  pinMode(RELAY_PUMP3, OUTPUT);
  stopPump(RELAY_PUMP1);
  stopPump(RELAY_PUMP2);
  stopPump(RELAY_PUMP3);

  pinMode(BUZZER_PIN, OUTPUT);
  digitalWrite(BUZZER_PIN, LOW);
  pinMode(BUTTON_ACK, INPUT_PULLUP);

  lcd.init();
  lcd.backlight();
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Smart Water Sys");
  lcd.setCursor(0, 1);
  lcd.print("Starting...");
  delay(1500);

  Serial.println("Arduino Setup Complete");
}

void loop() {

  long resDist = sonarReservoir.ping_cm();
  long houseDist = sonarHouse.ping_cm();
  int resLevel = mapLevelPercent(resDist, res_dist_full, res_dist_empty);
  int houseLevel = mapLevelPercent(houseDist, house_dist_full, house_dist_empty);
  int ylVal = analogRead(YL69_PIN);


  int optionalAnalog = analogRead(OPTIONAL_LEVEL_PIN);
  int optionalPercent = 0;
  if (optionalAnalog >= optional_threshold_analog) {
    optionalPercent = map(optionalAnalog, optional_threshold_analog, 160, 0, 100);
    optionalPercent = constrain(optionalPercent, 0, 100);
  } else {
    optionalPercent = 0;
  }
  bool optionalHasWater = (optionalPercent > 0);

  
  int turbVal;
  if (resLevel >= 15) {
    turbVal = analogRead(TURBID_PIN);
    storedTurbidity = turbVal;
    storedTurbidityValid = true;
  } else if (storedTurbidityValid) {
    turbVal = storedTurbidity;
  } else {
    turbVal = analogRead(TURBID_PIN);  
  }

  bool waterDirty = turbVal < turbidity_clean_threshold;
  bool filterFull = ylVal > yl69_filter_full_threshold;
  bool reservoirHasEnough = resLevel > 10;
  bool houseNeedsFill = houseLevel < 90;

  if (reservoirHasEnough || optionalHasWater) {
    buzzerOffFn();
    notifSentEmpty = false;
    notifResEmptyWhileFilling = false;
  }

  // LCD update
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("R:");
  lcd.print(resLevel);
  lcd.print("% H:");
  lcd.print(houseLevel);
  lcd.print("%");

  lcd.setCursor(0, 1);
  lcd.print("O:");
  lcd.print(optionalPercent);
  lcd.print("% ");

  if (!reservoirHasEnough && !optionalHasWater) {
    lcd.print("Tanks Empty!");
  } else if (!reservoirHasEnough) {
    lcd.print("Res Empty!");
  } else {
    lcd.print(waterDirty ? "Turbid " : "Clear  ");
    lcd.print("Filt:");
    lcd.print(filterFull ? "F" : "E");
  }

  // ===================== AUTOMATION LOGIC =====================

  if (waterDirty) {
    if (reservoirHasEnough) {
      if (!filterFull) {
        startPump(RELAY_PUMP2);
        stopPump(RELAY_PUMP1);
        stopPump(RELAY_PUMP3);
        notifSentEmpty = false;
      } else {
        stopPump(RELAY_PUMP2);
        stopPump(RELAY_PUMP1);
        stopPump(RELAY_PUMP3);
      }
    } else {
      stopPump(RELAY_PUMP2);
      stopPump(RELAY_PUMP1);
      if (optionalHasWater && houseNeedsFill) {
        startPump(RELAY_PUMP3);
        EspSerial.println("NOTIF:Using Optional Tank");
        notifSentEmpty = false;
      } else {
        stopPump(RELAY_PUMP3);
        if (!notifSentEmpty) {
          EspSerial.println("NOTIF:Reservoir (dirty) and Optional Tank Empty");
          notifSentEmpty = true;
        }
      }
    }

  } else {
    // CLEAN WATER PATH 
    if (houseNeedsFill) {
      if (reservoirHasEnough) {
        // Clean → send to house (Pump1)
        startPump(RELAY_PUMP1);
        stopPump(RELAY_PUMP2);
        stopPump(RELAY_PUMP3);
        notifSentEmpty = false;
      } else {
        stopPump(RELAY_PUMP1);
        stopPump(RELAY_PUMP2);
        if (optionalHasWater) {
          startPump(RELAY_PUMP3);
          EspSerial.println("NOTIF:Using Optional Tank");
        } else {
          stopPump(RELAY_PUMP3);
          if (!notifSentEmpty) {
            EspSerial.println("NOTIF:Reservoir and Optional Tank Empty");
            notifSentEmpty = true;
          }
        }
      }
    } else {
      stopPump(RELAY_PUMP1);
      stopPump(RELAY_PUMP2);
      stopPump(RELAY_PUMP3);
      notifResEmptyWhileFilling = false;
    }
  }

  if (digitalRead(RELAY_PUMP2) == LOW && filterFull) {
    stopPump(RELAY_PUMP2);
  }

  if (digitalRead(RELAY_PUMP1) == LOW && !reservoirHasEnough) {
    stopPump(RELAY_PUMP1);
    if (optionalHasWater) {
      startPump(RELAY_PUMP3);
      EspSerial.println("NOTIF:Switched to Optional Tank");
    } else if (!notifResEmptyWhileFilling) {
      EspSerial.println("NOTIF:Reservoir Empty While Filling");
      notifResEmptyWhileFilling = true;
    }
  }

  // ================== CENTRALIZED ALARM LOGIC ==================
  bool alarm =
      (!reservoirHasEnough && !optionalHasWater) ||
      (digitalWrite, false, (digitalRead(RELAY_PUMP1) == LOW && !reservoirHasEnough)); 

  alarm =
      (!reservoirHasEnough && !optionalHasWater) ||
      ((digitalRead(RELAY_PUMP1) == LOW) && !reservoirHasEnough);

  if (alarm) {
    buzzerOnFn();
  } else {
    buzzerOffFn();
  }

  if (buzzerOn && digitalRead(BUTTON_ACK) == LOW) {
    buzzerOffFn();
  }

  // Serial Monitor Output 
  Serial.println("=== Sensor Readings ===");
  Serial.print("Reservoir Level: ");
  Serial.print(resLevel);
  Serial.println("%");
  Serial.print("House Tank Level: ");
  Serial.print(houseLevel);
  Serial.println("%");
  Serial.print("Turbidity: ");
  Serial.print(turbVal);
  Serial.println(" (raw)");
  Serial.print("YL-69 Filter: ");
  Serial.print(ylVal);
  Serial.println(" (raw)");
  Serial.print("Optional Tank: ");
  Serial.print(optionalAnalog);
  Serial.print(" (raw) -> ");
  Serial.print(optionalPercent);
  Serial.println("%");
  Serial.print("Pump 1: ");
  Serial.println(digitalRead(RELAY_PUMP1) == LOW ? "ON" : "OFF");
  Serial.print("Pump 2: ");
  Serial.println(digitalRead(RELAY_PUMP2) == LOW ? "ON" : "OFF");
  Serial.print("Pump 3: ");
  Serial.println(digitalRead(RELAY_PUMP3) == LOW ? "ON" : "OFF");
  Serial.println();

  // Send to ESP8266
  if (millis() - lastSend >= SEND_INTERVAL) {
    lastSend = millis();
    EspSerial.print("DATA:");
    EspSerial.print(resLevel);
    EspSerial.print(",");
    EspSerial.print(houseLevel);
    EspSerial.print(",");
    EspSerial.print(turbVal);
    EspSerial.print(",");
    EspSerial.print(optionalPercent);
    EspSerial.println();
  }

  delay(200);
}
