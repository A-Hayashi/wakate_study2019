import oscP5.*; //<>//
import netP5.*;

import java.io.*;
import java.awt.image.*;
import javax.imageio.*;

import gohai.glvideo.*;
import processing.io.*;

I2C i2c;
GLCapture video;
OscP5 oscP5;
NetAddress myAddress;

float azimuth;
float pitch;
float roll;

int lh_ud;
int lh_rl;
int rh_ud;
int rh_rl;

void rotate_pan(int angle)
{
  try
  {
    i2c.beginTransmission(0x25);
    i2c.write(0x01);
    i2c.write(0x01);
    i2c.write(angle);
    i2c.write(20);
    i2c.endTransmission();
  }
  catch(Exception e)
  {
    i2c.endTransmission();
  }
}

void rotate_tilt(int angle)
{
  try
  {
    i2c.beginTransmission(0x25);
    i2c.write(0x01);
    i2c.write(0x02);
    i2c.write(angle);
    i2c.write(20);
    i2c.endTransmission();
  }
  catch(Exception e)
  {
    i2c.endTransmission();
  }
}

void motor_r(int duty)
{
  int send_duty = Math.min(Math.max(duty*2/3+100, 0), 200);
  try
  {
    i2c.beginTransmission(0x25);
    i2c.write(0x02);
    i2c.write(0x01);
    i2c.write(send_duty);
    i2c.endTransmission();
  }
  catch(Exception e)
  {
    i2c.endTransmission();
  }
}

void motor_l(int duty)
{
  int send_duty = Math.min(Math.max(duty*2/3+100, 0), 200);
  try
  {
    i2c.beginTransmission(0x25);
    i2c.write(0x02);
    i2c.write(0x02);
    i2c.write(send_duty);
    i2c.endTransmission();
  }
  catch(Exception e)
  {
    i2c.endTransmission();
  }
}

void setup() {
  float fontSize;

  fontSize = 24;
  textSize(fontSize);
  textAlign(LEFT, TOP);
  stroke(255);
  frameRate(10);

  size(640, 480, P2D);

  String[] devices = GLCapture.list();
  println("Devices:");
  printArray(devices);
  if (0 < devices.length) {
    String[] configs = GLCapture.configs(devices[0]);
    println("Configs:");
    printArray(configs);
  }

  i2c = new I2C(I2C.list()[0]);

  video = new GLCapture(this);
  video.start();

  OscProperties myProperties = new OscProperties();
  myProperties.setDatagramSize(100000); 
  myProperties.setListeningPort(1222);

  oscP5 = new OscP5(this, myProperties);
  myAddress = new NetAddress("192.168.100.118", 1234);
  oscP5.plug(this, "getData", "/a");
  oscP5.plug(this, "getCon", "/c");
}

public synchronized void getCon(int _lh_ud, int _lh_rl, int _rh_ud, int _rh_rl) {
  lh_ud = _lh_ud;
  lh_rl= _lh_rl;
  rh_ud= _rh_ud;
  rh_rl= _rh_rl;
  //println("received");
}

public synchronized void getData(float a, float p, float r) {
  azimuth = a;
  pitch = p;
  roll = r;
  //println("received");
}

void motor_control(int r, int l) {
  motor_r(r);
  motor_l(l);
}

void servo_control(float tilt, float pan) {
  rotate_tilt((int)tilt);
  rotate_pan((int)pan);
}

float calc_tilt(float in)
{
  float tilt;
  tilt = in + 180;
  tilt = Math.min(Math.max(tilt, 0), 180);
  return tilt;
}

float calc_pan(float in)
{
  float pan;
  pan = in + 180;
  pan = Math.min(Math.max(pan, 90), 270);
  pan = 180-(pan-90);
  return pan;
}

void video_control(GLCapture v)
{
  if (v.available()) {
    v.read();
    video_buf = v.get();
    video_buf = rotate_180(video_buf);
    thread("broadcast");
  }
}

PImage video_buf;
int cnt = 0;
synchronized void draw() {
  cnt++;
  background(0);
  if (cnt%3==0) {
    video_control(video);
  }

  float tilt = calc_tilt(roll);
  float pan = calc_pan(azimuth);
  if ((cnt+1)%3==0) {
    servo_control(tilt, pan);
  }
  if ((cnt+2)%3==0) {
    motor_control(rh_ud, lh_ud);
  }

  String dispText =
    String.format( "Azimuth:  %f\n", azimuth) +
    String.format( "Pitch:  %f\n", pitch) +
    String.format( "Roll:  %f\n", roll)+
    String.format( "tilt:  %f\n", tilt)+
    String.format( "pan:  %f\n", pan)+
    String.format( "lh_ud:  %d\n", lh_ud)+
    String.format( "lh_rl:  %d\n", lh_rl)+
    String.format( "rh_ud:  %d\n", rh_ud)+
    String.format( "rh_ud:  %d\n", rh_rl);
    image(video, 0, 0, width, height);
    text( dispText, 0, 0, width, height);

  String dispText2 =
    String.format( "Azimuth:  %f  ", azimuth) +
    String.format( "Pitch:  %f  ", pitch) +
    String.format( "Roll:  %f  ", roll)+
    String.format( "tilt:  %f  ", tilt)+
    String.format( "pan:  %f  ", pan)+
    String.format( "lh_ud:  %d  ", lh_ud)+
    String.format( "lh_rl:  %d  ", lh_rl)+
    String.format( "rh_ud:  %d  ", rh_ud)+
    String.format( "rh_ud:  %d  ", rh_rl);
  println(dispText2);
}

void broadcast() {
  PImage img = video_buf;
  img.loadPixels();

  BufferedImage bimg = new BufferedImage(img.width, img.height, BufferedImage.TYPE_INT_RGB);
  bimg.setRGB(0, 0, img.width, img.height, img.pixels, 0, img.width);
  ByteArrayOutputStream baos = new ByteArrayOutputStream();

  try {
    ImageIO.write(bimg, "jpg", new BufferedOutputStream(baos));
  }
  catch (IOException e) {
    e.printStackTrace();
  }

  byte[] bytes = baos.toByteArray();
  OscMessage myMessage = new OscMessage("/b");
  myMessage.add(bytes);

  if (myAddress!=null) {
    oscP5.send(myMessage, myAddress);
  } else {
    println("null");
  }
}

PImage rotate_180(PImage src) {
  PGraphics g = createGraphics(src.width, src.height);
  g.beginDraw();
  g.smooth();
  g.imageMode(CENTER);
  g.rotate(PI);
  g.image(src, -src.width/2, -src.height/2);
  g.endDraw();

  PImage dst = g.get();
  g.dispose();

  return dst;
}
