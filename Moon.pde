import java.util.Random;


class Moon {
  
  PVector location;
  PVector velocity;
  PVector acceleration;
  float mass;
  PShape moonShape;
  Planet planet;
  
  Moon(Planet planet, String texturePath) {
    this.mass = getRandomMass();
    this.planet = planet;
    this.location = new PVector(this.planet.location.x + getRandomStart(), 
                                this.planet.location.y + getRandomStart(), 
                                this.planet.location.z + random(400, 600));
    this.velocity = new PVector(1, 0);
    this.acceleration = new PVector(0, 0);
    this.setTexture(texturePath);
  }
  
  int getRandomMass() {
    int[] massList = {8, 10, 12, 15, 18};
    Random random = new Random();
    int index = random.nextInt(massList.length - 1);
    return massList[index];
  }
  
  int getRandomStart() {
    int[] startList = {-150, -200, -250, -300, -350, 150, 200, 250, 300, 350};
    Random random = new Random();
    int index = random.nextInt(startList.length - 1);
    return startList[index];
  }
  
  void setTexture(String texturePath) {
    this.moonShape = createShape(SPHERE, this.mass * 8);
    this.moonShape.setTexture(loadImage(texturePath));
  }
  
  // Based off of Gravitational Attraction (3D) by Daniel Shiffman <http://www.shiffman.net>
  void applyForce(PVector force) {
    PVector f = PVector.div(force, mass);
    this.acceleration.add(f);
  }

  void update() {
    this.velocity.add(acceleration); 
    this.location.add(velocity);    
    this.acceleration.mult(0);
  }

  void display() {
    noStroke();
    fill(255);
    pushMatrix();
    translate(this.location.x, this.location.y, this.location.z);
    shape(moonShape);
    this.moonShape.rotateX(0.01);
    this.moonShape.rotateY(0.01);
    popMatrix();
  }
}