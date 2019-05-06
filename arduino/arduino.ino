//#include <Servo.h>
#include <Wire.h>
#include <Arduino.h>
#include "VarSpeedServo.h"
#include "PS_PAD.h"

#define PS2_SEL 10
PS_PAD PAD(PS2_SEL);

static const byte PORT_M1  = 0;   //左
static const byte PORT_M2  = 1;   //右

VarSpeedServo ServoPan;
VarSpeedServo ServoTilt;

void setup() {
  Serial.begin(9600);

  ServoPan.attach(9);
  ServoTilt.attach(10);

  i2c_init();

//  pinMode(PS2_SEL, OUTPUT);
//  digitalWrite(PS2_SEL, HIGH);
//  PAD.init();

  //InitDCMotorPort(PORT_M1);
  //InitDCMotorPort(PORT_M2);
}

void ps_pad_test()
{
  PAD.poll();

  int lx = PAD.read(PS_PAD::ANALOG_LX);
  int ly = PAD.read(PS_PAD::ANALOG_LY);
  int rx = PAD.read(PS_PAD::ANALOG_RX);
  int ry = PAD.read(PS_PAD::ANALOG_RY);
  int buttons = PAD.read(PS_PAD::BUTTONS);

  Serial.print("LX:");
  Serial.print(lx);
  Serial.print("\tLY:");
  Serial.print(ly);
  Serial.print("\tRX:");
  Serial.print(rx);
  Serial.print("\tRY:");
  Serial.print(ry);
  Serial.print("\tBUTTONS:");
  Serial.print(buttons, HEX);
  Serial.print("\n");
}

void servo_motor_test()
{
  delay(100);
  ServoPan.write(50, 10);
  ServoTilt.write(50, 10);
  DCMotor(PORT_M1, 50);
  DCMotor(PORT_M2, -50);
  delay(2000);

  ServoPan.write(100, 50);
  ServoTilt.write(100, 50);
  DCMotor(PORT_M1, -50);
  DCMotor(PORT_M2, 50);
  delay(1000);
}

void motor_test()
{
  DCMotor(PORT_M1, 50);
  DCMotor(PORT_M2, -50);
  delay(2000);
  
  DCMotor(PORT_M1, -50);
  DCMotor(PORT_M2, 50);
  delay(1000);
}

void servo_test()
{
  ServoPan.write(50, 10);
  ServoTilt.write(50, 10);
  delay(2000);

  ServoPan.write(100, 50);
  ServoTilt.write(100, 50);
  delay(1000);
}

void loop() {

  //servo_test();

}


static const byte BRAKE            = 8;  // Brake
static const byte COAST            = 9;  // Coast
static const byte NORMAL           = 10; // Normal rotation
static const byte REVERSE          = 11; // Reverse rotation

static const byte   DCMDA1   = 2;  // DC motor driver A1
static const byte   DCMDA2   = 4;  // DC motor driver A2
static const byte   DDMDPWMA = 3;  // DC motor driver PRM A
static const byte   DCMDB1   = 7;  // DC motor driver B1
static const byte   DCMDB2   = 8;  // DC motor driver B2
static const byte   DDMDPWMB = 5;  // DC motor driver PRM B

void InitDCMotorPort(byte connector)
{
  if (connector == PORT_M1) {
    // Setup DC motor pins
    pinMode(DCMDA1, OUTPUT);
    pinMode(DCMDA2, OUTPUT);
    digitalWrite(DCMDA1, LOW);
    digitalWrite(DCMDA2, LOW);
  } else {
    // Setup DC motor pins
    pinMode(DCMDB1, OUTPUT);
    pinMode(DCMDB2, OUTPUT);
    digitalWrite(DCMDB1, LOW);
    digitalWrite(DCMDB2, LOW);
  }
}

void DCMotor(byte connector, int rotation)
{
  if (connector == PORT_M1) {
    Serial.print("LEFT: ");
  } else {
    Serial.print("RIGHT: ");
  }
  Serial.println(rotation);

  if (rotation > 0) {
    DCMotorControl(connector, NORMAL);
    DCMotorPower(connector, rotation);
  } else if (rotation == 0) {
    DCMotorControl(connector, BRAKE);
    DCMotorPower(connector, 0);
  } else {
    DCMotorControl(connector, REVERSE);
    DCMotorPower(connector, -rotation);
  }
}

void DCMotorControl(byte connector, byte rotation)
{
  // Set DC motor's rotation.
  if (connector == PORT_M1) {
    if (rotation == NORMAL) {
      digitalWrite(DCMDA1, HIGH);
      digitalWrite(DCMDA2, LOW);
    } else if (rotation == REVERSE) {
      digitalWrite(DCMDA1, LOW);
      digitalWrite(DCMDA2, HIGH);
    } else if (rotation == BRAKE) {
      digitalWrite(DCMDA1, HIGH);
      digitalWrite(DCMDA2, HIGH);
    } else if (rotation == COAST) {
      digitalWrite(DCMDA1, LOW);
      digitalWrite(DCMDA2, LOW);
    }
  } else if (connector == PORT_M2) {
    if (rotation == NORMAL) {
      digitalWrite(DCMDB1, HIGH);
      digitalWrite(DCMDB2, LOW);
    } else if (rotation == REVERSE) {
      digitalWrite(DCMDB1, LOW);
      digitalWrite(DCMDB2, HIGH);
    } else if (rotation == BRAKE) {
      digitalWrite(DCMDB1, HIGH);
      digitalWrite(DCMDB2, HIGH);
    } else if (rotation == COAST) {
      digitalWrite(DCMDB1, LOW);
      digitalWrite(DCMDB2, LOW);
    }
  }
}

void DCMotorPower(byte connector, byte pace)
{
  int duty = (((int)pace * 255) / 100);
  if (connector == PORT_M1) analogWrite(DDMDPWMA, duty);
  if (connector == PORT_M2) analogWrite(DDMDPWMB, duty);
}

void i2c_init()
{
  Wire.begin(0x25) ;                 // Ｉ２Ｃの初期化、自アドレスを0x20とする
  Wire.onRequest(requestEvent);     // マスタからのデータ取得要求のコールバック関数登録
  Wire.onReceive(receiveEvent);     // マスタからのデータ送信対応のコールバック関数登録
}


void receiveEvent(int howMany) {
  Serial.println("receiveEvent");
  byte cmd = Wire.read();
  Serial.print("cmd:");
  Serial.println(cmd);

  if (cmd == 0x01) {
    if (howMany == 4) {
      byte servo = Wire.read();
      byte angle = Wire.read();
      byte speed = Wire.read();
      Serial.print("servo: ");
      Serial.print(servo);
      Serial.print(" angle: ");
      Serial.print(angle);
      Serial.print(" speed: ");
      Serial.println(speed);
      switch (servo) {
        case 1:
          ServoPan.write(angle, speed);
          break;
        case 2:
          ServoTilt.write(angle, speed);
          break;
        default:
          break;
      }
    }
  }
}

// マスターからのリクエストに対するデータ送信
void requestEvent() {
  Serial.println("requestEvent");
}
