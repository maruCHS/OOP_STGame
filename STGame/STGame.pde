class Timer {
  private double baseTime;
  private boolean first = true;
  Timer() {
    baseTime = millis();
  }
  double getMilTime() {
    return millis() - baseTime;
  }
  double getCntOfFrames() {
    return glo_frameRate * getMilTime()/1000.0;
  }
  void resetTimer() {
    baseTime = millis();
  }
  boolean isFirstCall() {
    return first ? !(first = false) : false;
  }
}
class Danmaku { 
  private ArrayList<Projectile> projectiles = new ArrayList<>();
  private void display() {
    for(int i = 0; i < projectiles.size(); i++)  projectiles.get(i).display();
  }
  private void move() {
    for(int i = 0; i < projectiles.size(); i++) projectiles.get(i).move();
  }
  private void add(Projectile p) {
    projectiles.add(p);
  }
  private void add(ArrayList<Projectile> ps) {
    projectiles.addAll(ps);
  }
  private void deleteOutOfField() {
    for(int i = projectiles.size() - 1; i >= 0; i--) {
      Projectile p = projectiles.get(i);
      if(!p.isInside()) projectiles.remove(i);
    }
  }
  private boolean isEmpty() {
    return projectiles.isEmpty();
  }
}
abstract class Projectile {
  protected double x, y, size, speed, rad;
  protected int figId;
  protected Timer t;
  protected double sx, sy, cx, cy;
  protected color col;
  Projectile (double x0, double y0, double size0, double speed0, double rad0, int figId0, color col0) {
    x = x0; y = y0; size = size0; speed = speed0; rad = rad0; figId = figId0;
    t = new Timer();
    sx = x0; sy = y0; cx = 0; cy = 0; col = col0;
  }
  private void display() {
    fill(255);
    pushMatrix();
    translate((float)sx, (float)sy);
    rotate((float)rad);
    printFig();
    popMatrix();
  }
  private void printFig() {
    if(figId == 0) {
      fill(col); circle((float)cx, (float)cy, (float)size * 1.25);
      fill(255); circle((float)cx, (float)cy, (float)size);
    }
    else rect((float)cx, (float)cy, (float)size*2, (float)size);
  }
  abstract void move();
  protected void setXY() {
    if(cx >= 0) {
      x = sqrt(pow((float)cx, 2) + pow((float)cy, 2))*cos((float)rad) + sx; y = sqrt(pow((float)cx, 2) + pow((float)cy, 2))*sin((float)rad) + sy;
    }else{
      x = sqrt(pow((float)cx, 2) + pow((float)cy, 2))*cos((float)rad + PI) + sx; y = sqrt(pow((float)cx, 2) + pow((float)cy, 2))*sin((float)rad+ PI) + sy;
    }
  }
  private boolean isInside() {
    double tolerance = 50;
    return (-tolerance < x && x < width + tolerance && - tolerance < y && y < height + tolerance);
  }
}
class ULinearP extends Projectile {
  ULinearP(double x0, double y0, double size0, double speed0, double rad0, int figId0, color col0) {
    super(x0, y0, size0, speed0, rad0, figId0, col0);
  }
  void move() {
    cx = t.getCntOfFrames() * speed;
    setXY();
  }
}
abstract class GameObject {
  protected double x, y;
  abstract protected void display();
}
abstract class Unit extends GameObject {
  protected double size;
  protected Danmaku danmaku;
  protected boolean isAlive;
  protected Timer unitTimer = new Timer();
  Unit() {
    danmaku = new Danmaku(); isAlive = true;
  }
  protected boolean isColided(Danmaku opponentDanmaku) {
    if(isAlive) {
      boolean flag = false;
      ArrayList<Projectile> ops = opponentDanmaku.projectiles;
      for (int i = ops.size() - 1; i >= 0; i--) {
        Projectile op = ops.get(i);
        double d = dist((float)x, (float)y, (float)op.x, (float)op.y);
        if(d <= (size + op.size)/2) {
          ops.remove(i);
          return true;
        }
      }
    }
    return false;
  }
  protected void genOneDan(double x, double y, double size, double speed, double fireRad, int figId, color col) {
    danmaku.add(new ULinearP(x, y, size, speed, fireRad, figId, col));
  }
  protected void genNWaysDan(double x, double y, double size, double speed, double fireRad, double spanRad, int n, int figId, color col) {
    for(int i = 0; i < n; i++) {
      double baseRad = fireRad - (n-1) * spanRad / 2;
      danmaku.add(new ULinearP(x, y, size, speed, baseRad + spanRad * i, figId, col));
    }
  }
  protected void genAllDirectionsDan(double x, double y, double size, double speed, double rad, int n, int figId, color col) {
    for(int i = 0; i < n; i++) danmaku.add(new ULinearP(x, y, size, speed, rad + 2*PI*i/n, figId, col));
  }
}
class PlayerUnit extends Unit {
  private int numSubUnits, zanki = 3, mutekiTime = 3000;
  private boolean isAlive, muteki, displayPhase;
  private ArrayList<SubUnit> subUnits = new ArrayList<>();
  private double step = 8, slowStep = 4, angSpan = PI/18, angStep = PI/120, maxAngSpan = PI/18, minAngSpan = PI/72;
  private Timer mutekiTimer, efTimer;
  PlayerUnit() {
    super();
    x = width/2; y = height * 2 / 3; numSubUnits = 5; size = 15;
    for(int i = 0; i < numSubUnits; i++) addSubUnit(2*PI / numSubUnits * i);
    isAlive = true; muteki = false; displayPhase = false;
    mutekiTimer = new Timer(); efTimer = new Timer();
  }
  void update(ArrayList<EnemyUnit> enemies) {
    if(!muteki) {
      for(int i = 0; i < enemies.size(); i++) {
        Unit curEnemyUnit = enemies.get(i);
        if(!muteki && isColided(curEnemyUnit.danmaku)) {
          if(zanki == 0) isAlive = false;
          zanki--;
          muteki = true;
          efTimer.resetTimer(); mutekiTimer.resetTimer();
        }
      }
    }
    commandSubUnit(); shoot(); display(); move();
  }
  protected void display() {
    int efTime = 250;
    if(muteki) {
      if(efTimer.getMilTime() > efTime) {
        displayPhase = !displayPhase;
        efTimer.resetTimer();
      }
      if(mutekiTimer.getMilTime() > mutekiTime) {
        displayPhase = true;
        muteki = false;
      }
      if(!displayPhase) return;
    }
    fill(fBlack); circle((float)x, (float)y, (float)size);
    fill(fWhite); circle((float)x, (float)y, (float)size* 0.8);
  }
  private void move() {
    if(glo_keyState[0] && y >= 0)  y -= (!glo_keyState[4] ? step : slowStep);
    if(glo_keyState[1] && y <= height)  y += (!glo_keyState[4] ? step : slowStep);
    if(glo_keyState[2] && x >= 0)  x -= (!glo_keyState[4] ? step : slowStep);
    if(glo_keyState[3] && x <= width)  x += (!glo_keyState[4] ? step : slowStep);
  }
  private void shoot() {
    if(glo_keyState[4]) {
      angSpan -= angStep; 
      angSpan = max((float)minAngSpan, (float)angSpan);
    }else{
      angSpan += angStep;
      angSpan = min((float)angSpan, (float)maxAngSpan);
    }
    if(glo_keyState[8]) {
      if(unitTimer.getMilTime() >= 20) {
        genNWaysDan(x, y, 7, 20, -PI/2, angSpan, 3, 1, fWhite);
        unitTimer.resetTimer();
      }
    }
    danmaku.display(); danmaku.move(); danmaku.deleteOutOfField();
  }
  private void addSubUnit(double rad) {
    SubUnit newSubUnit = new SubUnit(rad);
    subUnits.add(newSubUnit);
  }
  private void commandSubUnit() {
    for(int i = 0; i < numSubUnits; i++) {
      SubUnit temp = subUnits.get(i);
      temp.setMainUnitLoc(x, y); temp.update();
    }
  }
  double getX() {return x;}
  double getY() {return y;}
  int getNumSubUnits() {return numSubUnits;}
  ArrayList<SubUnit> getSubUnits() {return new ArrayList<>(subUnits);}
  int getZanki() {return zanki;}
  boolean getIsAlive() {return isAlive;}
}
class SubUnit extends Unit {
  private double size = 10,maxDist = 50, minDist = 25, distFromPlayer = 50, dStep = 4, mainUnitX, mainUnitY, rad;
  SubUnit(double rad0) {
    x = distFromPlayer*cos((float)rad); y = distFromPlayer*sin((float)rad); rad = rad0;
  }
  void setMainUnitLoc(double px, double py) {
    mainUnitX = px; mainUnitY = py;
  }
  void update() {
    shoot(); display(); move();
  }
  protected void display() {
    x = distFromPlayer*cos((float)rad); y = distFromPlayer*sin((float)rad);
    pushMatrix();
    translate((float)mainUnitX, (float)mainUnitY);
    fill(200);
    rect((float)(x), (float)(y), 10, 10);
    popMatrix();
  }
  private void move() {
    if(glo_keyState[4]) {
      distFromPlayer = max((float)minDist, (float)distFromPlayer);
      distFromPlayer -= dStep;
    }else{
      distFromPlayer = min((float)distFromPlayer, (float)maxDist);
      distFromPlayer += dStep;
    }
    rad += PI/120.0;
    rad %= 2 * PI;
  }
  private void shoot() {
    if(glo_keyState[8]) {
      if(unitTimer.getMilTime() >= 20) {
        genOneDan(mainUnitX + x, mainUnitY + y, 5, 20, -PI/2, 0, fWhite);
        unitTimer.resetTimer();
      }
    }
    danmaku.display(); danmaku.move(); danmaku.deleteOutOfField();
  }
}
class EnemyUnit extends Unit {
  private Timer t, pauseTimer;
  protected int life;
  private int waypointsIndex, maxWaypointIndex;
  private double speed, rad, sx, sy, cx, cy, curWaypointX, curWaypointY;
  private double[][] waypoints;
  private boolean isPaused, isActive, hasPauseBeenTriggered, isMovable;  
  protected PlayerUnit player;
  EnemyUnit(double x0, double y0, double size0, double speed0, double[][] waypoints0) {
    super();
    x = x0; y = y0; sx = x0; sy = y0; cx = 0; cy = 0; size = size0; speed = speed0; waypoints = waypoints0; life = 1;
    t = new Timer(); pauseTimer = new Timer(); danmaku = new Danmaku(); 
    isAlive = true; isActive = true; hasPauseBeenTriggered = false; isPaused = false; isMovable = true;
    waypointsIndex = 0; maxWaypointIndex = waypoints.length - 1;
    curWaypointX = waypoints[0][0]; curWaypointY = waypoints[0][1];
  }
  void update() {
    drawDanmaku();
    if(isAlive) {
      if(isColided(player.danmaku)) applyDamage();
      ArrayList<SubUnit> playerSubUnits = player.getSubUnits();
      for(int i = 0; i < player.getNumSubUnits(); i++) if(isColided(playerSubUnits.get(i).danmaku)) applyDamage();
      if(!isInField()) isAlive = false;
      act(); display();
    }else{
      isActive = !danmaku.isEmpty();
    }
  }
  private void applyDamage() {
    if(life > 0) life--;
    else isAlive = false;
  }
  void display() {
    pushMatrix();
    translate((float)sx, (float)sy);
    rotate((float)rad);
    fill(fBlack);
    circle((float)cx, (float)cy, (float)size);
    fill(fWhite);
    circle((float)cx, (float)cy, (float)size*0.8);
    popMatrix();
  }
  protected void shootOnPause() {}; protected void shootJustOnPause() {}; protected void shootDurMoving() {}; protected void shootConstantly() {};  //抽象メソッドにはしない
  private void drawDanmaku() {
    danmaku.display(); danmaku.move(); danmaku.deleteOutOfField();
  }
  private void act() {
    if(isMovable) {
      if(isPaused) {
        if(!hasPauseBeenTriggered) {
          shootJustOnPause(); pauseTimer.resetTimer();
          hasPauseBeenTriggered = true;
        }
        if(pauseTimer.getMilTime() >= waypoints[waypointsIndex][2]) {
          if(waypointsIndex == maxWaypointIndex) {
            isMovable = false;
          }else{
            waypointsIndex++;
            sx = curWaypointX; sy = curWaypointY; cx = 0; cy = 0; curWaypointX = waypoints[waypointsIndex][0]; curWaypointY = waypoints[waypointsIndex][1];
            isPaused = false; hasPauseBeenTriggered = false;
            pauseTimer.resetTimer();
          }
        }
        shootOnPause();
      }else{
        double d = dist((float)x, (float)y, (float)curWaypointX, (float)curWaypointY);
        if(d <= speed) {
          isPaused = true;
        }else{
          moveTo(curWaypointX, curWaypointY);
        }
        shootDurMoving();
      }
    }
    shootConstantly();
  }
  private void moveTo(double curWpX, double curWpY) {
    rad = atan2((float)(curWpY - sy), (float)(curWpX - sx));
    cx += speed;
    setXYFromCXY();
  }
  private boolean isInField() {
    double tolerance = size/2;//50;
    return !(x <= -tolerance || x >= width + tolerance || y <= -tolerance || y >= height + tolerance);
  }
  protected void setXYFromCXY() {
    x = sqrt(pow((float)cx, 2) + pow((float)cy, 2))*cos((float)rad) + sx; y = sqrt(pow((float)cx, 2) + pow((float)cy, 2))*sin((float)rad) + sy;
  }
  void setPlayer(PlayerUnit player0) {
    player = player0;
  }
  boolean getActivityState() {return isActive;}
}
class NormEn1 extends EnemyUnit {
  private Timer[] shootOnPauseTimer;
  NormEn1(double x0, double y0, double size0, double speed0, double[][] waypoints0) {
    super(x0, y0, size0, speed0, waypoints0);
    life = 15;
    shootOnPauseTimer = new Timer[2]; shootOnPauseTimer[0] = new Timer(); shootOnPauseTimer[1] = new Timer();
  } 
  protected void shootJustOnPause() {
    double toP = atan2((float)(player.getY() - y), (float)(player.getX() - x));
    genNWaysDan(x, y, 10, 5, toP, PI/192, 13, 0, fMagenta);
    shootOnPauseTimer[1].resetTimer();    
  }
}
class NormEn2 extends EnemyUnit {
  private Timer[] shootOnPauseTimer;
  NormEn2(double x0, double y0, double size0, double speed0, double[][] waypoints0) {
    super(x0, y0, size0, speed0, waypoints0);
    life = 20;
    shootOnPauseTimer = new Timer[2]; shootOnPauseTimer[0] = new Timer(); shootOnPauseTimer[1] = new Timer();
  }
  protected void shootOnPause() {
    if(shootOnPauseTimer[0].isFirstCall() || shootOnPauseTimer[0].getMilTime() >= 1000) {
      double toP = atan2((float)(player.getY() - y), (float)(player.getX() - x));
      genAllDirectionsDan(x, y, 20, 3, toP, 24, 0, fBlue);
      shootOnPauseTimer[0].resetTimer();
    }
    if(shootOnPauseTimer[1].isFirstCall() || shootOnPauseTimer[1].getMilTime() >= 1600) {
      double toP = atan2((float)(player.getY() - y), (float)(player.getX() - x));
      genAllDirectionsDan(x, y, 30, 4, toP, 4, 0, fRed);
      shootOnPauseTimer[1].resetTimer();
    }
  }
}
class NormEn3 extends EnemyUnit {
  private Timer shootDurMoving;
  NormEn3(double x0, double y0, double size0, double speed0, double[][] waypoints0) {
    super(x0, y0, size0, speed0, waypoints0);
    life = 3;
    shootDurMoving = new Timer();
  }
  protected void shootJustOnPause() {
    genAllDirectionsDan(x, y, 10, 3, 0, 32, 0, fCyan);
  }
}
class LargeEn extends EnemyUnit {
  private Timer[] shootOnPauseTimer;
  LargeEn(double x0, double y0, double size0, double speed0, double[][] waypoints0) {
    super(x0, y0, size0, speed0, waypoints0);
    life = 150;
    shootOnPauseTimer = new Timer[2]; shootOnPauseTimer[0] = new Timer(); shootOnPauseTimer[1] = new Timer();
  }
  protected void shootOnPause() {
    if(shootOnPauseTimer[0].isFirstCall() || shootOnPauseTimer[0].getMilTime() >= 200) {
      double toP = atan2((float)(player.getY() - y), (float)(player.getX() - x));
      genAllDirectionsDan(x, y, 20, 5, toP, 18, 0, fRed);
      shootOnPauseTimer[0].resetTimer();
    }
    if(shootOnPauseTimer[1].isFirstCall() || shootOnPauseTimer[1].getMilTime() >= 100) {
      double toP = atan2((float)(player.getY() - y), (float)(player.getX() - x));
      genOneDan(x, y, 20, 8, toP, 0, fGreen);
      shootOnPauseTimer[1].resetTimer();
    }
  }
  protected void shootJustOnPause() {
    double toP = atan2((float)(player.getY() - y), (float)(player.getX() - x));
    genAllDirectionsDan(x, y, 30, 4, toP, 64, 0, fYellow);
  }
}
abstract class Wave {
  private Timer waveTimer, spawnTimer;
  private int round, startTime, span, enId;
  Wave(int round0, int startTime0, int span0, int enId0) {
    round = round0; startTime = startTime0; span = span0; enId = enId0;
    waveTimer = new Timer(); spawnTimer = new Timer();
  }
  void update() {
    spawnEnemy();
  }
  protected void spawnEnemy() {
    if(round > 0 && spawnTimer.getMilTime() > startTime) {
      if(waveTimer.isFirstCall() || waveTimer.getMilTime() >= span) {
        genEnemy();
        round--;
        waveTimer.resetTimer();
      }
    }
  }
  abstract protected void genEnemy();
}
class WaveA extends Wave {
  WaveA(int round0, int startTime0, int span0, int enId0) {
    super(round0, startTime0, span0, enId0);
  }
  protected void genEnemy() {
    float sp = height/6 / 10;
    for(int i = 0; i < 7; i++) {
      enemies.add(new NormEn1(width/8*(i+1), 0, sp, 4, new double[][] {{width/8*(i+1), height/6, 500}, {width/8*(i+1), height/3, 500}, {width/8*(i+1), height/2, 500}, {width/8*(i+1), height/8, 500}, {width/8*(i+1), -50, 500}}));
    }
  }
}
class WaveB extends Wave {
  WaveB(int round0, int startTime0, int span0, int enId0) {
    super(round0, startTime0, span0, enId0);
  }
  protected void genEnemy() {
    for(int i = 1; i <= 6; i++) {
      enemies.add(new NormEn2(width,   height/8, 20, 8*0.2*(7-i), new double[][] {{width/7*i, height/8, 10000}, {width+50, height/8, 10000}}));
      enemies.add(new NormEn2(    0,   height/4, 20, 8*0.2*i,     new double[][] {{width/7*i, height/4, 10000}, {-50, height/4, 10000}}));
      enemies.add(new NormEn2(width, height*3/8, 20, 8*0.2*(7-i), new double[][] {{width/7*i, height*3/8, 10000}, {width+50, height*3/8, 10000}}));
    }
  }
}
class WaveC1 extends Wave{ 
  WaveC1(int round0, int startTime0, int span0, int enId0) {
    super(round0, startTime0, span0, enId0);
  }
  protected void genEnemy() {
    enemies.add(new LargeEn(  width/5, 0, 30, 4, new double[][] {{  width/5, height/3,  2000}, {width/2, height/6, 2000}, {width*4/5, height/3, 2000}, {width/2, height/2, 2000}, {  width/5, height/3, 2000}, {width/5, -50, 2000}}));
    enemies.add(new LargeEn(width*4/5, 0, 30, 4, new double[][] {{width*4/5, height/3,  2000}, {width/2, height/2, 2000}, {  width/5, height/3, 2000}, {width/2, height/6, 2000}, {width*4/5, height/3, 2000}, {width*4/5, -50, 2000}}));
  }
}
class WaveC2 extends Wave{
  WaveC2(int round0, int startTime0, int span0, int enId0) {
    super(round0, startTime0, span0, enId0);
  }
  protected void genEnemy() {
    double ranX = random(width/8, width*7/8), ranY = random(height/6, height/2), ranSp = random(3, 6);
    enemies.add(new NormEn3(ranX, 0, 20, ranSp, new double[][] {{ranX, ranY, 100}, {ranX, -50, 10000}}));
  }
}


Title title;
ArrayList<Wave> waves;
PlayerUnit jiki;
ArrayList<EnemyUnit> enemies;
boolean[] glo_keyState = new boolean[16];//0-3:上下左右 4:低速モード 8:射撃
boolean glo_isClicked;
int glo_gameSeq, glo_frameRate, glo_maxZanki, glo_defeatedLEnCnt, glo_maxLEnCnt;
final color fWhite = color(255), fRed = color(255, 0, 0), fBlue = color(0, 0, 255), fGreen = color(0, 255, 0), fGray = color(127), fYellow = color(255, 255, 0), fMagenta = color(255, 0, 255), fCyan = color(0, 255, 255), fBlack = color(0);
void setup() {
  glo_frameRate = 60; glo_gameSeq = 0; glo_isClicked = false; glo_maxZanki = 3; glo_defeatedLEnCnt = 0; glo_maxLEnCnt = 2;
  size(800, 1200);
  frameRate(glo_frameRate); rectMode(CENTER); imageMode(CENTER); textAlign(CENTER); noStroke();
  for(int i = 0; i < 16; i++)  glo_keyState[i] = false;  
  title = new Title(); jiki = new PlayerUnit(); enemies = new ArrayList<>(); waves = new ArrayList<>(); 
}
class Title {
  private int colVal, dCol;
  private boolean isClicked;
  Title() {
    colVal = 215; dCol = 5; isClicked = false;
  }
  private void display() {
    background(255); textAlign(CENTER, BASELINE); fill(fBlack);
    textSize(60); text("Danamku Shooting Game!!!", width/2, height/5);
    textSize(50); text("How to play", width/2, height/3);
    textSize(20); text("direction key : MOVE", width/2, height/3 + 50); text("shift : SLOW MOVE",  width/2, height/3 + 150); text("x : SHOOT", width/2, height/3 + 100);
    fill(color(colVal));
    textSize(30);
    text("~~click to start!~~", width/2, height*2/3);
  }
  private void update() {
    display();
    colVal -= dCol;
    isClicked = glo_isClicked; //mousePressed()を使うため，セッターは用いない
    if(colVal < 40 || colVal > 215) dCol *= -1;
  }
  private boolean getIsClicked() {
    return isClicked;
  }
}
void draw() {
  if(glo_gameSeq == 0) {
    title.update();
    if(title.getIsClicked()) {
      WaveA w1 = new WaveA(4, 2000, 1000, 1); WaveB w2 = new WaveB(1, 12000, 1000, 1); WaveC1 w3 = new WaveC1(1, 24000, 0, 1); WaveC2 w4 = new WaveC2(60, 24500, 250, 1);
      waves.add(w1);waves.add(w2);waves.add(w3);waves.add(w4);
      glo_gameSeq = 1;
    }
  }
  if(glo_gameSeq == 1) {
    background(40, 40, 40, 10);
    jiki.update(enemies);
    for(int i = 0; i < waves.size(); i++) {
      Wave w = waves.get(i);
      w.update();
    }
    for(int i = 0; i < enemies.size(); i++) {
      EnemyUnit en = enemies.get(i);
      en.setPlayer(jiki);
      en.update();
      if(!en.getActivityState()) {
        if(en instanceof LargeEn) glo_defeatedLEnCnt++;
        enemies.remove(i);
      }                                    
    }
    zankiUI(jiki.getZanki());
    if(!jiki.getIsAlive()) glo_gameSeq = 2;
    if(glo_defeatedLEnCnt == glo_maxLEnCnt && enemies.isEmpty()) glo_gameSeq = 3;
  }else if(glo_gameSeq == 2) {
    background(20); fill(fRed); textAlign(CENTER); textSize(100); text("Game Over...", width/2, height/2);
    noLoop();
  }else if(glo_gameSeq == 3) {
    background(235); fill(fGreen); textAlign(CENTER); textSize(100); text("You Win!!!", width/2, height/2);
    noLoop();
  }
}
void zankiUI(int zanki) {
  int efDia = 20;
  String s = "Your Life:";
  float xw = width - textWidth(s);
  textSize(20);
  textAlign(RIGHT,CENTER);
  text("Your Life:", xw, height-efDia/2);
  for(int i = 0; i < jiki.getZanki(); i++) {
    fill(fRed);
    circle(width + efDia*(i - glo_maxZanki), height - efDia/2, efDia);
  }
}
void mousePressed() {
  glo_isClicked = true;
}
void keyPressed() {
  if(keyCode == UP)   glo_keyState[0] = true;
  if(keyCode == DOWN) glo_keyState[1] = true;
  if(keyCode == LEFT) glo_keyState[2] = true;
  if(keyCode == RIGHT) glo_keyState[3] = true;
  if(keyCode == SHIFT) glo_keyState[4] = true;
  if(key == 'x' || key == 'X') glo_keyState[8] = true;
}
void keyReleased() {
  if(keyCode == UP)   glo_keyState[0] = false;
  if(keyCode == DOWN) glo_keyState[1] = false;
  if(keyCode == LEFT) glo_keyState[2] = false;
  if(keyCode == RIGHT) glo_keyState[3] = false;
  if(keyCode == SHIFT) glo_keyState[4] = false;
  if(key == 'x' || key == 'X') glo_keyState[8] = false;
}
/*
class UCurveP extends Projectile {
  double angVelo;
  UCurveP(double x0, double y0, double size0, double speed0, double rad0, int figId0, double angVelo0, color col0) {
    super(x0, y0, size0, speed0, rad0, figId0, col0);
    angVelo = angVelo0;
  }
  void move() {
    cx = t.getCntOfFrames() * speed;
    rad = rad + t.getCntOfFrames() * angVelo;
    setXY();
  }
}
class UAcceleP extends Projectile {
  double cxac;
  UAcceleP(double x0, double y0, double size0, double speed0, double rad0, int figId0, double cxac0,  color col0) {
    super(x0, y0, size0, speed0, rad0, figId0, col0);
    cxac = cxac0;
  }
  void move() {
    double sec = t.getCntOfFrames();
    cx = speed*sec + cxac*sec*sec/2.0;
    setXY();
  }
}
class Wave2 extends Wave {
  Wave2(int round0, int startTime0, int span0, int enId0) {
    super(round0, startTime0, span0, enId0);
  }
  void genEnemy() {
    enemies.add(new NormEn1(0, height/3, 20, 3, new double[][] {{width/5, height/6, 0},{width*2/5, height/3, 0}, {width*3/5, height/6, 0}, {width*4/5, height/3, 0}, {width*4/5, height/3,0},{width+50, height/6, 0}}));
  }
}
class Wave3 extends Wave {
  Wave3(int round0, int startTime0, int span0, int enId0) {
    super(round0, startTime0, span0, enId0);
  }
  void genEnemy() {
    enemies.add(new NormEn1(width, height/3, 20, 3, new double[][] {{width*4/5, height/6, 0},{width*3/5, height/3, 0}, {width*2/5, height/6, 0}, {width/5, height/3, 0}, {0, height/6,0},{-50, height/6, 0}}));
  }
}
class HomingP extends Projectile {
  double limAng;
  double playerX, playerY;
  HomingP(double x0, double y0, double size0, double speed0, double rad0, int figId0, double limAng0, color col0) {
    super(x0, y0, size0, speed0, rad0, figId0, col0);
    limAng = limAng0;
  }
  private void setPlayerXY(PlayerUnit player) {
    playerX = player.getX();
    playerY = player.getY();
  }
  void move() {
    double toPlayerAng = atan2((float)(playerX-x), (float)(playerY-y));
    double cang;
    if(toPlayerAng >= rad) {
      cang = min((float)toPlayerAng, (float)(limAng + rad));
    }else{
      cang = max((float)toPlayerAng, (float)(limAng + rad));
    }
    rad = cang;
  }
}
abstract class Projectile extends Stuff {
  double tolerance = 50;
  double sx, sy, rad, speed, size;
  double cx, cy;
  Projectile(double x0, double y0, double size0, double speed0, double rad0) {
    x = x0;
    y = y0;
    sx = x0;
    sy = y0;
    rad = rad0;
    cx = 0;
    cy = 0;
    speed = speed0;
    size = size0;
  }
  abstract void drawFig();

  void display() {
    fill(255);
    translate((float)sx, (float)sy);
    rotate((float)rad);
    drawFig();
    rotate(-(float)rad);
    translate( -(float)sx, -(float)sy);
  }
  
  void move() {
    cy -= speed;
    x = sqrt(pow((float)cx, 2) + pow((float)cy, 2))*sin((float)rad) + sx;
    y = -sqrt(pow((float)cx, 2) + pow((float)cy, 2))*cos((float)rad) + sy;
  }

  boolean isInside() {
    if(x <= -tolerance || width + tolerance <= x 
    || y <= -tolerance || height + tolerance <= y ) {
      return false;
    }
    return true;
  }

  double getProjectileX() {
    return x;
  }
  double getProjectileY() {
    return y;
  }
}
class Bullet extends Projectile {
  Bullet(double x0, double y0, double size0, double speed0, double rad0) {
    super(x0, y0, size0, speed0, rad0);
  }
  void drawFig() {
    rect(0, (float)cy, (float)size, (float)size*2);
  }
}
class Orb extends Projectile {
  Orb(double x0, double y0, double size0, double speed0, double rad0) {
    super(x0, y0, size0, speed0, rad0);
  }
  void drawFig() {
    circle(0, (float)cy, (float)size);
  } 
}
abstract class DropItem extends Stuff {
  boolean isInside() {
    return true;
  }
}
class ScoreItem extends DropItem {
  void display() {
  }
}
class ExpItem extends DropItem {
  void display() {
  }
}
*/


/*class GameProgress {
  Timer gameTimer;
  boolean[] waves
  boolean bossBattle;

  PlayerUnit jiki = new PlayerUnit();
  ArrayList<EnemyUnit> enemies = new ArrayList<>();


  GameProgress() {
    waves = new boolean[3];
    for(int i = 0; i < waves.length(); i++) {
      waves[i] = false;
    }
    bossBattle = false;
  }

  void updata() {
    if(gameTimer >= 3000) {
      wave1 = new Wave1();
    }
  }
  void progress() {
    if(!waves[0]) {
      waves[0] = true;
    }else if(!waves[1]) {

    }else if(!waves[2]) {
      
    }else if(!waves[3]) {
      
    }else if(!waves[4]) {
      
    }
  }
  void stage1() {

  }
}
class Wave1 {
  Timer timer = new Timer();
  Timer spawn = new Timer();
  boolean[] spawned
  ArrayList<EnemyUnit> enemies = new ArrayList<>();
  Wave1() {
    spawned = new boolean[3];
    for(int i = 0; i < tern.length(); i++) {
      tern[i] = false;
    }
  }

  void spawnEnemies() {
    if(!spawned[0] && timer.getMilTime() >= 1000) {
      enemies.add(new NEnemy1(width/5, 0, 10, 3, PI));
      enemies.add(new NEnemy1(width*4/5, 0, 10, 3, PI));
      spawned[0] = true;
    }
    if(!spawned[1] && timer.getMilTime() >= 1500) {
      enemies.add(new NEnemy1(width/5, 0, 10, 3, PI));
      enemies.add(new NEnemy1(width*4/5, 0, 10, 3, PI));
      spawned[1] = true;
    }
    if(!spawned[2] && timer.getMilTime() >= 2000) {
      enemies.add(new NEnemy1(width/5, 0, 10, 3, PI));
      enemies.add(new NEnemy1(width*4/5, 0, 10, 3, PI));
      spawned[2] = true;
    }
  }

}

static class LinearProjectile extends Projectile {
  LinearProjectile(double x0, double y0, double size0, double speed0, double rad0, int figId0) {
    super(x0, y0, size0, speed0, rad0, figId0);
  }
  void move() {
    cy -= speed;
    x = sqrt(pow((float)cx, 2) + pow((float)cy, 2))*sin((float)rad) + sx;
    y = -sqrt(pow((float)cx, 2) + pow((float)cy, 2))*cos((float)rad) + sy;
  }
}
static class TrackingProjectile extends Projectile {
  TrackingProjectile(double x0, double y0, double size0, double speed0, double rad0, int figId0) {
    super(x0, y0, size0, speed0, rad0, figId0);
  }
  void move() {

  }
}



*/
