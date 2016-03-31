class Sun {
  float mass;
  PVector location;
  PShape sunShape;
  float rotation = 0.001;  
  
  Sun() {
    this.location = new PVector(width + 500, height + 600);
    this.mass = 500;
    this.sunShape = createShape(SPHERE, this.mass * 2);
    this.sunShape.setTexture(loadImage("textures/suntext.jpg"));
  }

  void display() {
    stroke(255);
    noFill();
    pushMatrix();
    translate(this.location.x, this.location.y, this.location.z);
    shape(sunShape);
    this.sunShape.rotateY(rotation);
    popMatrix();
  }
}