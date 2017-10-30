int ENVIRONMENT_WIDTH = 800;
int LANE_NUMBER = 4;
int SIDEWALK_HEIGHT = 60;
int SIDEWALK_BORDER_HEIGHT = 15;
int SIDEWALK_COLOR = 225;
int LANE_HEIGHT = 46;
int LANE_DIVISION_HEIGHT = 5;
int LANE_DIVISION_SEGMENT_WIDTH = 40;
int LANE_DIVISION_SEGMENT_COLOR[] = {251, 188, 5};
int STREET_COLOR = 96;
int DIVISOR_HEIGHT = 30;

App app;

void setup(){
  size(800, 550);

  app = new App();  
}

void draw(){
  app.draw();
}

class App{
  protected int level;
  protected Stage currentStage;
  
  App(){
    level = 1;

    setup();
  }
  
  protected void setup(){
    loadStage();
  }
  
  protected void loadStage(){    
    currentStage = new Stage(level);
  }

  void draw(){
    currentStage.draw();
  }
  
  void loadNextStage(){
    level++;
    loadStage();
  }
}

class Stage{
  protected ArrayList<Object> objects;
  protected Object lanes[];
  protected int totalHeight;

  Stage(int level){
    objects = new ArrayList<Object>();

    setupFreeway();
  }
  
  void setupFreeway(){
    totalHeight = 0;

    for(int x = 2; x-- > 0;){
      boolean isTop = x == 1;
      
      if(isTop)
        addFreewayObject(new Sidewalk(isTop));
      
      lanes = new Lane[LANE_NUMBER * 2];
      for(int y = LANE_NUMBER; y-- > 0;){
        Lane lane = new Lane(y > 0);
        lanes[LANE_NUMBER * (1 - x) + y] = lane;
        addFreewayObject(lane);
      }

      if(isTop)
        addFreewayObject(new Divisor());
      else
        addFreewayObject(new Sidewalk(isTop));
    }
  }
  
  void addFreewayObject(Object object){
    objects.add(object);
    object.setPosition(0, totalHeight);
    totalHeight += object.getHeight();
  }
  
  void process(){
    // TODO
  }

  void draw(){
    ArrayList<Object> sortedObjects = objects; // TODO SORT
    noStroke();
    for(Object object : sortedObjects){
      pushMatrix();
      pushStyle();

      translate(object.getX(), object.getY());
      object.draw();
      
      popStyle();
      popMatrix();
    }
  }
}

abstract class Object{
  protected int x;
  protected int y;

  abstract int getWidth();
  abstract int getHeight();
  abstract void draw();

  int getZIndex(){
    return 0;
  }
  
  void setPosition(int x, int y){
    setX(x);
    setY(y);
  }
  
  void setX(int posX){
    x = posX;
  }
  
  void setY(int posY){
    y = posY;
  }
  
  int getX(){
    return x;
  }
  
  int getY(){
    return y;
  }
  
  boolean shouldRemove(){
    return false;
  }
  
  boolean isOutOfView(int width, int height){
    return false; // TODO
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

    stroke(92);
    line(0, y, getWidth(), y);
  }
}

class Lane extends Object{
  protected boolean hasDivision;

  Lane(boolean division){
    hasDivision = division;
  }

  int getWidth(){
    return ENVIRONMENT_WIDTH;
  }

  int getHeight(){
    return LANE_HEIGHT + (hasDivision ? LANE_DIVISION_HEIGHT : 0);
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
  int getWidth(){
    return ENVIRONMENT_WIDTH;
  }

  int getHeight(){
    return DIVISOR_HEIGHT;
  }
  
  void draw(){
    fill(SIDEWALK_COLOR);
    rect(0, 0, getWidth(), getHeight());
  }
}