import oscP5.*;
import netP5.*;

import java.io.*;
import java.awt.image.*;
import javax.imageio.*;
import processing.video.*;

Capture camera;
OscP5 oscP5;
NetAddress myAddress;


float azimuth;
float pitch;
float roll;

void setup() {

  float fontSize;
  //文字サイズ、文字位置指定
  fontSize = 24;
  textSize(fontSize);
  textAlign(LEFT, TOP);
  stroke(255);
  frameRate(10);

  size(640, 480);

  camera = new Capture(this, width, height, 30); // Captureオブジェクトを生成
  camera.start();

  OscProperties myProperties = new OscProperties();
  myProperties.setDatagramSize(100000); 
  myProperties.setListeningPort(1222);  //自分のポート番号

  oscP5 = new OscP5(this, myProperties);
  myAddress = new NetAddress("192.168.100.118", 1234);//IPaddress,相手のポート番号;
  oscP5.plug(this, "getData", "/a");//getDta:受け取る関数
}

public void getData(float a, float p, float r) {
  azimuth = a;
  pitch = p;
  roll = r;

  //println("received");
}


void draw() {
  background(0);

  image(camera, 0, 0); // 画面に表示

  String dispText =
    "---------- Orientation --------\n" +
    String.format( "Azimuth\n\t%f\n", degrees(azimuth)) +
    String.format( "Pitch\n\t%f\n", degrees(pitch)) +
    String.format( "Roll\n\t%f\n", degrees(roll));
  text( dispText, 0, 0, width, height);
}


//カメラの映像が更新されるたびに、最新の映像を読み込む
void captureEvent(Capture camera) {
  camera.read();
  broadcast(camera);
}


void broadcast(PImage img) {
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
