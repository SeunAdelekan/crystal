require "enumerable"
require "pointer"
require "range"

generic class Array
  include Enumerable

  def initialize(initial_capacity = 16)
    @length = 0
    @capacity = initial_capacity
    @buffer = Pointer.malloc(initial_capacity)
  end

  def initialize(size, value)
    @length = size
    @capacity = size
    @buffer = Pointer.malloc(size, value)
  end

  def self.new(size)
    ary = Array.new(size)
    ary.length = size
    size.times do |i|
      ary.buffer[i] = yield i
    end
    ary
  end

  def length
    @length
  end

  def count
    @length
  end

  def size
    @length
  end

  def empty?
    @length == 0
  end

  def [](index : Int)
    index += length if index < 0
    @buffer[index]
  end

  def []=(index : Int, value)
    index += length if index < 0
    @buffer[index] = value
  end

  def [](range : Range)
    from = range.begin
    from += length if from < 0
    to = range.end
    to += length if to < 0
    to -= 1 if range.excludes_end?
    length = to - from + 1
    length <= 0 ? [] : self[from, length]
  end

  def [](start : Int, count : Int)
    Array.new(count) { |i| @buffer[start + i] }
  end

  def push(value)
    check_needs_resize
    @buffer[@length] = value
    @length += 1
    self
  end

  def pop
    return nil if @length == 0
    @length -= 1
    @buffer[@length]
  end

  def <<(value)
    push(value)
  end

  def first
    self[0]
  end

  def last
    self[@length - 1]
  end

  def delete_at(index : Int)
    index += length if index < 0
    return nil if index < 0 || index >= length

    elem = @buffer[index]
    (@buffer + index).memmove(@buffer + index + 1, length - index - 1)
    @length -= 1
    elem
  end

  def delete(obj)
    i1 = 0
    i2 = 0
    while i1 < @length
      e = @buffer[i1]
      unless obj == e
        if i1 != i2
          @buffer[i2] = e
        end
        i2 += 1
      end

      i1 += 1
    end
    if i2 != i1
      @length -= (i1 - i2)
      true
    else
      false
    end
  end

  def &(other : Array)
    hash = other.each_with_object({}) { |obj, hash| hash[obj] = true }
    ary = Array.new(Math.min(length, other.length))
    each do |obj|
      ary << obj if hash[obj]
    end
    ary
  end

  def |(other : Array)
    ary = Array.new(length + other.length)
    hash = {}
    each do |obj|
      ary << obj
      hash[obj] = true
    end
    other.each do |obj|
      ary << obj unless hash[obj]
    end
    ary
  end

  def -(other : Array)
    ary = Array.new(length - other.length)
    hash = other.each_with_object({}) { |obj, hash| hash[obj] = true }
    each do |obj|
      ary << obj unless hash[obj]
    end
    ary
  end

  def compact
    select { |x| !x.nil? }
  end

  def compact!
    delete nil
  end

  def flatten
    ary = Array.new(length)
    flatten_append ary, self
    ary
  end

  def clear
    @length = 0
  end

  def each
    length.times do |i|
      yield @buffer[i]
    end
    self
  end

  def buffer
    @buffer
  end

  def to_a
    self
  end

  def max
    max = self[0]
    1.upto(length - 1) do |i|
      max = self[i] if self[i] > max
    end
    max
  end

  def +(other : Array)
    new_length = length + other.length
    ary = Array.new(new_length)
    ary.length = new_length
    ary.buffer.memcpy(buffer, length)
    (ary.buffer + length).memcpy(other.buffer, other.length)
    ary
  end

  def concat(other : Enumerable)
    other.each do |elem|
      push elem
    end
    self
  end

  def ==(other : Array)
    return false if @length != other.length
    each_with_index do |item, i|
      return false if item != other[i]
    end
    true
  end

  def to_s
    str = StringBuilder.new
    str << "["
    each_with_index do |elem, i|
      str << ", " if i > 0
      str << elem.inspect
    end
    str << "]"
    str.inspect
  end

  def sort!
    quicksort 0, length - 1
    self
  end

  # protected

  def length=(length)
    @length = length
  end

  # private

  def check_needs_resize
    resize_to_double_capacity if @length == @capacity
  end

  def resize_to_double_capacity
    @capacity *= 2
    @buffer = @buffer.realloc(@capacity)
  end

  def flatten_append(target, source : Array)
    source.each do |obj|
      flatten_append target, obj
    end
  end

  def flatten_append(target, source)
    target.push source
  end

  def swap(i, j)
    temp = self[i]
    self[i] = self[j]
    self[j] = temp
  end

  def partition(left, right, pivot_index)
    pivot_value = self[pivot_index]
    swap pivot_index, right
    store_index = left
    left.upto(right) do |i|
      if self[i] < pivot_value
        swap i, store_index
        store_index += 1
      end
    end
    swap store_index, right
    store_index
  end

  def quicksort(left, right)
    if left < right
      pivot_index = (left + right) / 2
      pivot_new_index = partition left, right, pivot_index
      quicksort left, pivot_new_index - 1
      quicksort pivot_new_index + 1, right
    end
  end
end