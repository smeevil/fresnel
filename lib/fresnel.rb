%w(activesupport active_support).each { |l| require l rescue nil }
require 'terminal-table/import'
require 'highline/import'

require "fresnel/lighthouse"
require "fresnel/date_parser"
require "fresnel/cache"
require "fresnel/setup_wizard"
require "fresnel/frame"
require "fresnel/string"
require "fresnel/input_detector"

HighLine.track_eof = false

LICENSES={
  'mit' => "MIT License",
  'apache-2-0' => "Apache License 2.0",
  'artistic-gpl-2' => "Artistic License/GPLv2",
  'gpl-2' => "GNU General Public License v2",
  'gpl-3' => "GNU General Public License v3",
  'lgpl' => "GNU Lesser General Public License",
  'mozilla-1-1' => "Mozilla Public License 1.1",
  'new-bsd' => "New BSD License",
  'afl-3' => "Academic Free License v. 3.0"
}.sort

class Fresnel
  attr_reader :global_config_file, :project_config_file, :app_description
  attr_accessor :lighthouse, :current_project_id, :cache, :cache_timeout, :current_user_id

  def initialize(options=Hash.new)
    @global_config_file="#{ENV['HOME']}/.fresnel"
    @project_config_file=File.expand_path('.fresnel')
    @app_description="A lighthouseapp console manager"
    @lighthouse=Lighthouse
    @cache=Cache.new
    load_global_config
    load_project_config
  end

  def load_global_config
    unless File.exists? self.global_config_file
      puts Frame.new(:header=>"Notice",:body=>"global config not found at #{self.global_config_file}, starting wizard")
      SetupWizard.global(self)
      return load_global_config
    end

    config = YAML.load_file(self.global_config_file)

    @@cache_timeout=config['cache_timeout'] if config.has_key?('cache_timeout')
    @@debug=config['debug'] if config.has_key?('debug')
    @@term_size=config['term_size'] if config.has_key?('term_size')
    @@tags=config['tags']
    @@default_account=config['default_account']
    @@accounts=config['accounts']
    
    
    unless config && config.class==Hash && config.has_key?('default_account') && config.has_key?('user_id')  && config.has_key?('tags')
      puts Frame.new(:header=>"Warning !",:body=>"global config did not validate , recreating")
      SetupWizard.global(self)
      return load_global_config
    end

    @lighthouse_account = config['accounts'][@@default_account]['account']
    @lighthouse_token = config['accounts'][@@default_account]['token']
    @current_user_id = config['user_id']
    initialize_lighthouse
    nil
  end

  def initialize_lighthouse
    @lighthouse.account = @lighthouse_account
    @lighthouse.token = @lighthouse_token
    nil
  end

  def load_project_config
    unless File.exists? self.project_config_file
      puts Frame.new(:header=>"Notice",:body=>"project config not found at #{self.project_config_file}, starting wizard")
      SetupWizard.project(self)
      return load_project_config
    end

    config = YAML.load_file(self.project_config_file) || Hash.new
    unless config.has_key?('project_id') && config.has_key?('account_name')
      puts Frame.new(:header=>"Warning !",:body=>"project config found but did not validate, recreating ")
      return load_project_config
    end
    if config.has_key?('account_name')
      @lighthouse_account = @@accounts[config['account_name']]['account']
      @lighthouse_token = @@accounts[config['account_name']]['token']
    end
    @current_project_id = config['project_id']
    @@tags=config['tags'] if config.has_key?('tags')
    @@cache_timeout=config['cache_timeout'] if config.has_key?('cache_timeout')
    @@debug=config['debug'] if config.has_key?('debug')
    @@term_size=config['term_size'] if config.has_key?('term_size')
    initialize_lighthouse
    nil
  end

  def account
    lighthouse.account
  end

  def token
    lighthouse.token
  end

  def create_project
    name=ask("Name of this project : ")
    type=InputDetector.new("[p]rivate or [o]ss : ").answer
    if type=="o"
      row=Array.new
      license_table = table do |t|
        t.headings=['#' , 'license']
        LICENSES.each_with_index do |lic,i|
          t<<[i, lic.last]
        end
      end
      puts license_table
      license=InputDetector.new("License # : ",(0...LICENSES.size).to_a).answer
      license=LICENSES[license.to_i].first
    end

    puts "collected :"
    puts "#{name} : #{license}"
    project = Lighthouse::Project.new(:name => name)
    if license.present?
      project.access = 'oss'
      project.license = license
    end
    puts "creating project on lighthouse..."
    project.save
    config=Hash.new
    config['project_id']=project.id
    File.open(self.project_config_file,'w+'){ |f| f.write(YAML::dump(config)) }
    load_project_config
  end

  def projects(options=Hash.new)
    system("clear")
    options[:object]||=false
    system("clear") unless options[:clear]==false || options[:object]
    options[:selectable]||false
    projects_data=Hash.new
    project_ids=Array.new
    if @@accounts.size>1
      print "Fetching projects from multiple accounts : " unless options[:object]
      @@accounts.each do |key,value|
        print "#{key} "
        STDOUT.flush
        Lighthouse.account=value['account']
        Lighthouse.token=value['token']
        projects_data[Lighthouse.account]=Lighthouse::Project.find(:all)
      end
      puts " [done]"
    else
      print "Fetching projects..." unless options[:object]
      #projects_data=cache.load(:name=>"fresnel_projects"){Lighthouse::Project.find(:all)} #no cache for now
      projects_data[Lighthouse.account]=Lighthouse::Project.find(:all)
      puts " [done]"
    end
    
    #puts " [done] - data is #{projects_data.age}s old , max is #{@@cache_timeout}s" #no cache for now
    project_table = table do |t|
      t.headings=[]
      t.headings << '#' if options[:selectable]
      t.headings += ["account"] if @@accounts.size>1
      t.headings += [ 'project name', 'public', 'open tickets']
      i=0
      projects_data.each do |key,value|
        value.each do |project|
          row=Array.new
          row << i if options[:selectable]
          project_ids<<"#{project.id};#{key}"
          row+=[key] if @@accounts.size>1
          row+=[project.name, project.public, {:value=>project.open_tickets_count, :alignment=>:right}]
          t << row
          i+=1
        end
      end        
    end
    if options[:object]
      projects_data[:project_ids]=project_ids
      return projects_data
    else
      puts(project_table)
      unless options[:setup]
        action=InputDetector.new("[q]uit, [c]reate or project #",(0..project_ids.size).to_a).answer
        puts "action is #{action.inspect}"
        case action
          when "c" then create_project
          when /\d+/ then 
            project_ids[action.to_i]=~/(\d+);(\w+)/
            project_id=$1
            account=$2
            
            Lighthouse.account=@@accounts[account]["account"]
            Lighthouse.token=@@accounts[account]["token"]
            
            tickets(:project_id=>project_id)
          else
            exit(0)
        end
      end
    end
  end

  def tickets(options=Hash.new)
    system("clear")
    options[:all] ? print("Fetching all tickets#{" in bin #{options[:bin_name]}" if options[:bin_name].present?}...") : print("Fetching unresolved tickets#{" in bin #{options[:bin_name]}" if options[:bin_name].present?}...")
    STDOUT.flush
    @current_project_id=options[:project_id]||self.current_project_id
    project_id=options[:project_id]||self.current_project_id
    tickets=options[:tickets]||cache.load(:name=>"fresnel_project_#{project_id}_tickets#{"_all" if options[:all]}", :action=>"Lighthouse::Ticket.find(:all, :params=>{:project_id=>#{project_id} #{",:q=>'not-state:closed'" unless options[:all]}})")
    puts " [done] - data is #{tickets.age}s old , max is #{@@cache_timeout}s"
    if tickets.any?
      tickets_table = table do |t|
        prepped_headings=[
          {:value=>'#',:alignment=>:center},
          {:value=>'state',:alignment=>:center},
          {:value=>'title',:alignment=>:center},
        ]
        prepped_headings << {:value=>'assigned to',:alignment=>:center} if @@term_size>=90
        prepped_headings << {:value=>'by',:alignment=>:center} if @@term_size>=105
        prepped_headings << {:value=>'tags',:alignment=>:center} if @@term_size>=120
        prepped_headings << 'created at' if @@term_size>=140
        prepped_headings << 'updated at' if @@term_size>=160

        t.headings = prepped_headings #must assign the heading at once, else it will b0rk the output

        tickets.sort_by(&:number).reverse.each do |ticket|
          cols=[
            {:value=>ticket.number, :alignment=>:right},
            {:value=>ticket.state,:alignment=>:center},
            "#{ticket.title.truncate(50)}"
          ]
          cols << (ticket.assigned_user_name.split(" ").first.truncate(10) rescue "nobody") if @@term_size>=90
          cols << ticket.creator_name.split(" ").first.truncate(10) if @@term_size>=105
          cols << (ticket.tag.truncate(9) rescue "") if @@term_size>=120
          cols << {:value=>DateParser.string(ticket.created_at.to_s), :alignment=>:right} if @@term_size>=140
          cols << {:value=>DateParser.string(ticket.updated_at.to_s), :alignment=>:right} if @@term_size>=160

          t << cols #must assign the cols at once, else it will b0rk the output
        end
      end
      puts tickets_table
      action=InputDetector.new("[q]uit, [b]ins, [p]rojects, #{options[:all] ? "[u]nresolved" : "[a]ll"}, [c]reate , [r]efresh/[t]ickets or ticket # : ",tickets.map(&:number)).answer
      case action
        when /t|r/ then
          cache.clear(:name=>"fresnel_project_#{project_id}_tickets")
          self.tickets
        when "b" then get_bins
        when "c" then create
        when "p" then projects(:selectable=>true)
        when "a" then tickets(:all=>true)
        when "u" then self.tickets
        when /\d+/ then show_ticket(action)
        else
          exit(0)
      end
    else
      puts Frame.new(:header=>"Notice",:body=>"no #{"unresolved " unless options[:all]}tickets #{"in bin #{options[:bin_name]}"}...")
      action=InputDetector.pretty_prompt(:actions => %w[quit bins projects unresolved all create]).answer
      case action
        when "b" then get_bins
        when "c" then create
        when "p" then projects(:selectable=>true)
        when "a" then tickets(:all=>true)
        when "u" then self.tickets
        else
          exit(0)
      end

    end

  end

  def get_bins(project_id=self.current_project_id)
    system("clear")
    print "Fetching ticket bins..."
    STDOUT.flush
    bins=cache.load(:name=>"fresnel_project_#{project_id}_bins",:action=>"Lighthouse::Project.find(#{project_id}).bins")
    puts " [done] - data is #{bins.age}s old , max is #{@@cache_timeout}s"
    bins.reject!{|b|true unless b.user_id==self.current_user_id || b.shared}
    bins_table = table do |t|
      t.headings = ['#', 'bin', 'tickets', 'query']
      bins.each_with_index do |bin,i|
        t << [i, bin.name,{:value=>bin.tickets_count, :alignment=>:right},bin.query]
      end
    end
    puts bins_table
    bin_id=InputDetector.new("[q]uit or Bin #: ",(0...bins.size).to_a).answer
    if bin_id=="q"
       exit(0)
    else
      puts "Fetching tickets in bin : #{bins[bin_id.to_i].name}"
      data=bins[bin_id.to_i].tickets

      def data.age=(seconds)
        @age_in_seconds=seconds
      end
      def data.age
        @age_in_seconds
      end
      data.age=0
      tickets(:tickets=>data)
      def tickets.age=(seconds)
        @age_in_seconds=seconds
      end
      def tickets.age
        @age_in_seconds
      end
      tickets.age=0
      return tickets
    end
  end

  def get_tickets_in_bin(bin)
    bins=cache.load(:name=>"fresnel_project_#{self.current_project_id}_bins",:action=>"Lighthouse::Project.find(#{self.current_project_id}).bins")
    bins.reject!{|b|true unless b.user_id==self.current_user_id || b.shared}
    data=bins[bin.to_i].tickets

    def data.age=(seconds)
      @age_in_seconds=seconds
    end
    def data.age
      @age_in_seconds
    end
    data.age=0

    tickets(:tickets=>data, :bin_name=>bins[bin.to_i].name)
  end

  def get_ticket(number)
    cache.load(:name=>"fresnel_ticket_#{number}",:action=>"Lighthouse::Ticket.find(#{number}, :params => { :project_id => #{self.current_project_id} })")
  end

  def get_project(project_id=self.current_project_id)
    cache.load(:name=>"fresnel_project_#{project_id}",:action=>"Lighthouse::Project.find(#{project_id})")
  end

  def get_project_members(project_id=self.current_project_id)
    cache.load(:name=>"fresnel_project_#{project_id}_members", :action=>"Lighthouse::Project.find(#{project_id}).memberships", :timeout=>1.day)
  end

  def show_ticket(number)
    system("clear")
    ticket = get_ticket(number)
    puts Frame.new(
      :header=>[
        "Ticket ##{number} : #{ticket.title.chomp.truncate(@@term_size-5)}",
        "Date : #{DateParser.string(ticket.created_at.to_s)} by #{ticket.creator_name}",
        "Tags : #{ticket.tag}"
      ],
      :body=>ticket.versions.first.body
    )
    ticket.versions.each_with_index do |v,i|
      next if i==0
      if v.respond_to?(:diffable_attributes) && v.body.nil?
        puts "\nState changed #{DateParser.string(v.created_at.to_s)} from #{v.diffable_attributes.state} => #{v.state} by #{v.user_name}\n\n" if v.diffable_attributes.respond_to?(:state)
        puts "\nAssignment changed #{DateParser.string(v.created_at.to_s)} => #{v.assigned_user_name rescue "Nobody"} by #{v.user_name}\n\n" if v.diffable_attributes.respond_to?(:assigned_user)
      else
        user_date=v.user_name.capitalize
        date=DateParser.string(v.created_at.to_s)
        user_date=user_date.ljust((@@term_size-5)-date.size)
        user_date+=date

        footer=Array.new
        footer<<"State changed from #{v.diffable_attributes.state} => #{v.state}" if v.diffable_attributes.respond_to?(:state)
        footer<<"Assignment changed => #{v.assigned_user_name}" if v.diffable_attributes.respond_to?(:assigned_user)

        puts Frame.new(:header=>user_date,:body=>v.body,:footer=>footer)
      end
    end
    puts "Current state : #{ticket.versions.last.state}"
    choices = {
      :states => %w[open resolved invalid hold new],
      :actions => %w[quit tickets bins comments assign self web links errors Tag]
    }
    states = choices[:states]
    action=InputDetector.pretty_prompt(choices).answer
    case action
      when "T" then tag(:ticket=>number)
      when "t" then tickets
      when "b" then get_bins
      when "c" then comment(number)
      when "a" then assign(:ticket=>number)
      when "s" then claim(:ticket=>number)
      when "w" then open_browser_for_ticket(number)
      when "l" then links(number)
      when "e" then errors(number)
      when *(states.map{|state| state[0,1]})
        change_state(:ticket=>number,:state=>states.find{|state| state[0,1] == action})
      else
        exit(0)
    end
  end

  def links(number)
    ticket = get_ticket(number)
    links = ticket.versions.map{ |version| version.body.to_s.scrape_urls }.flatten.uniq
    if links.size == 0
      puts "No links found"
      sleep 1
    elsif links.size == 1
      url = links.first
      url="http://#{url}" unless url=~/^http/
      `open '#{url}'`
    else
      link_table=table do |t|
        t.headings=['#','link']
        links.each_with_index{|link,i|t << [i,link]}
      end
      puts link_table
      pick=InputDetector.new("open link # : ", (0...links.size).to_a).answer
      url=links[pick.to_i]
      url="http://#{url}" unless url=~/^http/
      `open '#{url}'`
    end
    show_ticket(number)
  end

  def errors(number)
    ticket = get_ticket(number)
    errors = ticket.versions.map{ |version| version.body.to_s.scrape_textmate_links }.flatten
    if errors.size == 0
      puts "No errors found"
      sleep 1
    elsif errors.size == 1
      error=errors.first
      error=~/(.*?):(\d+)/
      `mate -l #{$2} #{File.expand_path(".")}#{$1.gsub(/^\./,"")}`
    else
      error_table=table do |t|
        t.headings=['#','error']
        errors.each_with_index{|error,i|t << [i,error]}
      end
      puts error_table
      pick=InputDetector.new("open error # : ", (0...errors.size).to_a).answer
      error=errors[pick.to_i]
      error=~/(.*?):(\d+)/
      `mate -l #{$2} #{File.expand_path(".")}#{$1.gsub(/^\./,"")}`
    end
    show_ticket(number)
  end
  
  def comment(number,state=nil)
    puts "create comment for #{number}"
    ticket=get_ticket(number)
    File.open("/tmp/fresnel_ticket_#{number}_comment", "w+") do |f|
      f.puts
      f.puts "# Please enter the comment for this ticket. Lines starting"
      f.puts "# with '#' will be ignored, and an empty message aborts the commit."
      `echo "q" | fresnel #{number}`.each{ |l| f.write "# #{l}" }
    end
    system("mate -w /tmp/fresnel_ticket_#{number}_comment")
    body=Array.new
    File.read("/tmp/fresnel_ticket_#{number}_comment").each do |l|
      body << l unless l=~/^#/
    end

    body=body.to_s
    if body.blank?
      puts Frame.new(:header=>"Warning !", :body=>"Aborting comment because it was blank !")
    else
      ticket.body=body
      ticket.state=state unless state.nil?
      if ticket.save
        cache.clear(:name=>"fresnel_ticket_#{number}")
        show_ticket(number)
      else
        puts "something went wrong"
        puts $!
      end
    end
  end

  def tag(options)
    ticket=get_ticket(options[:ticket])
    tags=ask("Tags #{@@tags.join(", ")} : ")
    tags=tags.split(" ")
    expanded_tags=[]
    tags.each do |tag|
      match=false
      if tag.length==1
        @@tags.each do |predefined_tag|
          if predefined_tag=~/\[#{tag}\]/
            match=true
            expanded_tags<<predefined_tag.gsub(/\[|\]/,"")
          end
        end
      end
      expanded_tags<<tag unless match
    end
    puts "tags are #{expanded_tags.inspect}"
    ticket.tags=expanded_tags
    ticket.save
    tickets
  end
  
  
  def create
    system("mate -w /tmp/fresnel_new_ticket")
    if File.exists?("/tmp/fresnel_new_ticket")
      data=File.read("/tmp/fresnel_new_ticket")
      body=Array.new
      title=""
      if data.blank?
        puts Frame.new(:header=>"Warning !", :body=>"Aborting creation because the ticket was blank !")
      else
        data.each do |l|
          if title.blank?
            title=l
            next
          end
          body << l
        end
        body=body.to_s
        tags=ask("Tags #{@@tags.join(", ")} : ")
        tags=tags.split(" ")
        expanded_tags=[]
        tags.each do |tag|
          match=false
          if tag.length==1
            @@tags.each do |predefined_tag|
              if predefined_tag=~/\[#{tag}\]/
                match=true
                expanded_tags<<predefined_tag.gsub(/\[|\]/,"")
              end
            end
          end
          expanded_tags<<tag unless match
        end
      end
      puts "tags are #{expanded_tags.inspect}"
      puts "creating ticket..."
      ticket = Lighthouse::Ticket.new(
        :project_id=>self.current_project_id,
        :title=>title,
        :body=>body
      )
      ticket.tags=expanded_tags
      if ticket.save
        File.delete("/tmp/fresnel_new_ticket")
        show_ticket(ticket.number)
      else
        puts "something went wrong !"
        puts $!
      end
    else
      puts Frame.new(:header=>"Warning !", :body=>"Aborting creation because the ticket was blank !")
    end
  end

  def change_state(options)
    puts "should change state to #{options.inspect}"
    ticket=get_ticket(options[:ticket])
    old_state=ticket.state
    options[:state]="resolved" if options[:state]=~/closed?/
    if options[:state]=~/resolved|invalid/
      comment(options[:ticket],options[:state])
    else
      ticket.state=options[:state]
      ticket.assigned_user_id=options[:user_id] if options[:user_id].present?
      if ticket.save
        cache.clear(:name=>"fresnel_ticket_#{options[:ticket]}")
        if options[:user_id].present?
          user_name = Lighthouse::User.find(options[:user_id]).name
          puts Frame.new(:header=>"Success",:body=>"State has changed from #{old_state} to #{options[:state]} #{"and is reassigned to #{user_name}"}")
        end
        show_ticket(options[:ticket])
      else
        puts Frame.new(:header=>"Error !",:body=>"Something went wrong ! #{$!}")
      end
    end
  end

  def open_browser_for_ticket(number)
    puts "opening ticket #{number}in browser"
    `open "#{get_ticket(number).url}"`
    show_ticket(number)
  end

  def assign(options)
    unless options[:user_id]
      puts "should assign ticket #{options[:ticket]} to someone :"
      members=get_project_members
      members_table = table do |t|
        t.headings = ['#', 'user_id', 'username']
        members.each_with_index do |member,i|
          t << [i, member.user.id, member.user.name]
        end
      end
      puts members_table
      pick=InputDetector.new("Assign to user # : ",((0...members.size).to_a)).answer
      options[:user_id]=members[pick.to_i].user.id
    end
    ticket=get_ticket(options[:ticket])
    ticket.assigned_user_id=options[:user_id]
    if ticket.save
      cache.clear(:name=>"fresnel_ticket_#{options[:ticket]}")
      user_name = Lighthouse::User.find(options[:user_id]).name
      puts Frame.new(:header=>"Success",:body=>"Reassigned ticket ##{options[:ticket]} to #{user_name} !")
    else
      puts Frame.new(:header=>"Error",:body=>"assigning failed !")
    end
    show_ticket(options[:ticket])
  end

  def claim(options)
    puts "current user is : #{Lighthouse::User.find(self.current_user_id).name}"
    ticket=get_ticket(options[:ticket])
    if ticket.state=="new"
      change_state(:ticket=>options[:ticket], :state=>"open", :user_id=>self.current_user_id)  #get around the cache ...
    else
      assign(:ticket=>options[:ticket],:user_id=>self.current_user_id)
    end
    show_ticket(options[:ticket])
  end
  
  def create_extra_account
    config=YAML::load_file(self.global_config_file)
    
    puts "should add an extra account !"
    config['account']=ask("My extra lighthouse account is : ") do |q|
      q.validate = /^\w+$/
      q.responses[:not_valid]="\nError :\nThat seems to be incorrect, we would like to have the <account> part in\nhttp://<account>.lighthouseapp.com , please try again"
      q.responses[:ask_on_error]="My extra account is : "
    end
    
    config['accounts'][config['account']]={'account'=>config['account']}
    puts
    puts "what token would you like to use for the account : #{config['account']} ?"
    config['accounts'][config['account']]['token']=ask("My lighthouse token is : ") do |q|
      q.validate = /^[0-9a-f]{40}$/
      q.responses[:not_valid]="\nError :\nThat seems to be incorrect, we would like to have your lighthouse token\n this looks something like : 1bd25cc2bab1fc4384b7edfe48433fba5f6ee43c"
      q.responses[:ask_on_error]="My lighthouse token is : "
      q.default=config['token'] if config['token']
    end
    File.open(self.global_config_file,'w+'){ |f| f.write(YAML::dump(config)) }
    load_global_config
  end
end