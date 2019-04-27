import oscP5.*;
import netP5.*;
 
OscP5 oscP5;
 
float azimuth;
float pitch;
float roll;

void setup(){
  size(500, 500);
  oscP5 = new OscP5(this, 5555);//自分のポート番号
  oscP5.plug(this,"getData","/a");//getDta:受け取る関数
}
 
public void getData(float a, float p, float r) {
  azimuth = a;
  pitch = p;
  roll = r;
}
 

void draw() {
  background(0);

  String dispText =
    "---------- Orientation --------\n" +
    String.format( "Azimuth\n\t%f\n", degrees(azimuth)) +
    String.format( "Pitch\n\t%f\n", degrees(pitch)) +
    String.format( "Roll\n\t%f\n", degrees(roll));
  text( dispText, 0, 0, width, height);
}
