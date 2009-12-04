require 'active_support'
require 'terminal-table/import'
require 'highline/import'

require "fresnel/lighthouse"
require "fresnel/date_parser"
require "fresnel/cache"
require "fresnel/setup_wizard"
require "fresnel/frame"

HighLine.track_eof = false

class String
  def wrap(col = 80)
    self.gsub(/(.{1,#{col}})( +|$\n?)|(.{1,#{col}})/,
      "\\1\\3\n")
  end

  def truncate(size)
    "#{self.strip[0..size]}#{"..." if self.size>size}"
  end
end

class Fresnel
  attr_reader :global_config_file, :project_config_file, :app_description
  attr_accessor :lighthouse, :current_project_id, :cache, :cache_timeout, :current_user_id

  def initialize(options=Hash.new)
    @global_config_file="#{ENV['HOME']}/.fresnel"
    @project_config_file=File.expand_path('.fresnel')
    @app_description="A lighthouseapp console manager"
    @lighthouse=Lighthouse
    @cache=Cache.new
    Lighthouse.account, Lighthouse.token, @current_user_id = load_global_config
    @current_project_id=load_project_config

  end

  def load_global_config
    if File.exists? self.global_config_file
      config = YAML.load_file(self.global_config_file)

      @@cache_timeout=config['cache_timeout'] if config.has_key?('cache_timeout')
      @@debug=config['debug'] if config.has_key?('debug')
      @@term_size=config['term_size'] if config.has_key?('term_size')

      if config && config.class==Hash && config.has_key?('account') && config.has_key?('token') && config.has_key?('user_id')
        return [config['account'], config['token'], config['user_id']]
      else
        puts Frame.new(:header=>"Warning !",:body=>"global config did not validate , recreating")
        SetupWizard.global(self)
        load_global_config
      end
    else
      puts Frame.new(:header=>"Notice",:body=>"global config not found at #{self.global_config_file}, starting wizard")
      SetupWizard.global(self)
      load_global_config
    end
  end

  def load_project_config
    if File.exists? self.project_config_file
      config = YAML.load_file(self.project_config_file)
      if config && config.class==Hash && config.has_key?('project_id')
        return config['project_id']
      else
        puts Frame.new(:header=>"Warning !",:body=>"project config found but project_id was not declared")
        load_project_config
      end
    else
      puts Frame.new(:header=>"Notice",:body=>"project config not found at #{self.project_config_file}, starting wizard")
      SetupWizard.project(self)
      load_project_config
    end
  end

  def account
    lighthouse.account
  end

  def token
    lighthouse.token
  end

  def ask_for_action(actions_available="")
    if actions_available.present?
      puts actions_available.wrap
      regexp="^(#{actions_available.scan(/\[(.*?)\]/).flatten.join("|")}|[0-9]+)$"
    else
      regexp="^(q|[0-9]+)$"
    end
    ask("Action : ") do |q|
      q.default="q"
      q.validate=/#{regexp}/
    end
  end

  def create_project
    puts "create project is not implemented yet"
  end

  def projects(options=Hash.new)
    options[:object]||=false
    system("clear") unless options[:clear]==false || options[:object]
    options[:selectable]||false
    print "Fetching projects..." unless options[:object]
    projects_data=cache.load(:name=>"fresnel_projects",:action=>"Lighthouse::Project.find(:all)")
    puts " [done] - data is #{projects_data.age}s old , max is #{@@cache_timeout}s"
    project_table = table do |t|
      t.headings=[]
      t.headings << '#' if options[:selectable]
      t.headings += ['project name', 'public', 'open tickets']

      projects_data.each_with_index do |project,i|
        row=Array.new
        row << i if options[:selectable]
        row+=[project.name, project.public, {:value=>project.open_tickets_count, :alignment=>:right}]
        t << row
      end
    end
    if options[:object]
      return projects_data
    else
      puts(project_table)
      unless options[:setup]
        action=ask_for_action("[q]uit, [c]reate or project #")
        case action
          when "c" then create_project
          when /\d+/ then tickets(:project_id=>projects_data[action.to_i].id)
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
      action=ask_for_action("[q]uit, [b]ins, [p]rojects, #{options[:all] ? "[u]nresolved" : "[a]ll"}, [c]reate or ticket #")
      case action
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
      action=ask_for_action("[q]uit, [b]ins, [p]rojects, [u]nresolved, [a]ll, [c]reate")
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
    bin_id=ask_for_action
    if bin_id=="q"
       exit(0)
    else
      puts "Fetching tickets in bin : #{bins[bin_id.to_i].name}"
      tickets(:tickets=>bins[bin_id.to_i].tickets)
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
        "Ticket ##{number} : #{ticket.title.chomp.truncate(55)}",
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
    action=ask_for_action("[q]uit, [t]ickets, [b]ins, [c]omment, [a]ssign, [r]esolve, [s]elf, [o]pen, [h]old, [w]eb, [l]inks")
    case action
      when "t" then tickets
      when "b" then get_bins
      when "c" then comment(number)
      when "a" then assign(:ticket=>number)
      when "r" then change_state(:ticket=>number,:state=>"resolved")
      when "s" then claim(:ticket=>number)
      when "o" then change_state(:ticket=>number,:state=>"open")
      when "h" then change_state(:ticket=>number,:state=>"hold")
      when "w" then open_browser_for_ticket(number)
      when "l" then links(number)
      else
        exit(0)
    end
  end

  def links(number)
    ticket = get_ticket(number)
    links = ticket.versions.map{ |version|
      version.body.to_s.scan(/(http|https)(:\/\/)([a-zA-Z0-9.\/_-]+)| (www\.[a-zA-Z0-9.\/_-]+)/).map{ |url|
        url.join
      }
    }.flatten.uniq
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
      pick=ask("open link # : ", Integer) do |q|
        q.below=links.size
        q.above=-1
      end
      url=links[pick]
      url="http://#{url}" unless url=~/^http/
      `open '#{url}'`
    end
    show_ticket(number)
  end

  def comment(number,state=nil)
    puts "create comment for #{number}"
    ticket=get_ticket(number)
    File.open("/tmp/fresnel_ticket_#{number}_comment", "w+") do |f|
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
        tags=ask("Tags : ")
        tags=tags.split(" ")
      end
      puts "creating ticket..."
      ticket = Lighthouse::Ticket.new(
        :project_id=>self.current_project_id,
        :title=>title,
        :body=>body
      )
      ticket.tags=tags
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
    #fast
    #`open "https://#{self.account}.lighthouseapp.com/projects/#{self.current_project_id}/tickets/#{number}"`
    #or save
    puts "opening ticket #{number}in browser"
    `open "#{get_ticket(number).url}"`
    show_ticket(number)
  end

  def assign(options)
    puts "should assign ticket #{options[:ticket]} to someone :"
    unless options[:user_id]
      members=get_project_members
      members_table = table do |t|
        t.headings = ['#', 'user_id', 'username']
        members.each_with_index do |member,i|
          t << [i, member.user.id, member.user.name]
        end
      end
      puts members_table
      pick=ask("Assign to # : ",Integer) do |q|
        q.above=-1
        q.below=members.count
      end
      options[:user_id]=members[pick].user.id
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
  end

  def claim(options)
    puts "current user is : #{self.current_user_id}"
    ticket=get_ticket(options[:ticket])
    if ticket.state=="new"
      change_state(:ticket=>options[:ticket], :state=>"open", :user_id=>self.current_user_id)  #get around the cache ...
    else
      assign(:ticket=>options[:ticket],:user_id=>self.current_user_id)
    end

  end
end