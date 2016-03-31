import java.util.concurrent.ArrayBlockingQueue;
import java.io.File;


class FixedLengthQueue<E> extends ArrayBlockingQueue<E> {
 
  private int size;
 
  public FixedLengthQueue(int size) {
    super(size);
    this.size = size;
  }
 
  @Override
  synchronized public boolean add(E e) {
    if (super.size() == this.size) {
       this.remove();
    }
    return super.add(e);
  }
}