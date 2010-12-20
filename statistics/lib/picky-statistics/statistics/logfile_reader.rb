module Statistics

  class LogfileReader

    attr_writer :path

    #
    #
    def initialize path
      @path = File.expand_path path
      check_file
      
      @counts = {}
      initialize_totals
      initialize_full_totals
      initialize_live_totals
      initialize_other
    end
    def check_file
      if File.exists? @path
        puts "Logfile #{@path} found."
      else
        raise "Log file #{@path} not found."
      end
    end
    
    def full
      @counts[:full] ||= {}
    end
    def live
      @counts[:live] ||= {}
    end
    
    def initialize_totals
      full[:total] = Count.new "^>|"
      live[:total] = Count.new "^\\.|"
    end
    def initialize_full_totals
      full[:totals] = {}
      full[:totals][0] = Count.new "^>|.*|       0|"
      full[:totals][1] = Count.new "^>|.*|       1|"
      full[:totals][2] = Count.new "^>|.*|       2|"
      full[:totals][3] = Count.new "^>|.*|       3|"
      
      full[:totals][:four_plus] = Count.new("^>|.*|       [4-9]|....|.[1-9]|", # 2-9, with one or more allocs
                                            "^>|.*|......[0-9].|....|.1|")     # any number higher than 9, with one alloc
      full[:totals][:cloud]     = Count.new("^>|.*|[1-9].|",          # allocs 10+
                                            "^>|.*|.*|......[1-9].|....|.[2-9]|")        # allocs 2-9, more than 10 results
      
      full[:totals][:'100+']   = Count.new "^>|.*|.*|     [1-9]..|"
      full[:totals][:'1000+']  = Count.new "^>|.*|.*|....[0-9]...|"
    end
    def initialize_live_totals
      
    end
    def initialize_other
      full[:quick]             = Count.new "^>|.\\+\\?|0\\.00....|"
      full[:long_running]      = Count.new "^>|.\\+\\?|0\\.[1-9].....|"
      full[:very_long_running] = Count.new "^>|.\\+\\?|[1-9]\\.......|"
      
      full[:offset]            = Count.new "^>|.*|   0|" # with offset?
    end

    #
    #
    def since_last
      @last_offset ||= 0
      puts "Parsing log files from last parse point at line #{@last_offset}."
      with_temp_file(@last_offset) do |statistics|
        calculate_last_offset_from statistics
        
        puts "Generating statistics."
        full[:total].add_from statistics
        live[:total].add_from statistics
        
        full[:totals][0].add_from statistics
        full[:totals][1].add_from statistics
        full[:totals][2].add_from statistics
        full[:totals][3].add_from statistics
        
        full[:totals][:four_plus].add_from statistics
        full[:totals][:cloud].add_from statistics
        
        full[:totals][:'100+'].add_from statistics
        full[:totals][:'1000+'].add_from statistics
        
        full[:quick].add_from statistics
        full[:long_running].add_from statistics
        full[:very_long_running].add_from statistics
        
        full[:offset].add_from statistics, :nonmatching => true # TODO Move to initializer
        
        puts "Finished generating statistics."
      end
      @counts
    end
    
    def calculate_last_offset_from statistics
      lines = `wc -l #{statistics}`.to_i
      @last_offset = lines + 2 if lines > 0
    end

    #
    #
    def reset_from time
      with_temp_file(offset) do |statistics|
        full[:total].reset_from statistics
      end
      @counts
    end
    
    # Use the offset to speed up statistics gathering.
    #
    def with_temp_file offset = 0
      # Tempfile.open 'picky' do |temp_file|
      File.open('picky_statistics.tmp', 'w+') do |temp_file|
        temp_path = temp_file.path
        puts "Copying #{@path} to #{temp_path} beginning at line #{offset}."
        `tail -n +#{offset} #{@path} > #{temp_path}`
        puts "Finished copying."
        yield temp_path
        # TODO rm temp file
      end
    end
  
  end

end