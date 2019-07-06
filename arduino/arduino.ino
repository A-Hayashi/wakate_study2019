#include <Wire.h>
#include "L298N.h"
#include "VarSpeedServo.h"

#define ENA 5
#define IN1 9
#define IN2 10
#define IN3 11
#define IN4 12
#define ENB 3

//#define DEBUG
VarSpeedServo myservo0;
VarSpeedServo myservo1;

L298N motor0(ENA, IN1, IN2);
L298N motor1(ENB, IN3, IN4);

void setup() {
  Serial.begin(9600);
  Serial.println("Motor Start");

  myservo0.attach(8);
  myservo1.attach(7);

  i2c_init();
}

void loop() {
  //    myservo1.write(0, 40);
  //    delay(2000);
  //    myservo1.write(90, 40);
  //    delay(2000);
  //    myservo1.write(180, 80);
  //    delay(2000);
  //    myservo1.write(90, 40);
  //    delay(2000);

  //    myservo0.write(0, 40);
  //    delay(2000);
  //    myservo0.write(90, 40);
  //    delay(2000);
  //    myservo0.write(180, 80);
  //    delay(2000);
  //    myservo0.write(90, 40);
  //    delay(2000);

  //      Serial.println("Motor0 Forward");
  //      motor0.setSpeed(255);
  //      motor0.forward();
  //      delay(2000);
  //      Serial.println("Motor0 Backward");
  //      motor0.setSpeed(100);
  //      motor0.backward();
  //      delay(2000);
  //      motor0.stop();
  //
  //      Serial.println("Motor1 Forward");
  //      motor1.setSpeed(255);
  //      motor1.forward();
  //      delay(2000);
  //      Serial.println("Motor1 Backward");
  //      motor1.setSpeed(100);
  //      motor1.backward();
  //      delay(2000);
  //      motor1.stop();
}

void i2c_init()
{
  Wire.begin(0x25) ;                // Ｉ２Ｃの初期化、自アドレスを0x26とする
  Wire.onRequest(requestEvent);     // マスタからのデータ取得要求のコールバック関数登録
  Wire.onReceive(receiveEvent);     // マスタからのデータ送信対応のコールバック関数登録
}

void receiveEvent(int howMany) {
  byte cmd = Wire.read();
#ifdef DEBUG
  Serial.println("receiveEvent");
  Serial.print("cmd:");
  Serial.println(cmd);
#endif
  if (cmd == 0x02) {
    if (howMany == 3) {
      byte motor = Wire.read();
      uint8_t buf = Wire.read();

      int speed = (int)buf - 100;
#ifdef DEBUG
      Serial.print("motor: ");
      Serial.print(motor);
      Serial.print(" speed: ");
      Serial.println(speed);
#endif
      speed = map(speed, -100, 100, -255, 255);
      if (motor == 1) {
        if (speed > 0) {
          motor0.setSpeed(speed);
          motor0.forward();
        } else if (speed < 0) {
          motor0.setSpeed(-speed);
          motor0.backward();
        } else {
          motor0.stop();
        }
      } else if (motor == 2) {
        if (speed > 0) {
          motor1.setSpeed(speed);
          motor1.forward();
        } else if (speed < 0) {
          motor1.setSpeed(-speed);
          motor1.backward();
        } else {
          motor1.stop();
        }
      } else {

      }
    }
  }

  if (cmd == 0x01) {
    if (howMany == 4) {
      byte servo = Wire.read();
      byte angle = Wire.read();
      byte speed = Wire.read();
#ifdef DEBUG
      Serial.print("servo: ");
      Serial.print(servo);
      Serial.print(" angle: ");
      Serial.print(angle);
      Serial.print(" speed: ");
      Serial.println(speed);
#endif
      switch (servo) {
        case 1:
          myservo0.write(angle, speed);
          break;
        case 2:
          myservo1.write(angle, speed);
          break;
      }
    }
  }
}

// マスターからのリクエストに対するデータ送信
void requestEvent() {
#ifdef DEBUG
  Serial.println("requestEvent");
#endif
}
