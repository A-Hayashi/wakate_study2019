import oscP5.*; //<>// //<>//
import netP5.*;

import java.io.*;
import java.awt.image.*;
import javax.imageio.*;
import gohai.glvideo.*;

GLCapture video;
OscP5 oscP5;
NetAddress myAddress;
PImage video_buf;

void setup() {
  float fontSize;

  fontSize = 24;
  textSize(fontSize);
  textAlign(LEFT, TOP);
  stroke(255);
  frameRate(50);

  size(640, 480, P2D);

  String[] devices = GLCapture.list();
  println("Devices:");
  printArray(devices);
  if (0 < devices.length) {
    String[] configs = GLCapture.configs(devices[0]);
    println("Configs:");
    printArray(configs);
  }

  video = new GLCapture(this);
  video.start();

  OscProperties myProperties = new OscProperties();
  myProperties.setDatagramSize(100000); 
  myProperties.setListeningPort(1220);
  oscP5 = new OscP5(this, myProperties);
  myAddress = new NetAddress("192.168.100.118", 1221);
}

void draw() {
  background(0);
  video_control(video);
  image(video, 0, 0, width, height);
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
