# SwissDB Cursor
# Helps move around a result set
# Convenience methods over the standard cursor
# Used by Swiss DataStore
module SwissDB
  class Cursor

    FIELD_TYPE_BLOB    = 4
    FIELD_TYPE_FLOAT   = 2
    FIELD_TYPE_INTEGER = 1
    FIELD_TYPE_NULL    = 0
    FIELD_TYPE_STRING  = 3

    attr_accessor :cursor, :model

    def initialize(cursor, model)
      @cursor = cursor
      @model = model
      @values = {}
    end

    def model
      @model
    end

    def first
      begin
        return nil if count == 0
        cursor.moveToFirst ? self : nil
        swiss_model = model.new(to_hash)
      ensure
        cursor.close
      end
      swiss_model
    end

    def last
      begin
        return nil if count == 0
        cursor.moveToLast ? self : nil
        swiss_model = model.new(to_hash)
      ensure
        cursor.close
      end
      swiss_model
    end

    def current
      model.new(to_hash)
    end

    def [](pos)
      begin
        return nil if count == 0
        cursor.moveToPosition(pos) ? self : nil
        swiss_model = model.new(to_hash)
      ensure
        cursor.close
      end
      swiss_model
    end

    def to_hash
      hash_obj = {}
      column_names.each do |k|
        hash_obj[k] = self.send(k)
      end
      hash_obj
    end

    def to_a
      begin
        return nil if count == 0
        arr = []
        (0...count).each do |i|
          # puts i
          cursor.moveToPosition(i)
          arr << model.new(to_hash)
        end
      ensure
        cursor.close
      end
      arr
    end

    # todo: take out setter code. it's not used anymore. leave the getter code. it is used. (see #to_hash)

    def method_missing(method_name, *args)
      # puts "cursor method missing #{method_name}"
      if valid_getter?(method_name)
        get_method(method_name)
      else
        super
      end
    end

    def valid_getter?(method_name)
      column_names.include? method_name
    end

    def is_setter?(method_name)
      method_name[-1] == '='
    end

    def get_method(method_name)
      index = cursor.getColumnIndex(method_name)
      type = cursor.getType(index)
      # puts "getting field #{method_name} at index #{index} of type #{type}"

      if type == FIELD_TYPE_STRING #also boolean
        str = cursor.getString(index).to_s

        if str =~ /[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}.[0-9]{3}/
          formatter = Java::Text::SimpleDateFormat.new('yyyy-MM-dd hh:mm:ss.SSS')
          str = formatter.parse(str)
        end

        str = true if str == "true"
        str = false if str == "false"
        str
      elsif type == FIELD_TYPE_INTEGER
        cursor.getInt(index).to_i
      elsif type == FIELD_TYPE_NULL
        nil #??
      elsif type == FIELD_TYPE_FLOAT
        cursor.getFloat(index).to_f
      elsif type == FIELD_TYPE_BLOB
        cursor.getBlob(index)
      end
    end

    def count
      cursor.getCount
    end

    def column_names
      cursor.getColumnNames.map(&:to_sym)
    end

    def map(&block)
      return [] if count == 0
      arr = []
      (0...count).each do |i|
        # puts i
        cursor.moveToPosition(i)
        arr << yield(model.new(to_hash))
      end

      arr
    end

    def each(&block)
      return [] if count == 0
      arr = []
      (0...count).each do |i|
        # puts i
        cursor.moveToPosition(i)
        m = model.new(to_hash)
        yield(m)
        arr << m
      end

      arr
    end

    # those methods allow the use of PMCursorAdapter with SwissDB
    def moveToPosition(i)
      cursor.moveToPosition(i)
    end

    def moveToLast
      cursor.moveToLast
    end

    def moveToFirst
      cursor.moveToFirst
    end
  end
end
