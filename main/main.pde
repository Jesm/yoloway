int ENVIRONMENT_WIDTH = 640;
int LANE_NUMBER = 4;
int SIDEWALK_HEIGHT = 60;
int SIDEWALK_BORDER_HEIGHT = 15;
int SIDEWALK_COLOR = 225;
int LANE_HEIGHT = 46;
int LANE_DIVISION_HEIGHT = 5;
int LANE_DIVISION_SEGMENT_WIDTH = 40;
int LANE_DIVISION_SEGMENT_COLOR[] = {251, 188, 5};
int STREET_COLOR = 96;
int DIVISOR_HEIGHT = 40;
int CAR_WIDTH = 68;
int CAR_HEIGHT = 34;
int CAR_COLORS[][] = {{66, 133, 244}, {234, 67, 53}, {52, 168, 83}}; 
int CAR_VELOCITY_BASE = 160;
int CAR_VELOCITY_INCREASE = 30;
int PLAYER_WIDTH = 34;
int PLAYER_HEIGHT = 34;
int PLAYER_COLOR = 240;
int PLAYER_VELOCITY = 120;
String NOT_FOCUSED_TEXT = "Clique na tela para mover o personagem";
int TEXT_COLOR = 40;
int PLAYER_READY = 1;
int PLAYER_RAN_OVER = 2;
int PLAYER_SUCCESS = 3;

App app;

void setup(){
  size(640, 558);

  app = new App();  
}

void draw(){
  clear();
  app.draw();
}

void keyPressed(){
  app.setKeyPressStatus(keyCode, true);
}

void keyReleased(){
  app.setKeyPressStatus(keyCode, false);
}

class App{
  protected int level;
  protected Stage currentStage;
  protected KeyboardControl control;

  App(){
    level = 1;
    control = new KeyboardControl();

    setup();
  }
  
  protected void setup(){
    loadStage();
  }
  
  protected void loadStage(){    
    currentStage = new Stage(level);
  }

  void draw(){
    currentStage.process();
    currentStage.draw();
  }
  
  void setKeyPressStatus(int keyCode, boolean pressed){
    control.setKeyStatus(keyCode, pressed);
    currentStage.updatedControl(control);
  }
  
  void stageFinished(boolean success){
    if(success)
      level++;

    loadStage();
  }
}

class Stage{
  protected ArrayList<Object> objects;
  protected Object lanes[];
  protected int totalHeight;
  protected int lastTimestamp;
  protected Player player;
  protected int endGameInstant;

  Stage(int level){
    objects = new ArrayList<Object>();
    lastTimestamp = millis();
    endGameInstant = 0;
    
    setup(level);
  }
  
  void setup(int level){
    totalHeight = 0;
    int baseVelocity = CAR_VELOCITY_BASE + level * CAR_VELOCITY_INCREASE; 

    for(int x = 2; x-- > 0;){
      boolean isTop = x == 1;
      
      if(isTop){
        Sidewalk topSidewalk = new Sidewalk(true);
        addFreewayObject(topSidewalk);
        player = new Player(topSidewalk);
      }
      
      lanes = new Lane[LANE_NUMBER * 2];
      for(int y = LANE_NUMBER; y-- > 0;){
        Lane lane = new Lane(isTop ? PI : 0, baseVelocity, y > 0);
        lanes[LANE_NUMBER * (1 - x) + y] = lane;
        addFreewayObject(lane);
        lane.isEmpty();
      }

      if(isTop)
        addFreewayObject(new Divisor(level));
      else{
        Sidewalk bottomSidewalk = new Sidewalk(false);
        addFreewayObject(bottomSidewalk);
        
        float posX = (bottomSidewalk.getWidth() - player.getWidth()) / 2 + bottomSidewalk.getX();
        float posY = (bottomSidewalk.getHeight() - player.getHeight()) / 2 + bottomSidewalk.getY();
        player.setPosition(posX, posY);

        addObject(player);
      }
    }
  }
  
  void addFreewayObject(Object object){
    addObject(object);
    object.setPosition(0, totalHeight);
    totalHeight += object.getHeight();
  }
  
  void addObject(Object object){
    objects.add(object);
    object.setStage(this);
  }
  
  void process(){
    int timestamp = millis();
    int elapsed = timestamp - lastTimestamp;
    lastTimestamp = timestamp;
    
    if(player.getStatus() != PLAYER_READY){
      if(endGameInstant == 0)
        endGameInstant = millis();
      else if(millis() - endGameInstant > 2000)
        app.stageFinished(player.getStatus() == PLAYER_SUCCESS);

      return;
    }

    for(Object object : objects)
      moveObject(object, elapsed);
      
    verifyCollisions();
    verifyObjectsToRemove();
  }
  
  void moveObject(Object object, int elapsedTime){
    float increase = object.getVelocity() / 1000 * elapsedTime;
    float direction = object.getDirection();
    
    float x = object.getX() + cos(direction) * increase;
    float y = object.getY() + sin(direction) * increase;
    
    if(!object.canEscapeScreen()){
      x = min(max(x, 0), ENVIRONMENT_WIDTH - object.getWidth());
      y = min(max(y, 0), totalHeight - object.getHeight());
    }

    object.setPosition(x, y);
  }
  
  protected void verifyCollisions(){
    for(int x = 0, len = objects.size(); x < len; x++){
      Object current = objects.get(x);
      if(!current.verifiesCollision())
        continue;

      for(int y = x + 1; y < len; y++){
        Object comparison = objects.get(y);
        if(comparison.verifiesCollision() && current.isCollidingWith(comparison)){
          current.collidedWidth(comparison);
          comparison.collidedWidth(current);
        }
      }
    }
  }
  
  protected void verifyObjectsToRemove(){
    for(int size = objects.size(); size-- > 0;){
      if(objects.get(size).shouldRemove())
        objects.remove(size);
    }
  }

  void draw(){
    noStroke();
    for(Object object : objects){
      pushMatrix();
      pushStyle();

      translate(object.getX(), object.getY());
      object.draw();

      popStyle();
      popMatrix();
    }
  }
  
  void updatedControl(KeyboardControl control){
    float halfPi = 90;
    float pi = halfPi * 2;
    float twoPi = pi * 2;

    float degree = halfPi;
    if(control.left())
      degree += halfPi;
    if(control.right())
      degree -= halfPi;
  
    float halfDiff = (degree - halfPi) / 2;
    if(control.down())
      degree -= halfDiff;
    if(control.up())
      degree += degree == halfPi ? pi : halfDiff;

    player.setDirection(degree / twoPi * TWO_PI);
    player.setVelocity(degree % pi == halfPi && control.down() == control.up() ? 0 : PLAYER_VELOCITY);
  }
}

abstract class Object{
  protected Stage stage;
  protected float x, y, direction = 0, velocity = 0;

  abstract int getWidth();
  abstract int getHeight();
  abstract void draw();

  int getZIndex(){
    return 0;
  }

  void setPosition(float posX, float posY){
    x = posX;
    y = posY;
  }

  void setStage(Stage s){
    stage = s;
  }
  
  boolean isInsideOf(Object object){
    float objectX = object.getX();
    float objectY = object.getY();

    return x >= objectX
      && x + getWidth() < objectX + object.getWidth()
      && y >= objectY
      && y + getHeight() < objectY + object.getHeight();
  }

  boolean isCollidingWith(Object object){
    float objectX = object.getX();
    float objectY = object.getY();

    return x < objectX + object.getWidth()
      && x + getWidth() >= objectX
      && y < objectY + object.getHeight()
      && y + getHeight() >= objectY;
  }

  void setDirection(float d){
    direction = d;
  }

  void setVelocity(float v){
    velocity = v;
  }

  float getX(){
    return x;
  }
  
  float getY(){
    return y;
  }
  
  float getDirection(){
    return direction;
  }
  
  float getVelocity(){
    return velocity;
  }
  
  // OVERWRITE
  
  boolean shouldRemove(){
    return false;
  }
  
  boolean canEscapeScreen(){
    return true;
  }
  
  boolean verifiesCollision(){
    return false;
  }
  
  void collidedWidth(Object object){
    return;
  }
}

class Sidewalk extends Object{
  protected boolean top;
  
  Sidewalk(boolean t){
    top = t;
  }
  
  int getWidth(){
    return ENVIRONMENT_WIDTH;
  }

  int getHeight(){
    return SIDEWALK_HEIGHT;
  }
  
  void draw(){
    fill(SIDEWALK_COLOR);
    rect(0, 0, getWidth(), getHeight());
    int y = top ? getHeight() - SIDEWALK_BORDER_HEIGHT : SIDEWALK_BORDER_HEIGHT;

    stroke(170);
    line(0, y, getWidth(), y);
    
    for(int x = getWidth() + 20, height = getHeight(); x > 0; x -= 100)
      line(x, 0, x, height);
  }
}

class Lane extends Object{
  protected float carDirection;
  protected int carVelocity;
  protected boolean hasDivision;

  Lane(float cd, int velocity, boolean division){
    carDirection = cd;
    carVelocity = velocity;
    hasDivision = division;
  }

  int getWidth(){
    return ENVIRONMENT_WIDTH;
  }

  int getHeight(){
    return LANE_HEIGHT + (hasDivision ? LANE_DIVISION_HEIGHT : 0);
  }
  
  void isEmpty(){
    float velocity = random(carVelocity * .75, carVelocity * 1.25);
    Car car = new Car(this, carDirection, velocity);
    float x = carDirection == 0 ? 0 - car.getWidth() : getWidth();
    float y = (LANE_HEIGHT - car.getHeight()) / 2 + getY();
    car.setPosition(x, y);
    
    stage.addObject(car);
  }
  
  void draw(){
    fill(STREET_COLOR);
    rect(0, 0, getWidth(), getHeight());
    
    if(hasDivision){
      fill(LANE_DIVISION_SEGMENT_COLOR[0], LANE_DIVISION_SEGMENT_COLOR[1], LANE_DIVISION_SEGMENT_COLOR[2]);
      for(int x = -20, width = getWidth(), top = getHeight() - LANE_DIVISION_HEIGHT; x < width; x += 2 * LANE_DIVISION_SEGMENT_WIDTH)
        rect(x, top, LANE_DIVISION_SEGMENT_WIDTH, LANE_DIVISION_HEIGHT);
    }
  }
}

class Divisor extends Object{
  protected int level;

  Divisor(int l){
    level = l;
  }

  int getWidth(){
    return ENVIRONMENT_WIDTH;
  }

  int getHeight(){
    return DIVISOR_HEIGHT;
  }
  
  void draw(){
    fill(SIDEWALK_COLOR);
    rect(0, 0, getWidth(), getHeight());
    
    fill(TEXT_COLOR);
    textSize(20);
    String str = "Level " + level;
    float width = textWidth(str);
    text(str, (getWidth() - width) / 2, getHeight() / 2 + 7);
    
    if(!focused){
      textSize(12);
      text(NOT_FOCUSED_TEXT, getWidth() - 240, 12, getWidth() - 10, getHeight());
    }
  }
}

class Car extends Object{
  protected Lane lane;
  protected int bgColor[];
  
  Car(Lane l, float d, float v){
    lane = l;
    direction = d;
    velocity = v;
    bgColor = CAR_COLORS[int(random(CAR_COLORS.length))];
  }
  
  int getWidth(){
    return CAR_WIDTH;
  }

  int getHeight(){
    return CAR_HEIGHT;
  }
  
  boolean shouldRemove(){
    boolean remove = direction == 0 ? x >= lane.getWidth(): x + getWidth() <= 0;

    if(remove)
      lane.isEmpty();

    return remove;
  }
  
  boolean verifiesCollision(){
    return true;
  }
  
  void draw(){
    fill(bgColor[0], bgColor[1], bgColor[2]);
    rect(0, 0, getWidth(), getHeight());
  }
}

class Player extends Object{
  protected Sidewalk destination;
  protected int status;
  
  Player(Sidewalk d){
    destination = d;
    status = PLAYER_READY;
  }
  
  int getStatus(){
    return status;
  }

  int getWidth(){
    return PLAYER_WIDTH;
  }

  int getHeight(){
    return PLAYER_HEIGHT;
  }  
  
  boolean canEscapeScreen(){
    return false;
  } 
  
  boolean verifiesCollision(){
    return true;
  }
  
  void collidedWidth(Object object){
    if(status == PLAYER_READY)
      status = PLAYER_RAN_OVER;
  }
  
  boolean shouldRemove(){
    if(status == PLAYER_READY && isInsideOf(destination))
      status = PLAYER_SUCCESS;

    return false;
  }
  
  int getZIndex(){
    return 1;
  }
  
  void draw(){
    if(status == PLAYER_RAN_OVER && millis() % 200 < 100)
      return;

    fill(PLAYER_COLOR);
    stroke(48);
    rect(0, 0, getWidth(), getHeight());
  }
}

class KeyboardControl{
  boolean arrows[];
  
  KeyboardControl(){
    arrows = new boolean[4];
    for(int len = arrows.length; len-- > 0;)
      arrows[len] = false;
  }
  
  void setKeyStatus(int keyCode, boolean status){
    if(keyCode >= 37 && keyCode <= 41)
      arrows[keyCode - 37] = status;
  }
  
  boolean left(){
    return arrows[0];
  }
  
  boolean up(){
    return arrows[1];
  }
  
  boolean right(){
    return arrows[2];
  }
  
  boolean down(){
    return arrows[3];
  }
  
  boolean any(){
    for(int len = arrows.length; len-- > 0;){
      if(arrows[len])
        return true;
    }
    
    return false;
  }
}