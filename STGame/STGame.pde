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
    return FRAMERATE * getMilTime()/1000.0;
  }
  void resetTimer() {
    baseTime = millis();
  }
  boolean isFirstCall() {
    return first ? !(first = false) : false;
  }
}
interface MovableObject {
  void display();
  void move();
}
abstract class Unit implements MovableObject {
  protected double x, y;
  protected boolean isAlive;
  protected double size;
  protected Danmaku danmaku;
  protected Timer unitTimer = new Timer();
  Unit() {
    size = 10; danmaku = new Danmaku(); isAlive = true;
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
  private int numSubUnits, zanki;
  private boolean muteki, displayPhase;
  private ArrayList<SubUnit> subUnits = new ArrayList<>();
  private double angSpan;
  private Timer mutekiTimer, efTimer;
  private final int MUTEKI_TIME = 3000;
  private final double STEP = 8, SLOW_STEP = 4, ANG_STEP = PI/120, MAX_ANG_SPAN = PI/18, MIN_ANG_SPAN = PI/72;
  PlayerUnit() {
    x = width/2; y = height * 2 / 3; numSubUnits = 5; size = 15; zanki = 3; angSpan = PI/18;
    for(int i = 0; i < numSubUnits; i++) addSubUnit(2*PI / numSubUnits * i);
    muteki = false; displayPhase = false;
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
  void display() {
    final int EF_TIME = 250;
    if(muteki) {
      if(efTimer.getMilTime() > EF_TIME) {
        displayPhase = !displayPhase;
        efTimer.resetTimer();
      }
      if(mutekiTimer.getMilTime() > MUTEKI_TIME) {
        displayPhase = true;
        muteki = false;
      }
      if(!displayPhase) return;
    }
    fill(fBlack); circle((float)x, (float)y, (float)size);
    fill(WHITE); circle((float)x, (float)y, (float)size* 0.8);
  }
  void move() {
    if(g_keyState[0] && y >= 0)  y -= (!g_keyState[4] ? STEP : SLOW_STEP);
    if(g_keyState[1] && y <= height)  y += (!g_keyState[4] ? STEP : SLOW_STEP);
    if(g_keyState[2] && x >= 0)  x -= (!g_keyState[4] ? STEP : SLOW_STEP);
    if(g_keyState[3] && x <= width)  x += (!g_keyState[4] ? STEP : SLOW_STEP);
  }
  private void shoot() {
    if(g_keyState[4]) {
      angSpan -= ANG_STEP; 
      angSpan = max((float)MIN_ANG_SPAN, (float)angSpan);
    }else{
      angSpan += ANG_STEP;
      angSpan = min((float)angSpan, (float)MAX_ANG_SPAN);
    }
    if(g_keyState[8]) {
      if(unitTimer.getMilTime() >= 20) {
        genNWaysDan(x, y, 7, 20, -PI/2, angSpan, 3, 1, WHITE);
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
  private double distFromPlayer, mainUnitX, mainUnitY, rad;
  private final double SUBUNIT_SIZE = 10, MAX_DIST = 50, MIN_DIST = 25, D_STEP = 4;
  SubUnit(double rad0) {
    size = SUBUNIT_SIZE; distFromPlayer = MAX_DIST; x = distFromPlayer*cos((float)rad); y = distFromPlayer*sin((float)rad); rad = rad0;
  }
  void setMainUnitLoc(double px, double py) {
    mainUnitX = px; mainUnitY = py;
  }
  void update() {
    shoot(); display(); move();
  }
  void display() {
    x = distFromPlayer*cos((float)rad); y = distFromPlayer*sin((float)rad);
    pushMatrix();
    translate((float)mainUnitX, (float)mainUnitY);
    fill(200);
    rect((float)(x), (float)(y), 10, 10);
    popMatrix();
  }
  void move() {
    if(g_keyState[4]) {
      distFromPlayer = max((float)MIN_DIST, (float)distFromPlayer);
      distFromPlayer -= D_STEP;
    }else{
      distFromPlayer = min((float)distFromPlayer, (float)MAX_DIST);
      distFromPlayer += D_STEP;
    }
    rad += PI/120.0;
    rad %= 2 * PI;
  }
  private void shoot() {
    if(g_keyState[8]) {
      if(unitTimer.getMilTime() >= 20) {
        genOneDan(mainUnitX + x, mainUnitY + y, 5, 20, -PI/2, 0, WHITE);
        unitTimer.resetTimer();
      }
    }
    danmaku.display(); danmaku.move(); danmaku.deleteOutOfField();
  }
}
abstract class EnemyUnit extends Unit {
  private Timer t, pauseTimer;
  protected int life;
  private int waypointsIndex, maxWaypointIndex;
  private double speed, rad, sx, sy, cx, cy, curWaypointX, curWaypointY;
  private double[][] waypoints;
  private boolean isPaused, isActive, hasPauseBeenTriggered, isMovable;  
  protected PlayerUnit player;
  EnemyUnit(double x0, double y0, double size0, double speed0, double[][] waypoints0) {
    life = 10; x = x0; y = y0; sx = x0; sy = y0; cx = 0; cy = 0; size = size0; speed = speed0; waypoints = waypoints0; life = 1;
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
          move();
        }
        shootDurMoving();
      }
    }
    shootConstantly();
  }
  void display() {
    pushMatrix();
    translate((float)sx, (float)sy);
    rotate((float)rad);
    fill(fBlack);
    circle((float)cx, (float)cy, (float)size);
    fill(WHITE);
    circle((float)cx, (float)cy, (float)size*0.8);
    popMatrix();
  }
  void move() {
    rad = atan2((float)(curWaypointY - sy), (float)(curWaypointX - sx));
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
  NormEn1(double x0, double y0, double size0, double speed0, double[][] waypoints0) {
    super(x0, y0, size0, speed0, waypoints0);
    life = 15;
  } 
  protected void shootJustOnPause() {
    double toP = atan2((float)(player.getY() - y), (float)(player.getX() - x));
    genNWaysDan(x, y, 10, 5, toP, PI/192, 13, 0, MAGENTA); 
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
      genAllDirectionsDan(x, y, 20, 3, toP, 24, 0, BLUE);
      shootOnPauseTimer[0].resetTimer();
    }
    if(shootOnPauseTimer[1].isFirstCall() || shootOnPauseTimer[1].getMilTime() >= 1600) {
      double toP = atan2((float)(player.getY() - y), (float)(player.getX() - x));
      genAllDirectionsDan(x, y, 30, 4, toP, 4, 0, RED);
      shootOnPauseTimer[1].resetTimer();
    }
  }
}
class NormEn3 extends EnemyUnit {
  NormEn3(double x0, double y0, double size0, double speed0, double[][] waypoints0) {
    super(x0, y0, size0, speed0, waypoints0);
    life = 3;
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
      genAllDirectionsDan(x, y, 20, 5, toP, 18, 0, RED);
      shootOnPauseTimer[0].resetTimer();
    }
    if(shootOnPauseTimer[1].isFirstCall() || shootOnPauseTimer[1].getMilTime() >= 100) {
      double toP = atan2((float)(player.getY() - y), (float)(player.getX() - x));
      genOneDan(x, y, 20, 8, toP, 0, GREEN);
      shootOnPauseTimer[1].resetTimer();
    }
  }
  protected void shootJustOnPause() {
    double toP = atan2((float)(player.getY() - y), (float)(player.getX() - x));
    genAllDirectionsDan(x, y, 30, 4, toP, 64, 0, YELLOW);
  }
}
class Danmaku implements MovableObject { 
  ArrayList<Projectile> projectiles = new ArrayList<>();
  void display() {
    for(int i = 0; i < projectiles.size(); i++)  projectiles.get(i).display();
  }
  void move() {
    for(int i = 0; i < projectiles.size(); i++) projectiles.get(i).move();
  }
  void add(Projectile p) {
    projectiles.add(p);
  }
  void add(ArrayList<Projectile> ps) {
    projectiles.addAll(ps);
  }
  void deleteOutOfField() {
    for(int i = projectiles.size() - 1; i >= 0; i--) {
      Projectile p = projectiles.get(i);
      if(!p.isInside()) projectiles.remove(i);
    }
  }
  boolean isEmpty() {
    return projectiles.isEmpty();
  }
}
abstract class Projectile implements MovableObject{
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
  void display() {
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
abstract class Wave {
  private Timer waveTimer, spawnTimer;
  private int round, startTime, span, enId;
  protected ArrayList<EnemyUnit> enemies;
  Wave(int round0, int startTime0, int span0) {
    round = round0; startTime = startTime0; span = span0;
    waveTimer = new Timer(); spawnTimer = new Timer();
  }
  void update(ArrayList<EnemyUnit> enemies) {
    spawnEnemy(enemies);
  }
  protected void spawnEnemy(ArrayList<EnemyUnit> enemies) {
    if(round > 0 && spawnTimer.getMilTime() > startTime) {
      if(waveTimer.isFirstCall() || waveTimer.getMilTime() >= span) {
        enemies.addAll(genEnemy());
        round--;
        waveTimer.resetTimer();
      }
    }
  }
  boolean isCompleted() {
    return round == 0;
  }
  abstract protected ArrayList<EnemyUnit> genEnemy();
}
class WaveA extends Wave {
  WaveA(int round0, int startTime0, int span0) {
    super(round0, startTime0, span0);
  }
  protected ArrayList<EnemyUnit> genEnemy() {
    ArrayList<EnemyUnit> gEn = new ArrayList<>();
    float sp = height/6 / 10;
    for(int i = 0; i < 7; i++) {
      gEn.add(new NormEn1(width/8*(i+1), 0, sp, 4, new double[][] {{width/8*(i+1), height/6, 500}, {width/8*(i+1), height/3, 500}, {width/8*(i+1), height/2, 500}, {width/8*(i+1), height/8, 500}, {width/8*(i+1), -50, 500}}));
    }
    return gEn;
  }
}
class WaveB extends Wave {
  WaveB(int round0, int startTime0, int span0) {
    super(round0, startTime0, span0);
  }
  protected ArrayList<EnemyUnit> genEnemy() {
    ArrayList<EnemyUnit> gEn = new ArrayList<>();
    for(int i = 1; i <= 6; i++) {
      gEn.add(new NormEn2(width,   height/8, 20, 8*0.2*(7-i), new double[][] {{width/7*i, height/8, 10000}, {width+50, height/8, 10000}}));
      gEn.add(new NormEn2(    0,   height/4, 20, 8*0.2*i,     new double[][] {{width/7*i, height/4, 10000}, {-50, height/4, 10000}}));
      gEn.add(new NormEn2(width, height*3/8, 20, 8*0.2*(7-i), new double[][] {{width/7*i, height*3/8, 10000}, {width+50, height*3/8, 10000}}));
    }
    return gEn;
  }
}
class WaveC1 extends Wave{ 
  WaveC1(int round0, int startTime0, int span0) {
    super(round0, startTime0, span0);
  }
  protected ArrayList<EnemyUnit> genEnemy() {
    ArrayList<EnemyUnit> gEn = new ArrayList<>();
    gEn.add(new LargeEn(  width/5, 0, 30, 4, new double[][] {{  width/5, height/3,  2000}, {width/2, height/6, 2000}, {width*4/5, height/3, 2000}, {width/2, height/2, 2000}, {  width/5, height/3, 2000}, {width/5, -50, 2000}}));
    gEn.add(new LargeEn(width*4/5, 0, 30, 4, new double[][] {{width*4/5, height/3,  2000}, {width/2, height/2, 2000}, {  width/5, height/3, 2000}, {width/2, height/6, 2000}, {width*4/5, height/3, 2000}, {width*4/5, -50, 2000}}));
    return gEn;
  }
}
class WaveC2 extends Wave{
  WaveC2(int round0, int startTime0, int span0) {
    super(round0, startTime0, span0);
  }
  protected ArrayList<EnemyUnit> genEnemy() {
    ArrayList<EnemyUnit> gEn = new ArrayList<>();
    double ranX = random(width/8, width*7/8), ranY = random(height/6, height/2), ranSp = random(3, 6);
    gEn.add(new NormEn3(ranX, 0, 20, ranSp, new double[][] {{ranX, ranY, 100}, {ranX, -50, 10000}}));
    return gEn;
  }
}
class Title {
  private int colVal, dCol;
  private boolean isClicked;
  private final int D_COL = 5, MAX_COL_VAL = 215, MIN_COL_VAL = 40;
  Title() {
    colVal = MAX_COL_VAL; dCol = D_COL; isClicked = false;
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
    isClicked = g_isClicked; //mousePressed()を使うため，セッターは用いない
    if(colVal < MIN_COL_VAL || colVal > MAX_COL_VAL) dCol *= -1;
  }
  private boolean getIsClicked() {
    return isClicked;
  }
}
class Game {
  private int gameSeq, defeatedLEnCnt, maxLEnCnt, maxZanki;
  private Title title;
  private PlayerUnit jiki;
  private ArrayList<EnemyUnit> enemies;
  private ArrayList<Wave> waves;
  private final int TITLE = 0, PLAY = 1, GAMEOVER = 2, GAMECLEAR = 3;
  Game() {
    title = new Title(); jiki = new PlayerUnit(); enemies = new ArrayList<>(); waves = new ArrayList<>(); 
    gameSeq = 0;
    defeatedLEnCnt = 0;
  }
  void update() {
    if(gameSeq == TITLE) {
      drawTitle();  
    }else if(gameSeq == PLAY) {
      drawGame();
    }else if(gameSeq == GAMEOVER) {
      drawGameover();
    }else if(gameSeq == GAMECLEAR) {
      drawGameclear();
    }
  }
  private void initWave() {
    WaveA w1 = new WaveA(4, 2000, 1000); WaveB w2 = new WaveB(1, 12000, 1000); WaveC1 w3 = new WaveC1(1, 24000, 0); WaveC2 w4 = new WaveC2(60, 24500, 250);
    waves.add(w1);waves.add(w2);waves.add(w3);waves.add(w4);
    maxLEnCnt = 2;
  }
  private void drawTitle() {
    title.update();
    if(title.getIsClicked()) {
      initWave();
      maxZanki = jiki.getZanki();
      gameSeq = PLAY;
    }
  }
  private void drawGame() {
    background(40, 40, 40, 10);
    jiki.update(enemies);
    for(int i = 0; i < waves.size(); i++) {
      Wave w = waves.get(i);
      w.update(enemies);
      if(w.isCompleted()) waves.remove(i);
    }
    for(int i = 0; i < enemies.size(); i++) {
      EnemyUnit en = enemies.get(i);
      en.setPlayer(jiki);
      en.update();
      if(!en.getActivityState()) {
        if(en instanceof LargeEn) defeatedLEnCnt++;
        enemies.remove(i);
      }                                    
    }
    zankiUI(jiki.getZanki());
    
    if(!jiki.getIsAlive()) gameSeq = GAMEOVER;
    if(defeatedLEnCnt == maxLEnCnt && enemies.isEmpty()) gameSeq = GAMECLEAR;
  }
  private void drawGameover() {
    background(20); fill(RED); textAlign(CENTER); textSize(100); text("Game Over...", width/2, height/2);
    noLoop();
  }
  private void drawGameclear() {
    background(235); fill(GREEN); textAlign(CENTER); textSize(100); text("You Win!!!", width/2, height/2);
    noLoop();
  }
  private void zankiUI(int zanki) {
    int efDia = 20;
    String s = "Your Life:";
    float xw = width - textWidth(s);
    textSize(20);
    textAlign(RIGHT,CENTER);
    text("Your Life:", xw, height-efDia/2);
    for(int i = 0; i < jiki.getZanki(); i++) {
      fill(RED);
      circle(width + efDia*(i - maxZanki), height - efDia/2, efDia);
    }
  }
}

boolean[] g_keyState = new boolean[16];//0-3:上下左右 4:低速モード 8:射撃
boolean g_isClicked;
final int FRAMERATE = 60;
final color WHITE = color(255), RED = color(255, 0, 0), BLUE = color(0, 0, 255), GREEN = color(0, 255, 0), GRAY = color(127), YELLOW = color(255, 255, 0), MAGENTA = color(255, 0, 255), fCyan = color(0, 255, 255), fBlack = color(0);


Game game;
void setup() {
  size(800, 1200);
  frameRate(FRAMERATE); rectMode(CENTER); imageMode(CENTER); textAlign(CENTER); noStroke();
  g_isClicked = false; 
  for(int i = 0; i < 16; i++)  g_keyState[i] = false;  
  game = new Game();
}
void draw() {
  game.update();
}
void mousePressed() {
  g_isClicked = true;
}
void keyPressed() {
  if(keyCode == UP)   g_keyState[0] = true;
  if(keyCode == DOWN) g_keyState[1] = true;
  if(keyCode == LEFT) g_keyState[2] = true;
  if(keyCode == RIGHT) g_keyState[3] = true;
  if(keyCode == SHIFT) g_keyState[4] = true;
  if(key == 'x' || key == 'X') g_keyState[8] = true;
}
void keyReleased() {
  if(keyCode == UP)   g_keyState[0] = false;
  if(keyCode == DOWN) g_keyState[1] = false;
  if(keyCode == LEFT) g_keyState[2] = false;
  if(keyCode == RIGHT) g_keyState[3] = false;
  if(keyCode == SHIFT) g_keyState[4] = false;
  if(key == 'x' || key == 'X') g_keyState[8] = false;
}
