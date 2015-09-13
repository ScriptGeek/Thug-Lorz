class Storage
  
  # instantiate a storage item
  def initialize(item_name, storage_capacity, purchase_price)
    if Storage.Storage_Items == nil
      Storage.Storage_Items = Hash.new
    end
    
    Storage.Storage_Items[item_name] = {capacity: storage_capacity, purchase_price: purchase_price}
  end
  
  # create getter/setter for class variable
  class << self
    attr_accessor :Storage_Items
  end
  
  # quick access to the capacity of each storage item by name
  def self.get_capacity(item_name)
    Storage.Storage_Items[item_name][:capacity]
  end
  
end

# Initialize all storage items
Storage.new("pockets",20, 0)
Storage.new("trenchcoat",50, 2000)
Storage.new("backpack",100, 5000)
