require 'io/console'


class Menu
  attr_reader :name, :content, :options, :menus, :selected_item_hash
  
  @@menus = Hash.new # store all menus here, accessible by name, i.e.
  @@prompt_input_string = ""
  
  # options:  hash of option items (explained below:) with a key of the keystroke that invokes the associated option
  # Option is a hash consisting of Description, array of ValidationRules, Method to call on validation check
  public
  def initialize(name)
    @name = name
    @options = Hash.new
    @to_exit = false
    @@menus[name] = self
    @selected_item_hash = {}
  end
  
  public
  def set_content(content)
    @content = content
  end
  
  # static method for accessing all menus by name
  public
  def Menu.get_menu(name)
    @@menus[name]
  end
  
  # static method for accessing last prompt input string
  public
  def Menu.prompt_input
    @@prompt_input_string
  end
  
  public
  def set_selected_item(hash)
    @selected_item_hash = hash
  end
  
  
  # method that closes the associated menu
  public
  def exit_menu
    @to_exit = true
  end
  
  
  public
  def add_option(key, is_case_sensitive, name, rules, on_validation)
    options[key] = {Name: name, Rules: rules, on_valid: on_validation}
    if !is_case_sensitive
      if options.has_key?(key.upcase)
        options[key.downcase] = {Name: name, Rules: rules, on_valid: on_validation}
      else
        options[key.upcase] = {Name: name, Rules: rules, on_valid: on_validation}
      end
    end
  end
  
  # Displays the content of this menu and waits for input
  public
  def display
    
    @to_exit = false # exit this menu when true
    while !@to_exit do
      @content.call
      if !@to_exit
        Menu.handle_input_key(@options)
      end
    end
    
  end
    
  
  # Waits for and handles user input key stroke selections
  private
  def Menu.handle_input_key(options)
    if @to_exit # exit menu without processing input 
      return
    end
    
    printf "press a key\n"
    chr = STDIN.getch
    
    if options.has_key?(chr)
      failed_rule = Menu.validate_rules(options[chr][:Rules])
      if failed_rule != nil
        failed_rule[:on_invalid].call
      else
        options[chr][:on_valid].call
      end
    end
  end
  
  
  # Menu.handle_input_prompt:
  # Example of options parameter:
  #options = [{
  #  conditions: [{
  #    rule: lambda {input.to_i==1},  on_fail: lambda {puts "fail"}},
  #    rule: lambda {input.to_i>1}, on_fail: lambda {puts "fayl"}
  #  ],
  #  handler: lambda {puts "it works!"},
  #  reprompt_on_success: false,
  #  reprompt_on_failure: false}
  # ]
  public
  def Menu.handle_input_prompt(prompt, options)
    begin # reprompt loop
      print "#{prompt}"
      @@prompt_input_string = gets.chomp
      reprompt = false
      options.each do |option|
        is_valid = true
        option[:conditions].each do |condition| # check all conditions for this option
          is_valid = condition[:rule].call
          if !is_valid
            condition[:on_fail].call
            reprompt = option[:reprompt_on_failure]
            break
          end
        end
        if is_valid
          option[:handler].call
          reprompt = option[:reprompt_on_success] || option[:reprompt_while].call
          break
        end
      end
    end while reprompt == true
    @@prompt_input_string = ""
  end
    

  # Validates an array of rules
  # Returns failed rule when invalid or null when valid
  private
  def self.validate_rules(rules)
    pass = true
    rules.each do |rule|
      if  !rule[:rule].call
        return rule
      end
    end
    return nil
  end
    
      
end

      