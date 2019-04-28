import oscP5.*;
import netP5.*;

import java.io.*;
import java.awt.image.*;
import javax.imageio.*;
import processing.video.*;

Capture camera;
OscP5 oscP5;
NetAddress myAddress;

void setup() {
  textSize(24);
  textAlign(LEFT, TOP);
  stroke(255);
  frameRate(10);
  size(640, 480);

  camera = new Capture(this, width, height, 30);
  camera.start();

  OscProperties myProperties = new OscProperties();
  myProperties.setDatagramSize(100000); 
  myProperties.setListeningPort(1222);  //自分のポート番号
  oscP5 = new OscP5(this, myProperties);
  myAddress = new NetAddress("192.168.100.100", 1234);//IPaddress,相手のポート番号;
  oscP5.plug(this, "getData", "/a");//getDta:受け取る関数
}

int test = 0;
public void getData(int data) {
  test = data;
}

void draw() {
  background(0);

  image(camera, 0, 0); // 画面に表示

  String dispText = String.format( "RECEIVED: \t%d\n", test);
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
