//#include <Servo.h>
//#include <Wire.h>
#include <Arduino.h>
#include "VarSpeedServo.h"

static const byte PORT_M1  = 0;   //左
static const byte PORT_M2  = 1;

VarSpeedServo ServoPan;
VarSpeedServo ServoTilt;

void setup() {
  Serial.begin(9600);
  pinMode(A0, INPUT);
  pinMode(A1, INPUT);
  pinMode(A2, INPUT);
  pinMode(A3, INPUT);

  ServoPan.attach(9);
  ServoTilt.attach(10);

  InitDCMotorPort(PORT_M1);
  InitDCMotorPort(PORT_M2);
}

void loop() {
  // put your main code here, to run repeatedly:
  byte a0 = digitalRead(A0);
  byte a1 = digitalRead(A1);
  byte a2 = digitalRead(A2);
  byte a3 = digitalRead(A3);
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
