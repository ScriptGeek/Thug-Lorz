require './storage.rb'

class Player
  
  # Class variable accessors
  class << self
    attr_accessor :cash, :debt, :bank_balance, :health, :storage_item, :inventory, :has_gun, :location, :loot, :enemy_health
  end
  
  # inventory is a hash of drug_name and qty
  def initialize(cash, debt, bank_balance, health, storage_item, inventory, has_gun)
    Player.cash = cash
    Player.debt = debt
    Player.bank_balance = bank_balance
    Player.health = 100
    Player.storage_item = storage_item
    Player.inventory = inventory
    Player.has_gun = has_gun
  end
  
  # calculates current score and returns result
  public
  def Player.get_score
    return Player.cash - Player.debt + Player.bank_balance
  end
  
  # calculates inventory utilization and returns the result
  public
  def Player.get_inventory_utilization
    count = 0
    Player.inventory.each do |key, value|
      count += value
    end
    return count
  end
  
  # calculates available inventory space and returns the result
  public
  def Player.get_available_inventory_capacity
    return Storage.get_capacity(Player.storage_item) - get_inventory_utilization
  end
  
  # processes the effects of traveling to new location
  public
  def Player.travel_to(new_location)
    Drugs.set_new_price_list
    Player.location = new_location
    if Game.day > 0
      Player.debt *= 1.1
      Player.debt = Player.debt.to_i
      Player.bank_balance *= 1.03
      Player.bank_balance = Player.bank_balance.to_i
      Game.choose_random_event
    end
    Game.set_next_day
  end

  # creates random loot for loot found event when traveling
  public
  def Player.generate_loot
    Player.loot = {cash: Random.rand(1..500), drug: {name: Drugs.get_random_drug_name, qty: Random.rand(1..5)}}
    return Player.loot
  end
  
  # processes one round of fighting for encounter event when traveling
  public
  def Player.fight (enemy_name)
    if Random.rand(0..100) > 50
      puts "You shoot the #{enemy_name}!"
      enemy_health -= Random.rand(1..40)
    else
      puts "You shoot, but you miss!"
    end
    if Random.rand(0..100) > 65
      puts "The #{enemy_name} shoots you!"
      health -= Random.rand(1..20)
    else
      puts "The #{enemy_name} shoots at you, but misses!"
    end
    if Player.enemy_health <= 0
      puts "The #{enemy_name} is incapacitated, you run away before someone else appears."
      Menu.get_menu(enemy_name).exit_menu
    end
    if Player.health <= 0
      Game.Instance.game_over("You are incapacitated.")
      Menu.get_menu(enemy_name).exit_menu
    end
  end
  
  # handles one attempt at escaping an encounter when traveling
  def Player.run(enemy_name)
    if Random.rand(0..100) > 65
      puts "You escaped!"
      Menu.get_menu(enemy_name).exit_menu
    else
      damage = Random.rand(0..3)
      Player.health -= damage
      puts "You tried to escape, but you tripped and take #{damage} points of damage."
      puts "Your health: #{Player.health}"
      if Player.health <= 0
        Game.Instance.game_over("You are incapacitated.")
        Menu.get_menu(enemy_name).exit_menu
      end
    end
  end

  public
  def Player.set_enemy_health
    Player.enemy_health = 100
  end
  
  def Player.perform_drug_transaction(drug_name, quantity, price)
    Player.cash -= quantity * price
    if Player.inventory.has_key?(drug_name)
      Player.inventory[drug_name] += quantity
    else
      Player.inventory[drug_name] = quantity
    end
    if Player.inventory[drug_name] == 0
      Player.inventory.delete(drug_name)
    end
  end
  
  
  # heals the player for the specified number of points
  public
  def Player.heal(points)
    old_health = health
    Player.health += points
    puts "You are healed for #{health > 100 ? 100-old_health : points} health points"
    if health > 100
      Player.health = 100
    end
    
  end
  
  def Player.perform_bank_transaction(funds)
      Player.cash += funds
      Player.bank_balance -= funds
  end
  
  def Player.display_inventory
    qty_width = 3
    drug_name_width = 8
    
    # Display header
    header_string = "Qty".rjust(qty_width)+"Drug".rjust(drug_name_width)
    puts header_string
    inventory.each do |key, value|
      value_string = value.to_s.rjust(qty_width)+key.rjust(drug_name_width)+"\n"
      puts value_string
    end
  end
  
end
