class Planet {

  int planetCount;
  float mass;
  PVector location;
  PShape planetShape;
  float G = 10;
  float rotation = -0.01;
  
  Planet(int planetCount) {
    println("INITIALIZING A NEW PLANET: " + str(planetCount) + "\n");
    this.planetCount = planetCount;
    this.location = getPlanetLocation();
    this.mass = 30;
    this.planetShape = createShape(SPHERE, this.mass * 3);
    this.planetShape.setTexture(loadImage("textures/planet_texture.png"));
  }

  PVector attract(Moon m) {
    PVector force = PVector.sub(this.location, m.location); 
    float distance = force.mag();                                  
    distance = constrain(distance, 15.0, 30.0);                            
    float strength = (G * this.mass * m.mass) / (distance * distance);      
    force.setMag(strength);                                                  
    return force;
  }

  PVector getPlanetLocation() {
    PVector myLocation;
    
    switch(this.planetCount) {
     case 0:
      myLocation = new PVector(width / 2, height / 2, 2);          // middle
      break; 
     case 1:
      myLocation = new PVector(width / 4 - 100, height / 4, 2);          // top left
      break;
     case 2:
      myLocation = new PVector(3 * width / 4 - 200, 3 * height / 4, 2);  // bottom right
      break;
     case 3:
      myLocation = new PVector(width / 4 + 50, 3 * height / 4 + 100  , 2);      // bottom left
      break;
     case 4:
      myLocation = new PVector(3 * width / 4 + 50, height / 4, 2);      // top right
      break;
     case 5:
      myLocation = new PVector(width / 4 - 100, height / 2, 2);          // mid left
      break;
     case 6:
      myLocation = new PVector(3 * width / 4, height / 2, 2);      // mid right
      break;
     case 7:
      myLocation = new PVector(width / 2 - 100, 3 * height / 4 - 50, 2);      // bottom mid
      break;
     case 8:
      myLocation = new PVector(width / 2, height / 4 + 50, 2);          // top mid
      break;
     default:
      myLocation = new PVector(random(0, 800), random(0, 800));
      break;
     }  
    
    return myLocation;
}
  
  void display() {
    stroke(255);
    noFill();
    pushMatrix();
    translate(this.location.x, this.location.y, this.location.z);    
    shape(planetShape);
    this.planetShape.rotateY(rotation);
    popMatrix();
  }
}