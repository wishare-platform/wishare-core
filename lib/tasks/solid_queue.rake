namespace :solid_queue do
  desc "Load Solid Queue schema into the database"
  task :load_schema => :environment do
    puts "Loading Solid Queue schema..."
    
    queue_schema_path = Rails.root.join('db', 'queue_schema.rb')
    
    if File.exist?(queue_schema_path)
      # Switch to queue database connection
      ActiveRecord::Base.connected_to(role: :writing, shard: :queue) do
        # Load the queue schema
        load queue_schema_path
        puts "Solid Queue schema loaded successfully!"
      end
    else
      puts "Queue schema file not found at #{queue_schema_path}"
      exit 1
    end
  end
  
  desc "Create Solid Queue tables in production"
  task :setup => :environment do
    puts "Setting up Solid Queue for production..."
    
    begin
      # Check if solid_queue_jobs table exists in the primary database
      unless ActiveRecord::Base.connection.table_exists?('solid_queue_jobs')
        puts "Creating Solid Queue tables..."
        
        # Load the queue schema directly into the primary database
        queue_schema_path = Rails.root.join('db', 'queue_schema.rb')
        if File.exist?(queue_schema_path)
          load queue_schema_path
          puts "Solid Queue tables created successfully!"
        else
          puts "ERROR: Queue schema file not found!"
          exit 1
        end
      else
        puts "Solid Queue tables already exist."
      end
    rescue => e
      puts "ERROR: Failed to set up Solid Queue: #{e.message}"
      exit 1
    end
  end
end