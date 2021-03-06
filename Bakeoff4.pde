import java.util.ArrayList;
import java.util.Collections;
import ketai.sensors.*;
KetaiSensor sensor;

float cursorX, cursorY;
float light = 0; 
float proxSensorThreshold = 30; //you will need to change this per your device.
boolean tapped = false;
int bwidth = 500;
int bheight = 500;
float prevz = 0;;
private class Target
{
  int target = 0;
  int action = 0;
}

int trialCount = 5; //this will be set higher for the bakeoff
int trialIndex = 0;
ArrayList<Target> targets = new ArrayList<Target>();

int startTime = 0; // time starts when the first click is captured
int finishTime = 0; //records the time of the final click
boolean userDone = false;
int countDownTimerWait = 0;
PImage CW;
PImage CCW;
void setup() {
  CW = loadImage("CW.png");
  CCW = loadImage("CCW.png");
  size(1000, 1000,P2D); //you can change this to be fullscreen
  frameRate(60);
  sensor = new KetaiSensor(this);
  sensor.start();
  orientation(PORTRAIT);

  rectMode(CENTER);
  textFont(createFont("Arial", 40)); //sets the font to Arial size 20
  textAlign(CENTER);

  for (int i=0; i<trialCount; i++)  //don't change this!
  {
    Target t = new Target();
    t.target = ((int)random(1000))%4;
    t.action = ((int)random(1000))%2;
    targets.add(t);
    println("created target with " + t.target + "," + t.action);
  }

  Collections.shuffle(targets); // randomize the order of the button;
  tapped = false;
}

void draw() {
  int index = trialIndex;

  //uncomment line below to see if sensors are updating
  //println("light val: " + light +", cursor accel vals: " + cursorX +"/" + cursorY);
  background(80); //background is light grey
  noStroke(); //no stroke
  
  countDownTimerWait--;

  if (startTime == 0)
    startTime = millis();

  if (index>=targets.size() && !userDone)
  {
    userDone=true;
    finishTime = millis();
  }

  if (userDone)
  {
    text("User completed " + trialCount + " trials", width/2, 50);
    text("User took " + nfc((finishTime-startTime)/1000f/trialCount, 1) + " sec per target", width/2, 150);
    return;
  }

  for (int i=0; i<4; i++)
  {
    if (targets.get(index).target==i)
      fill(0, 255, 0);
    else
      fill(180, 180, 180);
    //stroke(200);
    //rect(50,50,100,100);
    //noStroke();
    stroke(100);
    rect((bwidth/2)+bwidth*(i%2), (bheight/2) + bheight*((i < 2)? 0 : 1), bwidth, bheight);
    noStroke();
  }

  if (!tapped)
    fill(180, 0, 0);
  else  {
    if(targets.get(index).action==0)  {
      image(CW,bwidth/2,bheight/4,bwidth,bheight/3);
    }
    else  {
      image(CW,bwidth/2,3*bheight/2,bwidth,bheight/3);
    }
    fill(255, 0, 0);
  }
  ellipse(cursorX, cursorY, 50, 50);

  fill(255);//white
  text("Trial " + (index+1) + " of " +trialCount, width/2, 50);
  text("Target #" + (targets.get(index).target)+1, width/2, 100);

  if (targets.get(index).action==0)
    text("UP", width/2, 150);
  else
    text("DOWN", width/2, 150);
}

void onGyroscopeEvent(float x, float y, float z)
{
  int index = trialIndex;
  if (userDone || index>=targets.size())
    return;
  Target t = targets.get(index);
  
  if (t==null)
    return;
 
  if (tapped && abs(z-prevz)>1 && countDownTimerWait<0) //possible hit event
  {
    
    if (hitTest()==t.target)//check if it is the right target
    {
      
      //println(z-9.8); use this to check z output!
      if (((z-prevz)>1 && t.action==0) || ((z-prevz)<-1 && t.action==1))
      {
        System.out.println("Right target, right z direction!");
        trialIndex++; //next trial!
      } else
      {
        if (trialIndex>0)
          trialIndex--; //move back one trial as penalty!
        System.out.println("right target, WRONG z direction!");
      }
      countDownTimerWait=8;
      tapped = false;
      cursorX =500;
      cursorY =500;
      //wait roughly 0.5 sec before allowing next trial
    } 
  } else if (tapped && countDownTimerWait<0 && hitTest()!=t.target)
  { 
    tapped = false;
    System.out.println("wrong round 1 action!"); 

    if (trialIndex>0)
      trialIndex--; //move back one trial as penalty!

    countDownTimerWait=8; //wait roughly 0.5 sec before allowing next trial
    cursorX =500;
    cursorY =500;
  }
  prevz = z;
}

void onAccelerometerEvent(float x, float y, float z)
{
  int index = trialIndex;

  if (userDone || index>=targets.size())
    return;

  if (!tapped && countDownTimerWait<0) //only update cursor, if light is low
  {
    cursorX = cursorX-x*1000; //cented to window and scaled
    cursorY = cursorY+y*1000; //cented to window and scaled
    if (cursorX < 50)
     cursorX = 50;
    if (cursorX > 2*bwidth - 50)
     cursorX = 2*bwidth - 50;
     if (cursorY < 50)
     cursorY = 50;
    if (cursorY > 2*bheight - 50)
     cursorY = 2*bheight - 50;
     
  }


}
boolean between(float x,float y,float width)  {
  return (x <= y && y <= x+width);
}
int hitTest() 
{
  
  for (int i=0; i<4; i++)
    //if (50+i%2*bwidth<cursorX && 50+(i%2+1)*bwidth > cursorX && 50+i%2*bheight<cursorY && 50+(i%2+1)*bheight > cursorY)
      if(between(bwidth*(i%2),cursorX, bwidth) && between( bheight*((i < 2)? 0 : 1),cursorY,bheight))  {
         
         return i;
      }
      

  return -1;
}


void onLightEvent(float v) //this just updates the light value
{
  light = v;
  if(light<=proxSensorThreshold)
    tapped = true;
}