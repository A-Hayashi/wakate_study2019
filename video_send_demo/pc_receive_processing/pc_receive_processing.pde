import oscP5.*;
import netP5.*;

import java.io.*;
import java.awt.image.*;
import javax.imageio.*;
import processing.video.*;

PImage video;
OscP5 oscP5;
NetAddress myAddress;

void setup() {
  textSize(24);
  textAlign(LEFT, TOP);
  stroke(255);
  frameRate(10);
  size(640, 480);

  video = createImage(width, height, RGB);

  OscProperties myProperties = new OscProperties();
  myProperties.setDatagramSize(100000); 
  myProperties.setListeningPort(1234);  //自分のポート番号
  oscP5 = new OscP5(this, myProperties);//自分のポート番号
  myAddress = new NetAddress("192.168.100.100", 1222);//IPaddress,相手のポート番号;
  oscP5.plug(this, "getData", "/b");//getDta:受け取る関数
}

public void getData(byte[] data) {
  ByteArrayInputStream bais = new ByteArrayInputStream(data);

  try {
    ImageIO.read(bais).getRGB(0, 0, video.width, video.height, video.pixels, 0, video.width);
  }
  catch (Exception e) {
    e.printStackTrace();
  }

  video.updatePixels();
}

int test = 0;
void draw() {
  background(0);

  if (video!=null) {
    image(video, 0, 0);
  }
  String dispText = String.format( "SEND: \t%d\n", test);
  text( dispText, 0, 0, width, height);

  test++;
  OscMessage myMessage = new OscMessage("/a");
  myMessage.add(test);

  if (myAddress!=null) {
    oscP5.send(myMessage, myAddress);
  } else {
    println("null");
  }
}
