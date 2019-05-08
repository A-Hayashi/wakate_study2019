import net.java.games.input.*;
import org.gamecontrolplus.*;
import org.gamecontrolplus.gui.*;

import oscP5.*;
import netP5.*;


ControlIO control;
ControlDevice device;
ControlSlider[] sliders = new ControlSlider[4];
ControlButton[] button  =new ControlButton[4];
ControlHat hat;

int a, b, c, d;
float e, f;

OscP5 oscP5;
NetAddress myAddress;


void setup() {
  control = ControlIO.getInstance(this);
  device = control.getDevice("ELECOM JC-PS101U series");//ここは自分のデバイス名に変更

  sliders[0] = device.getSlider(0);  // RH stick Up-Down
  sliders[1] = device.getSlider(1);  // RH stick Left-Right
  sliders[2] = device.getSlider(2);  // LH stick Up-Down
  sliders[3] = device.getSlider(3);  // LH stick Left-Right

  button[0] = device.getButton(0);   //triangleButton
  button[0].plug(this, "triangleButtonPress", ControlIO.ON_PRESS);
  button[0].plug(this, "triangleButtonRelease", ControlIO.ON_RELEASE);
  button[1] = device.getButton(1);   //circleButton
  button[1].plug(this, "circleButtonPress", ControlIO.ON_PRESS);
  button[1].plug(this, "circleButtonRelease", ControlIO.ON_RELEASE);
  button[2] = device.getButton(2);   //xButton
  button[2].plug(this, "xButtonPress", ControlIO.ON_PRESS);
  button[2].plug(this, "xButtonRelease", ControlIO.ON_RELEASE);
  button[3] = device.getButton(3);   //squareButton
  button[3].plug(this, "squareButtonPress", ControlIO.ON_PRESS);
  button[3].plug(this, "squareButtonRelease", ControlIO.ON_RELEASE);

  hat = device.getHat(12);
  hat.plug(this, "hatPress", ControlIO.ON_PRESS);
  hat.plug(this, "hatRelease", ControlIO.ON_RELEASE);

  size(600, 600, P3D);
  smooth();
  frameRate(250);


  OscProperties myProperties = new OscProperties();
  myProperties.setDatagramSize(100000); 
  myProperties.setListeningPort(1234);
  oscP5 = new OscP5(this, myProperties);
  myAddress = new NetAddress("192.168.100.11", 1222);
  oscP5.plug(this, "getData", "/c");
}

void draw() {
  background(0);
  int LH_UD = int(-sliders[2].getValue()*100);
  int LH_RL = int(sliders[3].getValue()*100);
  int RH_UD = int(-sliders[0].getValue()*100);
  int RH_RL = int(sliders[1].getValue()*100);

  textUpDate();

  OscMessage myMessage = new OscMessage("/c");
  myMessage.add(LH_UD);
  myMessage.add(LH_RL);
  myMessage.add(RH_UD);
  myMessage.add(RH_RL);

  if (myAddress!=null) {
    oscP5.send(myMessage, myAddress);
  } else {
    println("null");
  }
}

void textUpDate() {
  textSize(24);
  fill(240);
  textAlign(RIGHT);
  text("LH U-D", 200, 40);
  text(int(-sliders[2].getValue()*100), 300, 40);
  text("LH R-L", 200, 80);
  text(int(sliders[3].getValue()*100), 300, 80);
  text("RH U-D", 200, 120);
  text(int(-sliders[0].getValue()*100), 300, 120);
  text("RH R-L", 200, 160);
  text(int(sliders[1].getValue()*100), 300, 160);
  text("RH R-L", 200, 160);
  text(int(sliders[1].getValue()*100), 300, 160);

  text("TRIANGLE", 200, 200);
  text(a, 300, 200);
  text("CIRCLE", 200, 240);
  text(b, 300, 240);
  text("x", 200, 280);
  text(c, 300, 280);
  text("square", 200, 320);
  text(d, 300, 320);

  text("HatX", 200, 360);
  text(e, 300, 360);
  text("HatY", 200, 400);
  text(f, 300, 400);
}

void triangleButtonPress() {
  a+=1;
}

void triangleButtonRelease() {
  a-=1;
}

void circleButtonPress() {
  b+=1;
}

void circleButtonRelease() {
  b-=1;
}

void xButtonPress() {
  c+=1;
}

void xButtonRelease() {
  c-=1;
}

void squareButtonPress() {
  d+=1;
}

void squareButtonRelease() {
  d-=1;
}

void hatPress(float x, float y) {
  e=x;
  f=y;
}

void hatRelease(float x, float y) {
  e-=x;
  f-=y;
}
