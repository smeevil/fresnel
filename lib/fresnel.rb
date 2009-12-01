class Fresnel
  attr_reader :config_file, :app_description
  attr_accessor :lighthouse
  
  def initialize(options=Hash.new)
    @config_file="#{ENV['HOME']}/.fresnel"
    @app_description="A lighthouseapp console manager"
    @lighthouse=Lighthouse
    Lighthouse.account, Lighthouse.token = load_config
  end
  
  def config_wizard
    config=Hash.new
    puts "================================================"
    puts "    Fresnel - #{self.app_description}           "
    puts "                config wizard                   "
    puts "================================================"
    puts
    puts "what is your Lighthouse account ? "
    puts "Example : http://<account>.lighthouseapp.com"

    print "My lighthouse account is : "
    config['account']=gets.chomp.downcase
    puts
    puts "what token would you like to use for the account : #{config['account']} ?"
    print "My lighthouse token is : "
    config['token']=gets.chomp.downcase
    puts

    puts "generated your config in #{self.config_file}, going on with main program..."
    File.open(self.config_file,'w+'){ |f| f.write(YAML::dump(config)) }
    load_config
  end

  def load_config
    if File.exists? self.config_file
      config = YAML.load_file(self.config_file)
      if config && config.class==Hash && config.has_key?('account') && config.has_key?('token')
        return [config['account'], config['token']]
      else
        puts "config did not validate , recreating"
        config_wizard
      end
    else
      puts "config not found at #{self.config_file}, starting wizard"
      config_wizard
    end
  end
  
  def account
    lighthouse.account
  end
  
  def token
    lighthouse.token
  end
  
  def projects
    puts "fetching projects..."
    
    project_table = table do |t|
      t.headings = ['id', 'project name', 'public', 'open tickets']
      lighthouse::Project.find(:all).each do |project|
        t << [{:value=>project.id, :alignment=>:right}, project.name, project.public, {:value=>project.open_tickets_count, :alignment=>:right}]
      end
    end    
    puts project_table
  end
  

  
end