/**
 * Bounded Ring Buffer for Zero-GC Sliding Empirical Metric Window
 */

export class RingBuffer {
  constructor(capacity = 500) {
    this.capacity = capacity;
    this.buffer = new Array(capacity);
    this.head = 0;
    this.tail = 0;
    this.count = 0;
  }

  push(item) {
    this.buffer[this.head] = item;
    this.head = (this.head + 1) % this.capacity;
    if (this.count < this.capacity) {
      this.count++;
    } else {
      this.tail = (this.tail + 1) % this.capacity;
    }
  }

  toArray() {
    const arr = [];
    for (let i = 0; i < this.count; i++) {
      const idx = (this.tail + i) % this.capacity;
      arr.push(this.buffer[idx]);
    }
    return arr;
  }

  clear() {
    this.head = 0;
    this.tail = 0;
    this.count = 0;
  }
}
