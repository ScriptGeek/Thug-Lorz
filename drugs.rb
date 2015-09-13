class Drugs
  
  @@price_index
  @@price_list
  
  
  def initialize
    @@price_index = Hash.new
    @@price_index["Acid"] = Range.new(1000,4500)
    @@price_index["Cocaine"] = Range.new(15000,30000)
    @@price_index["Hashish"] = Range.new(450,1500)
    @@price_index["Heroin"] = Range.new(5000,14000)
    @@price_index["Ecstacy"] = Range.new(10,60)
    @@price_index["Smack"] = Range.new(1500,4500)
    @@price_index["Opiom"] = Range.new(500,1300)
    @@price_index["Crack"] = Range.new(1000,3500)
    @@price_index["Peyote"] = Range.new(100,700)
    @@price_index["Shrooms"] = Range.new(600,1400)
    @@price_index["Speed"] = Range.new(70,250)
    @@price_index["Weed"] = Range.new(300,900)
    
    # initialize the price list
    self.class.set_new_price_list
  end
  
  # Call only once each time player travels
  def self.set_new_price_list
    @@price_list = Hash.new
    @@price_index.each do |key, value|
      @@price_list[key] = Random.rand(value)
    end
  end
  
  def self.get_price_list
    @@price_list
  end
  
  # Adds a drug with name and priceRange to the aggregate list of available drugs
  def self.add_drug(name, price_range)
    price_index[name] = price_range
  end
  
  # Returns a hash of drugs with names and associated prices from the aggregate list of available drugs
  # need to support number of units of each item
  # need to support onkey item selection
  def self.get_drug_name_to_price_range_hash
    drug_menu = []
    price_index.each do |drug, range|
      drug_menu.push( {drug: drug, price: rand(range)} )
    end
    drug_menu
  end
  
  # Assigns a selection key to each drug name for keyboard menu selection
  def self.get_drug_name_to_selector_key_hash
    selector_key_hash = {}
    selector_key = 65
    @@price_index.keys.each do |key|
      selector_key_hash[key] = selector_key.chr
      selector_key += 1
    end
    selector_key_hash
  end
    
  def self.get_random_drug_name
    drug_names = @@price_index.keys
    drug_names[Random.rand(0..drug_names.length - 1)]
  end
  
end
