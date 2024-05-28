#include <Arduino.h>
#define RED_PIN   PF_1
#define GREEN_PIN PF_3
#define BLUE_PIN  PF_2
uint8_t tono=0;
uint8_t nota=0;
uint8_t nibble1;
uint8_t nibble2;
uint16_t frecuencia;
#define BUZZER_PIN PD_7  // Define el pin donde está conectado el buzzer
#define Umbral 3 //Define el umbral mínimo para que se active cada nota

void tone(uint16_t frequency, uint32_t duration) {
  uint32_t period = 1000000 / frequency;  
  uint32_t half_period = period / 2;  
  
  for (uint32_t i = 0; i < duration * frequency / 1000; i++) {
    digitalWrite(BUZZER_PIN, HIGH);
    delayMicroseconds(half_period);
    digitalWrite(BUZZER_PIN, LOW);
    delayMicroseconds(half_period);
  }
}

void noTone() {
  digitalWrite(BUZZER_PIN, LOW);
}

void setup() {
  // Configura los pines del LED RGB como salidas
  pinMode(RED_PIN, OUTPUT);
  pinMode(GREEN_PIN, OUTPUT);
  pinMode(BLUE_PIN, OUTPUT);
  digitalWrite(RED_PIN, HIGH);
  digitalWrite(BLUE_PIN, HIGH);
  digitalWrite(GREEN_PIN, HIGH);
  
  Serial.begin(115200);
  pinMode(BUZZER_PIN, OUTPUT);
}

void loop() {
  if (Serial.available()>1){
    uint8_t basura=Serial.read();  
  }
  else if (Serial.available()) {  // Espera a que llegue al menos un byte
    uint8_t receivedByte = Serial.read();  // Lee el byte recibido
    // Divide el byte en sus dos nibbles
    nibble1 = receivedByte >> 4;  // Obtiene el primer nibble (bits 7-4)
    nibble2 = receivedByte & 0x0F;  // Obtiene el segundo nibble (bits 3-0)
    Serial.println(receivedByte);
    Serial.println(nibble1);
    Serial.println(nibble2);
    // Verifica los valores de los nibbles y asigna tono y nota
    
    if (nibble1 >= Umbral && nibble2 >= Umbral) {
      tono = 1;
      nota = 3;  // Si ambos nibbles son mayores o igual a 3, asigna Sol (G)
    } else if (nibble1 >= Umbral-1 && nibble2 < Umbral) {
      tono = 1;
      nota = 1;  // Si el primer nibble es mayor o igual a 2 y el segundo es menor a 3, asigna Si (C)
    } else if (nibble1 < Umbral-1 && nibble2 >= Umbral) {
      tono = 1;
      nota = 2;  // Si el primer nibble es menor a 2 y el segundo es mayor o igual a 3, asigna La (A)
    } else {
      tono = 0;
      nota = 0;  // Si ninguno de los anteriores se cumple, no toca nada
    }
  }
    // Asigna frecuencia según la nota
    switch(nota) {
      case 1:
        frecuencia = 494; // Frecuencia de la nota Si (C)
        digitalWrite(RED_PIN, HIGH);
        digitalWrite(BLUE_PIN, LOW);
        digitalWrite(GREEN_PIN, LOW);
        //Serial.println("Nota: Si (C)");
        break;
      case 2:
        frecuencia = 440; // Frecuencia de la nota La (A)
        //Serial.println("Nota: La (A)");
        digitalWrite(RED_PIN, LOW);
        digitalWrite(BLUE_PIN, HIGH);
        digitalWrite(GREEN_PIN, LOW);
        break;
      case 3:
        frecuencia = 392; // Frecuencia de la nota Sol (G)
        //Serial.println("Nota: Sol (G)");
        digitalWrite(RED_PIN, LOW);
        digitalWrite(BLUE_PIN, LOW);
        digitalWrite(GREEN_PIN, HIGH);
        break;
      default:
        frecuencia = 0; // Si la nota es 0 (no tocar), establece la frecuencia en 0
        digitalWrite(RED_PIN, HIGH);
        digitalWrite(BLUE_PIN, HIGH);
        digitalWrite(GREEN_PIN, HIGH);
        break;
    }
    
    // Toca la nota en el buzzer
    if (tono == 1 && frecuencia != 0) {
      tone(frecuencia, 1000); // Toca la nota durante 1 segundo
      tono=0;
      nota=0;
      Serial.println(frecuencia);
    } else {
      noTone(); // Detiene el tono si el tono es 0 o si la frecuencia es 0
    }
  }
