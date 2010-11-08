module Indexing
  
  class Type
    
    attr_reader :name, :source, :categories, :after_indexing
    
    # Delegators for indexing.
    #
    delegate :connect_backend,
             :to => :source
             
    delegate :index,
             :cache,
             :generate_caches,
             :backup_caches,
             :restore_caches,
             :check_caches,
             :clear_caches,
             :create_directory_structure,
             :to => :categories
    
    def initialize name, source, options = {}
      @name   = name
      @source = source
      
      @after_indexing = options[:after_indexing]
      
      @categories = Categories.new
    end
    
    # TODO Spec. Doc.
    #
    def add_category name, options = {}
      categories << Category.new(name, self, options)
    end
    
    # Indexing.
    #
    def take_snapshot
      source.take_snapshot self
    end
    
  end
  
end