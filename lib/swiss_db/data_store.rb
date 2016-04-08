# main connection point
# creates and upgrades our database for us
# and provides low level SQL features
module SwissDB
  class DataStore < Android::Database::SQLite::SQLiteOpenHelper

    ContentValues = Android::Content::ContentValues

    def writable_db
      getWritableDatabase
    end

    def self.drop_db
      SwissDB.context.deleteDatabase(SwissDB.db_name)
    end

    def onUpgrade(db, oldVersion, newVersion)
      # TODO when migrations are implemented
      mp "Calling onUpgrade"
      mp "old version: #{oldVersion}"
      mp "new version: #{newVersion}"
    end

    #create
    def onCreate(db)
      SwissDB.create_tables_from_schema(db)
    end

    #insert
    def insert(db=writable_db, table, hash_values)
      # puts "inserting data in #{table}"
      values = ContentValues.new(hash_values.count)
      hash_values.each do |k, v|
        values.put(k, coerces(v))
      end
      result = db.insert(table, nil, values)
      result
    end
    #retrieve
    def select_all(db=writable_db, table, model)
      sql = "select * from '#{table}'"
      puts sql
      cursor = db.rawQuery(sql, nil)
      Cursor.new(cursor, model) # we wrap their cursor
    end

    def select(db=writable_db, table, values, model)
      puts "selecting data from #{table}"
      value_str = values.map do |k, v|
        "#{k} = '#{coerces(v)}'"
      end.join(" AND ")
      sql = "select * from '#{table}' where #{value_str}"
      puts sql
      cursor = db.rawQuery(sql, nil)
      Cursor.new(cursor, model) # we wrap their cursor
    end

    # update

    def update(db=writable_db, table, values, where_values)
      value_str = values.map do |k, v|
        "'#{k}' = '#{coerces(v)}'"
      end.join(",")
      where_str = where_values.map do |k, v|
        "#{k} = '#{coerces(v)}'"
      end.join(",")
      sql = "update '#{table}' set #{value_str} where #{where_str}"
      puts sql
      db.execSQL sql
    end

    #deleting all records

    def destroy_all(db=writable_db, table) # WARNING!
      puts "destroying all from #{table}"
      db.delete(table, nil, nil)
    end

    # transform values
    def coerces(v)
      if v.is_a?(Time)
        formatter = Java::Text::SimpleDateFormat.new('yyyy-MM-dd hh:mm:ss.SSS')
        formatter.format(v).to_s
      else
        v.to_s
      end
    end
  end
end
