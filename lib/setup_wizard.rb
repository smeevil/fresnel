class SetupWizard
  def self.global(fresnel)
    if File.exists?(fresnel.global_config_file)
      config=YAML::load_file(fresnel.global_config_file)
    end

    config=Hash.new unless config
    puts "================================================"
    puts "    Fresnel - #{fresnel.app_description}           "
    puts "                config wizard                   "
    puts "================================================"
    puts
    config['account']=ask("My lighthouse account is : ") do |q|
      q.validate = /^\w+$/
      q.responses[:not_valid]="\nError :\nThat seems to be incorrect, we would like to have the <account> part in\nhttp://<account>.lighthouseapp.com , please try again"
      q.responses[:ask_on_error]="My lighthouse account is : "
      q.default=config['account']||ENV['USER']
    end

    puts
    puts "what token would you like to use for the account : #{config['account']} ?"
    config['token']=ask("My lighthouse token is : ") do |q|
      q.validate = /^[0-9a-f]{40}$/
      q.responses[:not_valid]="\nError :\nThat seems to be incorrect, we would like to have your lighthouse token\n this looks something like : 1bd25cc2bab1fc4384b7edfe48433fba5f6ee43c"
      q.responses[:ask_on_error]="My lighthouse token is : "
      q.default=config['token'] if config['token']
    end
    Lighthouse.account=config['account']
    Lighthouse.token=config['token']
    user_id=Lighthouse::Token.get(fresnel.token)['user_id']
    config['user_id']=ask("My lighthouse user_id is : ", Integer) do |q|
      q.default=user_id
    end
    

    puts "generated your config in #{fresnel.global_config_file}, going on with main program..."
    File.open(fresnel.global_config_file,'w+'){ |f| f.write(YAML::dump(config)) }
  end
  
  def self.project(fresnel)
    config=Hash.new
    puts "current projects : "
    data=fresnel.projects(:object=>true)
    current_dir=File.expand_path(".").split("/").last
    fresnel.projects(:selectable=>true)

    project_id=ask("please select which # resides here : ", Integer) do |q|
       q.validate = /^\d+$/
       q.below=data.size
       q.responses[:ask_on_error]="This project is # : "
     end
     config['project_id']=data[project_id].id
     puts "generated your config in #{fresnel.project_config_file}, going on with main program..."
     File.open(fresnel.project_config_file,'w+'){ |f| f.write(YAML::dump(config)) }
  end
end