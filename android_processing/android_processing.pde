import android.app.Activity;
import android.content.Context;
import android.hardware.Sensor;
import android.hardware.SensorManager;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import oscP5.*;
import netP5.*;
import android.os.AsyncTask;

import java.io.*;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;

float[] accelerometerValues  = new float[3];
float[] magneticValues = new float[3];

Activity      act;
SensorManager mSensor = null;
SensorCatch   sensorCatch = null;

float easing = 0.6;
float azimuth;
float pitch;
float roll;

PImage video;
OscP5 oscP5;
NetAddress myAddress;

class SensorCatch implements SensorEventListener {
  public void onSensorChanged(SensorEvent sensorEvent) {
    float[] I = new float[16];
    float[] R = new float[16];
    float orientation[] = new float[3]; 

    switch(sensorEvent.sensor.getType()) {

    case Sensor.TYPE_ACCELEROMETER:
      accelerometerValues  = sensorEvent.values.clone();
      break;
    case Sensor.TYPE_MAGNETIC_FIELD:
      magneticValues  = sensorEvent.values.clone();
      break;
    }

    if (SensorManager.getRotationMatrix(R, I, accelerometerValues, magneticValues)) {
      SensorManager.getOrientation(R, orientation);
      azimuth += easing * (orientation[0] - azimuth);
      pitch += easing * (orientation[1] - pitch);
      roll += easing * (orientation[2] - roll);

      SendAsyncTask task = new SendAsyncTask();
      task.execute(azimuth, pitch, roll);
    }
  }

  public void onAccuracyChanged(Sensor sensor, int i) {
  }
}

public void onResume() {

  super.onResume();

  act = getActivity();
  mSensor = (SensorManager)act.getSystemService(Context.SENSOR_SERVICE);

  sensorCatch = new SensorCatch();

  mSensor.registerListener(sensorCatch, mSensor.getDefaultSensor(Sensor.TYPE_ACCELEROMETER), SensorManager.SENSOR_DELAY_NORMAL);
  mSensor.registerListener(sensorCatch, mSensor.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD), SensorManager.SENSOR_DELAY_NORMAL);
}


public void onPause() {
  super.onPause();
  if (mSensor != null) {
    mSensor.unregisterListener(sensorCatch);
  }
}

void setup() {

  float         fontSize;
  orientation(PORTRAIT);

  fontSize = 24 * displayDensity;
  textSize(fontSize);
  textAlign(LEFT, TOP);
  stroke(255);

  OscProperties myProperties = new OscProperties();
  myProperties.setDatagramSize(100000); 
  myProperties.setListeningPort(1234);
  oscP5 = new OscP5(this, myProperties);
  myAddress = new NetAddress("192.168.100.100", 1222);
  oscP5.plug(this, "getData", "/b");
}

public void getData(byte[] data) {
  ByteArrayInputStream bis=new ByteArrayInputStream(data); 
  Bitmap bimg = BitmapFactory.decodeStream(bis); 

  synchronized(this) {
    video=new PImage(bimg.getWidth(), bimg.getHeight(), PConstants.RGB);
    bimg.getPixels(video.pixels, 0, video.width, 0, 0, video.width, video.height);
    video.updatePixels();
  }
}

void draw() {
  translate(width, 0);
  rotate(PI/2);
  background(0);

  if (video!=null) {
    PImage video_disp;
    synchronized(this) {
      video_disp = video.get();
    }
    image(video_disp, 0, 0, height, width);
  } else {
    println("video is null");
  }

  float ut = sqrt(sq(magneticValues[0]) 
    + sq(magneticValues[1]) 
    + sq(magneticValues[2]));

  String dispText 
    = String.format( 
    "加速度\n X:%s Y:%s Z:%s\n\n"
    +"地磁気\n X:%s Y:%s Z:%s\n"
    +"地磁気の大きさ:%s\n\n"

    +"Azimuth:\t%s\t%s\n"
    +"Pitch:\t%s\t%s\n"
    +"Roll:\t%s\t%s\n", 

    nfs(accelerometerValues[0], 2, 2), 
    nfs(accelerometerValues[1], 2, 2), 
    nfs(accelerometerValues[2], 2, 2), 

    nfs(magneticValues[0], 2, 2), 
    nfs(magneticValues[1], 2, 2), 
    nfs(magneticValues[2], 2, 2), 
    nfs(ut, 2, 2), 

    nfs(azimuth, 2, 2), 
    nfs(degrees(azimuth), 2, 2), 
    nfs(pitch, 2, 2), 
    nfs(degrees(pitch), 2, 2), 
    nfs(roll, 2, 2), 
    nfs(degrees(roll), 2, 2)
    );

  text( dispText, 0, 0, width, height);
}


public class SendAsyncTask extends AsyncTask<Float, Integer, Boolean> {

  @Override
    protected void onPreExecute() {
  }

  @Override
    protected Boolean doInBackground(Float... params) {

    Float azimuth = params[0];
    Float pitch = params[1];
    Float roll = params[2];

    OscMessage myMessage = new OscMessage("/a");
    myMessage.add(azimuth);
    myMessage.add(pitch);
    myMessage.add(roll);

    if (myAddress!=null) {
      oscP5.send(myMessage, myAddress);
    }

    return true;
  }

  @Override
    protected void onProgressUpdate(Integer... progress) {
  }

  @Override
    protected void onPostExecute(Boolean result) {
  }
}
