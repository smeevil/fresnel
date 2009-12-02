class SetupWizard
  def self.global(fresnel)
    config=Hash.new
    puts "================================================"
    puts "    Fresnel - #{fresnel.app_description}           "
    puts "                config wizard                   "
    puts "================================================"
    puts
    config['account']=ask("My lighthouse account is : ") do |q|
      q.validate = /^\w+$/
      q.responses[:not_valid]="\nError :\nThat seems to be incorrect, we would like to have the <account> part in\nhttp://<account>.lighthouseapp.com , please try again"
      q.responses[:ask_on_error]="My lighthouse account is : "
      q.default=ENV['USER']
    end

    puts
    puts "what token would you like to use for the account : #{config['account']} ?"
    config['token']=ask("My lighthouse token is : ") do |q|
      q.validate = /^[0-9a-f]{40}$/
      q.responses[:not_valid]="\nError :\nThat seems to be incorrect, we would like to have your lighthouse token\n this looks something like : 1bd25cc2bab1fc4384b7edfe48433fba5f6ee43c"
      q.responses[:ask_on_error]="My lighthouse token is : "
    end
    puts

    puts "generated your config in #{fresnel.global_config_file}, going on with main program..."
    File.open(fresnel.global_config_file,'w+'){ |f| f.write(YAML::dump(config)) }
  end
  
  def self.project(fresnel)
    config=Hash.new
    puts "current projects : "
    data=fresnel.projects(:object=>true)
    current_dir=File.expand_path(".").split("/").last
    fresnel.projects

    config['project_id']=ask("please select which project id resides here : ") do |q|
       q.validate = /^\d+$/
       q.responses[:not_valid]="\nError :\nThat seems to be incorrect, we would like to have the <number> part"
       q.responses[:ask_on_error]="This project is : "
     end

     puts "generated your config in #{fresnel.project_config_file}, going on with main program..."
     File.open(fresnel.project_config_file,'w+'){ |f| f.write(YAML::dump(config)) }
  end
end