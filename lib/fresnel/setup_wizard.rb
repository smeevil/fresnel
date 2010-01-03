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
    
    puts "What are your commonly used tags ?"
    puts "Please write them down like : [l]ow [m]edium [h]igh awe[s]ome"
    puts "When adding tags you can give something like : special s design h"
    puts "this will be expanded to : special awesome design high"
    tags=ask("Tags : ")
    config['tags']=tags.split(" ")
    
    puts "generated your config in #{fresnel.global_config_file}, going on with main program..."
    # TODO: Refactor GlobalConfig into its own object, responsible for loading and saving itself.
    File.open(fresnel.global_config_file,'w+'){ |f| f.write(YAML::dump(config)) }
  end

  def self.project(fresnel)
    config=Hash.new
    data=fresnel.projects(:object=>true)
    current_dir=File.expand_path(".").split("/").last
    fresnel.projects(:selectable=>true, :clear=>false, :setup=>true)
    project_id=InputDetector.new("please select which project # resides here or [c]reate a new one : ", 0...data.size).answer
    if project_id=="c"
      fresnel.create_project
    else
      config['project_id']=data[project_id.to_i].id
      puts "generated your config in #{fresnel.project_config_file}, going on with main program..."
      # TODO: Refactor ProjectConfig into its own object, responsible for loading and saving itself.
      File.open(fresnel.project_config_file,'w+'){ |f| f.write(YAML::dump(config)) }
    end
  end
end