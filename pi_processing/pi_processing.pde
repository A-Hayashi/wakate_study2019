import oscP5.*;
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
}

public void getData(float a, float p, float r) {
  synchronized(this) {
    azimuth = a;
    pitch = p;
    roll = r;
  }

  //println("received");
}

PImage video_buf;
float azimuth_buf;
float pitch_buf;
float roll_buf;
byte cnt = 0;

void draw() {
  cnt++;
  background(0);
  if (cnt%3==0) {
    if (video.available()) {
      video.read();
      video_buf = video.get();
      video_buf = rotate_180(video_buf);
      thread("broadcast");
    }
  }

  image(video, 0, 0, width, height);

  synchronized(this) {
    azimuth_buf = azimuth;
    pitch_buf = pitch;
    roll_buf = roll;
  }

  float tilt=roll;
  float pan=azimuth;
  {
    tilt = tilt + 180;
    tilt = Math.min(Math.max(tilt, 0), 180);
    print("tilt: ");
    print(tilt);

    pan = pan + 180;
    pan = Math.min(Math.max(pan, 90), 270);
    pan = 180-(pan-90);
    print(" pan: ");
    println(pan);
  }

  if ((cnt+1)%3==0) {
    rotate_tilt((int)tilt);
    //rotate_tilt((int)90);
  }
  if ((cnt+2)%3==0) {
    rotate_pan((int)pan);
    //rotate_pan((int)90);
  }

  String dispText =
    "---------- Orientation --------\n" +
    String.format( "Azimuth\n\t%f\n", azimuth) +
    String.format( "Pitch\n\t%f\n", pitch) +
    String.format( "Roll\n\t%f\n", roll);

  text( dispText, 0, 0, width, height);
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
