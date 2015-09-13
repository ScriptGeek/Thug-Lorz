require './menu.rb'
require './storage.rb'
require './drugs.rb'
require './player.rb'


# initialize a set of drug items
Drugs.new

# initialize player starting values
cash = 2000
debt = 2000
bank_balance = 0
health = 100
has_gun = false
storage_item = "pockets"
inventory = {}
Player.new(cash, debt, bank_balance, health, storage_item, inventory, has_gun)


class Game
  
  class << self
    attr_accessor :day, :max_days, :main_menu
  end
    
  def initialize(main_menu)
    Game.day = 0
    Game.max_days = 30
    Game.main_menu = main_menu
    Player.travel_to("Santa Monica")
  end
  
  def self.set_next_day
    @day += 1
    if @day > @max_days
      game_over("Out-Of-Time")
    end
  end
  
  def self.game_over(status)
    Menu.get_menu("Travel").exit_menu
    Menu.get_menu("Main").exit_menu

win_string = "│  Lorz: 'Usually a 3rd wheel, someone who tags  │
│    along or fills in the gap when the best     │
│   friend isn't there' - urbandictionary.com    │"

lose_string = "│    Your consciousness fades into blackness     │
│  as you drift to your next life and all your   │
│       hard-earned wealth is left behind.       │
│            Better luck next time!              │"
puts "
┌────────────────────────────────────────────────┐
│                 G A M E   O V E R              │
├────────────────────────────────────────────────┤
│                                                │
#{Player.health > 0 ? win_string : lose_string}
│                                                │
│                                                │
│                                                │
#{status.center(48).center(50,"│")}
│                                                │
#{"Total Score:".center(48).center(50,"│")}
#{Player.get_score.to_s.center(48).center(50,"│")}
│                                                │
└────────────────────────────────────────────────┘"
end

  def self.choose_random_event
    events = [
    {probability: 15, event: lambda {
      Player.generate_loot
      Menu.get_menu("Found Loot").display
    }},
    {probability: 5, event: lambda {
      Player.set_enemy_health
      Menu.get_menu("Mugger").display
    }},
    {probability: 5, event: lambda {
      Player.set_enemy_health
      Menu.get_menu("Cop").display
    }},
    {probability: 10, event: lambda {
      #FIXME: spawn black market item here
      set_black_market_item
      Menu.get_menu("Black Market").display
    }},
    {probability: 65, event: lambda {
      puts "Nothing out of the ordinary happens, you safely arrive at your destination."
    }}]
      
    rnd = Random.rand(0..100)
    n = 0
    events.each do |event|
      n += event[:probability]
      if rnd < n
        event[:event].call
        break
      end
    end  
  end
end # end of class


# construct all the user menus for the entire game here
puts "

┌─────────────────────────────────────────────────┐
│                T H U G   L O R Z                │
├─────────────────────────────────────────────────┤
│                                                 │
│ An immersive text-based drug dealer simulation. │
│                                                 │
│ Not for the faint of heart,                     │
│                       proceed at your own risk! │
│                                                 │
│            Press SPACE KEY to begin             │
│                      - or -                     │
│        Press the SCARDEY-CAT KEY to quit        │
│                                                 │
└─────────────────────────────────────────────────┘
"
#Wait for Space Key
while STDIN.getch != ' ' do
end

# MAIN MENU
main_menu = Menu.new("Main")
main_menu.set_content(lambda {
  puts "
#{Player.location.center(50)}

Day: #{Game.day}/#{Game.max_days}
Health: #{Player.health}
Cash: $#{Player.cash}
Debt: $#{Player.debt}
Bank: $#{Player.bank_balance}
Gun: Insert Yes or No here
Storage Item: #{Player.storage_item}
Capacity: #{Player.get_inventory_utilization} / #{Storage.get_capacity(Player.storage_item)}
Inventory:
"
#{Player.display_inventory}
  puts "
OPTIONS:

(P)urchase drugs
(S)ell drugs
(B)ank
(H)ospital
(L)oan Shark
(T)ravel
(Q)uit

"
})

main_menu.add_option("q", false, "Quit", [{ rule: lambda {true}, on_invalid: lambda{} }], lambda {
  Menu.handle_input_prompt("Are you sure you want to quit? (y/n) ",
    [{conditions: [{
        rule: lambda {Menu.prompt_input.upcase == "Y"}, on_fail: lambda {}}
      ],
      handler: lambda {Menu.get_menu("Main").exit_menu},
      reprompt_on_success: false,
      reprompt_on_failure: false,
      reprompt_while: lambda {false}
      },
     {conditions: [{
        rule: lambda {Menu.prompt_input.upcase == "N"}, on_fail: lambda {}}
      ],
      handler: lambda {},
      reprompt_on_success: false,
      reprompt_on_failure: false,
      reprompt_while: lambda {false}}
    ])
})

# DRUG PURCHASE MENU
drug_purchase_menu = Menu.new("Purchase Drugs")
drug_purchase_menu.set_content(lambda {
  puts "
Purchase Drugs
---------"

  drug_name_to_selector_keys_hash = Drugs.get_drug_name_to_selector_key_hash
  inventory = Player.inventory
  price_list = Drugs.get_price_list
  
  selection_width = 5
  qty_width = 3
  drug_name_width = 9
  price_width = 7
  
  if Player.get_available_inventory_capacity <= 0 
    puts "Storage is full, sell some drugs before buying more"
    puts "(ESC) to return to previous menu\n\n"
    return
  else
    puts "You have $#{Player.cash}\n\n"
  end
  
# Display header
  puts "Key".ljust(selection_width)+"Qty".rjust(qty_width)+"Drug".rjust(drug_name_width)+"Price".rjust(price_width)

  drug_name_to_selector_keys_hash.each do |key, value|
    qty = 0
    if inventory.has_key?(key)
      qty = inventory[key]
    end
    puts value.ljust(selection_width)+qty.to_s.rjust(qty_width)+key.rjust(drug_name_width)+price_list[key].to_s.rjust(price_width)
    
    drug_purchase_menu.add_option(value, false, key, [{ rule: lambda {
      price_list[key] <= Player.cash &&
      Player.get_available_inventory_capacity > 0
    }, on_invalid: lambda {
      if price_list[key] > Player.cash
        puts "Not enough cash to purchase #{key}."
      elsif Player.get_available_inventory_capacity == 0
        puts "Not enough available storage space, sell some drugs first."
      end
    } }], lambda {
    puts "capacity: #{Player.get_available_inventory_capacity}"
    max_item_purchase = [Player.get_available_inventory_capacity, Player.cash / price_list[key]].min
    Menu.handle_input_prompt("Enter number of units of #{key} to purchase (max: #{max_item_purchase}): ",
      [{conditions: [
        {rule: lambda {Menu.prompt_input =~ /\A\d+\z/ ? true : false}, on_fail: lambda {puts "Input must be a number."}},
        {rule: lambda {Menu.prompt_input.to_i >= 0}, on_fail: lambda {puts "Input must be greater than zero."}},
        {rule: lambda {Menu.prompt_input.to_i <= Player.get_available_inventory_capacity}, on_fail: lambda {puts "Not enough room in your stash for #{Menu.prompt_input.to_i} units as there is only enough room for #{Player.get_available_inventory_capacity} units."}},
        {rule: lambda {Menu.prompt_input.to_i <= Player.cash / price_list[key]}, on_fail: lambda {puts "Not enough funds."}}
      ],
      handler: lambda {Player.perform_drug_transaction(key, Menu.prompt_input.to_i, price_list[key])},
      reprompt_on_success: false,
      reprompt_on_failure: true,
      reprompt_while: lambda {false}}
    ])
  })

end
  puts "(ESC) to return to previous menu\n\n"
})

drug_purchase_menu.add_option("\e", true, "Exit Menu", [{ rule: lambda {true}, on_invalid: lambda {} }], lambda {Menu.get_menu("Purchase Drugs").exit_menu})
main_menu.add_option("p", false, "Purchase Drugs", [{ rule: lambda {true}, on_invalid: lambda {} }], lambda {drug_purchase_menu.display})

# DRUG SELLING MENU
drug_sell_menu = Menu.new("Sell Drugs")
drug_sell_menu.set_content(lambda {
  puts "
Sell Drugs
---------"

drug_name_to_selector_keys_hash = Drugs.get_drug_name_to_selector_key_hash
inventory = Player.inventory
price_list = Drugs.get_price_list

selection_width = 5
qty_width = 3
drug_name_width = 9
price_width = 7

if Player.get_inventory_utilization == 0
  puts "You have no drugs to sell."
  puts "(ESC) to return to previous menu\n\n"
  return
else
  puts "You have $#{Player.cash}\n"
end

puts #{"Key".ljust(selection_width)#{"Qty".rjust(qty_width)#{"Drug".rjust(drug_name_width)}#{"Price".rjust(price_width)}
drug_name_to_selector_keys_hash.each do |key, value|
  qty = 0
  if inventory.has_key?(key)
    qty = inventory[key]
  end
  puts "#{("("+value+")").ljust(selection_width)}#{qty.to_s.rjust(qty_width)}#{key.rjust(drug_name_width)}#{price_list[key].to_s.rjust(price_width)}"
  
  # Create menu option here, for item selection
  drug_sell_menu.add_option(value, false, key, [{rule: lambda { inventory.has_key?(key) }, on_invalid: lambda { puts "You don't have any #{key}."} }], lambda {
  Menu.handle_input_prompt("Enter number of units of #{key} to sell (max: #{qty}):  ",
    [{conditions: [
      {rule: lambda {Menu.prompt_input =~ /\A\d+\z/ ? true : false}, on_fail: lambda {puts "Input must be a number."}},
      {rule: lambda {Menu.prompt_input.to_i >= 0}, on_fail: lambda {puts "Input must be greater than zero."}},
      {rule: lambda {Menu.prompt_input.to_i <= qty}, on_fail: lambda {puts "Not enough units for transaction"}}
      ],
      handler: lambda {Player.perform_drug_transaction(key, Menu.prompt_input.to_i * -1, price_list[key])},
      reprompt_on_success: false,
      reprompt_on_failure: true,
      reprompt_while: lambda {false}}
    ])
  })
end  
puts "(ESC) to return to previous menu\n\n"
})

drug_sell_menu.add_option("\e", true, "exit", [{ rule: lambda {true}, on_invalid: lambda {} }], lambda {Menu.get_menu("Sell Drugs").exit_menu})
main_menu.add_option("s", false, "Sell Drugs", [{ rule: lambda {true}, on_invalid: lambda {} }], lambda {drug_sell_menu.display})

bank_menu = Menu.new("Bank")
# BANK MENU
bank_menu.set_content(lambda {
  puts "
Bank
---------
#{"Cash: ".ljust(11)+Player.cash.to_s.rjust(11)}
#{"Account:".ljust(11)+Player.bank_balance.to_s.rjust(11)}

(D)eposit funds
(W)ithdraw funds
(ESC) to return to previous menu\n\n"
})

# Create menu option here, for item selection
bank_menu.add_option("d", false, "Deposit", [{rule: lambda { Player.cash > 0 }, on_invalid: lambda{ puts "You don't have any cash to deposit!"} }], lambda {
  Menu.handle_input_prompt("Enter funds to deposit: ",
  [{conditions: [
    {rule: lambda {Menu.prompt_input =~ /\A\d+\z/ ? true : false}, on_fail: lambda {puts "Value entered must be a number."}},
    {rule: lambda {Menu.prompt_input.to_i >= 0}, on_fail: lambda {puts "Cannot desposit less than zero funds."}},
    {rule: lambda {Menu.prompt_input.to_i <= Player.cash}, on_fail: lambda {puts "Not enough funds."}}
    ],
    handler: lambda {Player.perform_bank_transaction(Menu.prompt_input.to_i * -1)},
    reprompt_on_success: false,
    reprompt_on_failure: true,
    reprompt_while: lambda {false}}
  ])
})

# Create menu option here, for item selection
bank_menu.add_option("w", false, "Withdraw", [{rule: lambda { Player.bank_balance > 0 }, on_invalid: lambda { "You don't have any available funds to withdraw!"} }], lambda {
  Menu.handle_input_prompt("Enter funds to withdraw: ",
  [{conditions: [
    {rule: lambda {Menu.prompt_input =~ /\A\d+\z/ ? true : false}, on_fail: lambda {puts "Value entered must be a number."}},
    {rule: lambda {Menu.prompt_input.to_i >= 0}, on_fail: lambda {puts "Cannot withdraw less than zero funds."}},
    {rule: lambda {Menu.prompt_input.to_i <= Player.bank_balance}, on_fail: lambda {puts "Not enough funds."}}
    ],
    handler: lambda {Player.perform_bank_transaction(Menu.prompt_input.to_i)},
    reprompt_on_success: false,
    reprompt_on_failure: true,
    reprompt_while: lambda {false}}
  ])
})

bank_menu.add_option("\e", true, "exit", [{ rule: lambda {true}, on_invalid: lambda {} }], lambda {Menu.get_menu("Bank").exit_menu})
main_menu.add_option("b", false, "Bank", [{ rule: lambda {true}, on_invalid: lambda {} }], lambda {bank_menu.display})

hospital_menu = Menu.new("Hospital")
main_menu.add_option("h", false, "Hospital", [{rule: lambda {true}, on_invalid: lambda {} }], lambda {hospital_menu.display})
hospital_menu.add_option("\e", true, "exit", [{rule: lambda {true}, on_invalid: lambda {} }], lambda {Menu.get_menu("Hospital").exit_menu})

pill_price = 50
bandaid_price = 250
surgery_price = 1000

# HOSPITAL MENU
hospital_menu.set_content(lambda {
  option_length = 15
  price_length = 13
  puts "
Hospital
---------
Health: ".ljust(11)+Player.health.to_s.rjust(9)+"
Cash: ".ljust(11)+Player.cash.to_s.rjust(11)+"\n"+"
Option:".ljust(option_length)+"Price:".rjust(price_length)+"
(P)ills".ljust(option_length)+pill_price.to_s.rjust(price_length)+"
(B)andaids".ljust(option_length)+bandaid_price.to_s.rjust(price_length)+"
(S)urgery".ljust(option_length)+surgery_price.to_s.rjust(price_length)+"
(ESC) to return to previous menu\n\n"
})

# Create menu option here, for item selection
hospital_menu.add_option("p", false, "Pills", [{ rule: lambda { Player.cash > pill_price }, on_invalid: lambda { puts "You don't enough cash to pay for pills!"} }], lambda {
  Player.cash -= pill_price
  puts "You swallow a pill for $#{pill_price}"
  Player.heal(1)
})

hospital_menu.add_option("b", false, "Bandaid", [{ rule: lambda { Player.cash > bandaid_price }, on_invalid: lambda { puts "You don't enough cash to pay for bandaids!"} }], lambda {
  Player.cash -= bandaid_price
  puts "The doctor puts a bandaid on you for $#{bandaid_price}"
  Player.heal(10)
})

hospital_menu.add_option("s", false, "Surgery", [{rule: lambda { Player.cash > surgery_price }, on_invalid: lambda { puts "You don't enough cash to pay for surgery!"} }], lambda {
  Player.cash -= surgery_price
  puts "You get surgery for for $#{surgery_price}"
  Player.heal(100)
})

loan_shark_menu = Menu.new("Loan Shark")
main_menu.add_option("l", false, "Loan Shark", [{ rule: lambda {true}, on_invalid: lambda {} }], lambda {loan_shark_menu.display})
loan_shark_menu.add_option("\e", true, "exit", [{ rule: lambda {true}, on_invalid: lambda {} }], lambda {Menu.get_menu("Loan Shark").exit_menu})

loan_shark_menu.set_content(lambda {
  puts "
Loan Shark
----------
Cash: $#{Player.cash}
Debt: $#{Player.debt}\n
Options:
(R)epay Debt
(ESC) to return to previous menu\n\n"
})

loan_shark_menu.add_option("r", false, "Repay Loan", [{ rule: lambda {Player.cash > 0}, on_invalid: lambda { puts "No cash to repay loan!"} }], lambda {
  Menu.handle_input_prompt("Enter payment amount: ",
  [{conditions: [
    {rule: lambda {Menu.prompt_input =~ /\A\d+\z/ ? true : false}, on_fail: lambda {puts "Value entered must be a number."}},
    {rule: lambda {Menu.prompt_input.to_i >= 0}, on_fail: lambda {puts "Cannot repay less than zero funds."}},
    {rule: lambda {Menu.prompt_input.to_i <= Player.debt}, on_fail: lambda {puts "Not enough funds."}}
    ],
    handler: lambda {
      Player.debt -= Menu.prompt_input.to_i
      Player.cash -= Menu.prompt_input.to_i
    },
    reprompt_on_success: false,
    reprompt_on_failure: true,
    reprompt_while: lambda {false}}
  ])
})

travel_menu = Menu.new("Travel")
main_menu.add_option("t", false, "Travel", [{ rule: lambda {true}, on_invalid: lambda {} }], lambda {travel_menu.display})
travel_menu.add_option("\e", true, "exit", [{ rule: lambda {true}, on_invalid: lambda {} }], lambda {Menu.get_menu("Travel").exit_menu})

travel_menu.set_content(lambda {
  puts "
Travel
--------
You are currently in #{Player.location}.

Options:
(1) Santa Monica
(2) Long Beach
(3) Santa Ana
(4) Anaheim
(5) Riverside
(ESC) to return to previous menu\n\n"
})

def travel_fail_message
  return puts "You're already in #{Player.location}, choose a different destination."
end

travel_menu.add_option("1", true, "Santa Monica", [{ rule: lambda {Player.location != "Santa Monica"}, on_invalid: lambda { travel_fail_message } }], lambda {
  Player.travel_to("Santa Monica")
  Menu.get_menu("Travel").exit_menu
})
travel_menu.add_option("2", true, "Long Beach", [{ rule: lambda {Player.location != "Long Beach"}, on_invalid: lambda { travel_fail_message} }], lambda {
  Player.travel_to("Long Beach")
  Menu.get_menu("Travel").exit_menu
})
travel_menu.add_option("3", true, "Santa Ana", [{ rule: lambda {Player.location != "Santa Ana"}, on_invalid: lambda { travel_fail_message} }], lambda {
  Player.travel_to("Santa Ana")
  Menu.get_menu("Travel").exit_menu
})
travel_menu.add_option("4", true, "Anaheim", [{ rule: lambda {true}, on_invalid: lambda { travel_fail_message} }], lambda {
  Player.travel_to("Anaheim")
  Menu.get_menu("Travel").exit_menu
})
travel_menu.add_option("5", true, "Riverside", [{ rule: lambda {true}, on_invalid: lambda { travel_fail_message} }], lambda {
  Player.travel_to("Riverside")
  Menu.get_menu("Travel").exit_menu
})

found_loot_menu = Menu.new("Found Loot")
found_loot_menu.set_content(lambda {  
  puts "You find $#{Player.loot[:cash]} and #{Player.loot[:drug][:qty]} units of #{Player.loot[:drug][:name]} on the street.  You slip the cash in your pocket."
  if Player.get_available_inventory_capacity < Player.loot[:drug][:qty]
    puts "Your stash is too full to conceal the drugs, so you leave them behind."
    found_loot_menu.exit_menu
  else
    puts "Would you like to pickup the drugs? (y/n)"  
  end
})
found_loot_menu.add_option("y", false, "Pickup", [{ rule: lambda {true}, on_invalid: lambda {} }], lambda {
  puts "You quickly slip the drugs into your stash and hurry away from the scene."
  Player.perform_drug_transaction(Player.loot[:drug][:name], Player.loot[:drug][:qty], 0)
  Menu.get_menu("Found Loot").exit_menu
})
found_loot_menu.add_option("n", false, "Leave", [{ rule: lambda {true}, on_invalid: lambda {} }], lambda {
  puts "You leave those tempting drugs on the street for another lucky thug."
  Menu.get_menu("Found Loot").exit_menu
})

mugger_menu = Menu.new("Mugger")
mugger_menu.set_content(lambda {
  puts "You've encountered a mugger and they want to take your goods! What would you like to do? "
  puts "Your health: #{Player.health}"
  puts "Mugger's health: #{Player.enemy_health}"
  puts "Options: (F)ight, (R)un, or (S)urrender goods"
})
mugger_menu.add_option("f", false, "Fight", [{ rule: lambda {Player.has_gun}, on_invalid: lambda { puts "You have no gun to fight, choose another option."} }], lambda {
  Player.fight("Mugger")
})
mugger_menu.add_option("r", false, "Run", [{ rule: lambda {true}, on_invalid: lambda {} }], lambda {
  Player.run("Mugger")
})
mugger_menu.add_option("s", false, "Surrender", [{ rule: lambda {true}, on_invalid: lambda {} }], lambda {
  puts "You make a sacrifice with your goods to preserve your health."
  Player.inventory = {}
  Player.cash = 0
  Menu.get_menu("Mugger").exit_menu
})

cop_menu = Menu.new("Cop")
cop_menu.set_content(lambda {
  puts "You've encountered a cop, what will you do?!"
  puts "Your health: #{Player.health}"
  puts "Cop's health: #{Player.enemy_health}"
    
  #puts "Cop health: #{Player.enemy_health}"
  puts "Options: (F)ight or (R)un"
  
})

cop_menu.add_option("f", false, "Fight", [{ rule: lambda {Player.has_gun}, on_invalid: lambda {puts "You have no gun to fight, choose another option."} }], lambda {
  Player.fight("Cop")
})
cop_menu.add_option("r", false, "Run", [{ rule: lambda {true}, on_invalid: lambda {} }], lambda {
  Player.run("Cop")
})

def set_black_market_item
  items_to_buy = Hash.new
  storage_items = Storage.Storage_Items.keys
  storage_items.each do |item|
    items_to_buy[item] = Storage.Storage_Items[item][:purchase_price]
  end
  items_to_buy["gun"] = 3000
  item_names = items_to_buy.keys
  selected_item_name = item_names[Random.rand(1..item_names.length-1)] # don't select the 1st one
  Menu.get_menu("Black Market").set_selected_item({name: selected_item_name, price: items_to_buy[selected_item_name]})
end

black_market_menu = Menu.new("Black Market")
black_market_menu.set_content( lambda {
  selected_item = black_market_menu.selected_item_hash 
  print "You've encountered a black market agent and they have a #{selected_item[:name]} for sale"
  if selected_item[:name] == Player.storage_item || (selected_item[:name] == "gun" && Player.has_gun)
    print ", but you already have one.\n"
    Menu.get_menu("Black Market").exit_menu
  else
    # check funds
    if Player.cash >= selected_item[:price]
      print ".\nWould you like to purchase this item? (y/n):\n"
    else
      print ", but you cannot afford it.\n"
      Menu.get_menu("Black Market").exit_menu
    end
  end
})
black_market_menu.add_option("y", false, "Buy", [{ rule: lambda {true}, on_invalid: lambda {} }], lambda {
  item_name = black_market_menu.selected_item_hash[:name]
  if item_name == "gun"
    Player.cash -= black_market_menu.selected_item_hash[:price]
    Player.has_gun = true
  elsif item_name == "trenchcoat"
    Player.cash -= black_market_menu.selected_item_hash[:price]
    Player.storage_item = item_name
  elsif item_name == "backpack"
    Player.cash -= black_market_menu.selected_item_hash[:price]
    Player.storage_item = item_name
  else
      puts "Sorry, there is no support for purchasing #{item_name} yet."
  end
  Menu.get_menu("Black Market").exit_menu
})
black_market_menu.add_option("n", false, "Do not buy", [{ rule: lambda {true}, on_invalid: lambda {} }], lambda {
  puts "You decide not to make the purchase."
  Menu.get_menu("Black Market").exit_menu
})

# Create new game object and pass in root menu
game = Game.new(main_menu)
    
# Start the game by showing the main menu
main_menu.display
