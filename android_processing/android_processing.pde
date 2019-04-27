// Based on the compass example from Rolf van Gelder.
// http://cagewebdev.com/index.php/android-processing-examples/

import android.content.Context;
import android.hardware.Sensor;
import android.hardware.SensorManager;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import oscP5.*;
import netP5.*;
import android.os.AsyncTask;

Context context;
SensorManager manager;
SensorListener listener;
Sensor accelerometer;
Sensor magnetometer;

float easing = 0.6;

float azimuth;
float pitch;
float roll;


OscP5 oscP5;
NetAddress myAddress;

void setup() {
  fullScreen(P2D);
  orientation(PORTRAIT);

  float fontSize;
  //文字サイズ、文字位置指定
  fontSize = 24 * displayDensity;
  textSize(fontSize);
  textAlign(LEFT, TOP);
  stroke(255);
  frameRate(10);

  context = getContext();  
  listener = new SensorListener();
  manager = (SensorManager)context.getSystemService(Context.SENSOR_SERVICE);
  accelerometer = manager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER);
  magnetometer  = manager.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD);
  manager.registerListener(listener, accelerometer, SensorManager.SENSOR_DELAY_NORMAL);
  manager.registerListener(listener, magnetometer, SensorManager.SENSOR_DELAY_NORMAL);


  oscP5 = new OscP5(this, 1234);//自分のポート番号
  myAddress = new NetAddress("192.168.100.100", 5555);//IPaddress,相手のポート番号;
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

void resume() {
  if (manager != null) {
    manager.registerListener(listener, accelerometer, SensorManager.SENSOR_DELAY_NORMAL);
    manager.registerListener(listener, magnetometer, SensorManager.SENSOR_DELAY_NORMAL);
  }
}

void pause() {
  if (manager != null) {
    manager.unregisterListener(listener);
  }
}

class SensorListener implements SensorEventListener {
  float[] gravity = new float[3];
  float[] geomagnetic = new float[3];
  float[] I = new float[16];
  float[] R = new float[16];
  float orientation[] = new float[3]; 

  public void onSensorChanged(SensorEvent event) {
    if (event.accuracy == SensorManager.SENSOR_STATUS_ACCURACY_LOW) return;

    if (event.sensor.getType() ==  Sensor.TYPE_MAGNETIC_FIELD) {
      arrayCopy(event.values, geomagnetic);
    }
    if (event.sensor.getType() ==  Sensor.TYPE_ACCELEROMETER) {
      arrayCopy(event.values, gravity);
    }
    if (SensorManager.getRotationMatrix(R, I, gravity, geomagnetic)) {
      SensorManager.getOrientation(R, orientation);
      azimuth += easing * (orientation[0] - azimuth);
      pitch += easing * (orientation[1] - pitch);
      roll += easing * (orientation[2] - roll);

      SendAsyncTask task = new SendAsyncTask();
      task.execute(azimuth, pitch, roll);
    }
  }
  public void onAccuracyChanged(Sensor sensor, int accuracy) {
  }
}

public class SendAsyncTask extends AsyncTask<Float, Integer, Boolean> {

  @Override
    protected void onPreExecute() {
  }

  @Override
    protected Boolean doInBackground(Float... params) {

    float azimuth = params[0];
    float pitch = params[1];
    float roll = params[2];

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
    // このサンプルでは progress[0] が進捗.
  }

  @Override
    protected void onPostExecute(Boolean result) {
  }
}
