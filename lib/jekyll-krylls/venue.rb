module Jekyll
  class Venue
    include Convertible
    
    attr_accessor :site
    attr_accessor :data, :content, :output
    attr_accessor :name

    def initialize(site, source, dir, name)
      @site = site
      @base = File.join(source, dir, '_venues')
      @fname = name

      self.read_yaml(@base, name)          
      
      if self.data.has_key?('name')
        self.name = self.data["name"].to_s
      end
    end
    
    def id
      File.join(self.dir, self.fname)
    end
    
    def inspect
      "<Show: #{self.id}>"
    end
    
    # Convert this venue into a Hash for use in Liquid templates.
    #
    # Returns <Hash>
    def to_liquid
      self.data.deep_merge(
      { "content" => self.content })
    end
  end
end