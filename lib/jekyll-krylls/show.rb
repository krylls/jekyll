module Jekyll
  class Show
    include Comparable
    include Convertible
    
    MATCHER = /^(.+\/)*(\d+-\d+-\d+)-(.*)(\.[^.]+)$/

    # show name validator. Show filenames must be like:
    #   2008-11-05-don-pedro
    #
    # Returns <Bool>
    def self.valid?(name)
      name =~ MATCHER
    end

    attr_accessor :site
    attr_accessor :data, :content, :output, :ext
    attr_accessor :date, :slug, :published
    attr_accessor :venue

    def initialize(site, source, dir, name)
      @site = site
      @base = File.join(source, dir, '_shows')
      @name = name

      self.process(name)
      self.read_yaml(@base, name)

      #If we've added a date and time to the yaml, use that instead of the filename date
      #Means we'll sort correctly.
      if self.data.has_key?('date')
        # ensure Time via to_s and reparse
        self.date = Time.parse(self.data["date"].to_s)
      end

      if self.data.has_key?('venue')
        self.venue = self.site.venue(self.data["venue"].to_s)
      end
            
      if self.data.has_key?('published') && self.data['published'] == false
        self.published = false
      else
        self.published = true
      end
    end
    
    # Returns -1, 0, 1
    def <=>(other)
      cmp = self.date <=> other.date
      return cmp
    end
    
    # Extract information from the show filename
    #   +name+ is the String filename of the show file
    #
    # Returns nothing
    def process(name)
      m, cats, date, slug, ext = *name.match(MATCHER)
      self.date = Time.parse(date)
      self.slug = slug
      self.ext = ext
    end
    
    # The generated directory into which the show will be placed
    # upon generation. This is derived from the permalink or, if
    # permalink is absent, set to the default date
    # e.g. "/shows/2008/11/05/" if the permalink style is :date, otherwise nothing
    #
    # Returns <String>
    def dir
      File.dirname(url)
    end

    # The full path and filename of the news item.
    # Defined in the YAML of the news item body
    # (Optional)
    #
    # Returns <String>
    def permalink
      self.data && self.data['permalink']
    end
    
    def template
      case self.site.permalink_style
      when :pretty
        "/shows/:year/:month/:day/:title/"
      when :none
        "/shows/:title.html"
      when :date
        "/shows/:year/:month/:day/:title.html"
      else
        self.site.permalink_style.to_s
      end
    end

    # The generated relative url of this show
    # e.g. /shows/2008/11/05/my-awesome-news.html
    #
    # Returns <String>
    def url
      return permalink if permalink

      @url ||= {
        "year"       => date.strftime("%Y"),
        "month"      => date.strftime("%m"),
        "day"        => date.strftime("%d"),
        "title"      => CGI.escape(slug),
      }.inject(template) { |result, token|
        result.gsub(/:#{token.first}/, token.last)
      }.gsub(/\/\//, "/")
    end
    
    # The UID for this show (useful in feeds)
    # e.g. /shows/2008/11/05/my-awesome-news
    #
    # Returns <String>
    def id
      File.join(self.dir, self.slug)
    end
    
    # Add any necessary layouts to this show
    #   +layouts+ is a Hash of {"name" => "layout"}
    #   +site_payload+ is the site payload hash
    #
    # Returns nothing
    def render(layouts, site_payload)
      # construct payload
      payload =
      {
        "site" => {},
        "page" => self.to_liquid
      }
      payload = payload.deep_merge(site_payload)

      do_layout(payload, layouts)
    end
    
    # Write the generated show file to the destination directory.
    #   +dest+ is the String path to the destination dir
    #
    # Returns nothing
    def write(dest)
      FileUtils.mkdir_p(File.join(dest, dir))

      # The url needs to be unescaped in order to preserve the correct filename
      path = File.join(dest, CGI.unescape(self.url))

      if template[/\.html$/].nil?
        FileUtils.mkdir_p(path)
        path = File.join(path, "index.html")
      end

      File.open(path, 'w') do |f|
        f.write(self.output)
      end
    end
    
    # Convert this show into a Hash for use in Liquid templates.
    #
    # Returns <Hash>
    def to_liquid
      self.data.deep_merge(
      { "title"    => self.data["title"] || self.slug.split('-').select {|w| w.capitalize! || w }.join(' '),
      "url"        => self.url,
      "date"       => self.date,
      "venue"      => self.venue,
      "id"         => self.id,
      "next"       => self.next,
      "previous"   => self.previous,
      "content"    => self.content })
    end

    def inspect
      "<Show: #{self.id}>"
    end

    def next
      pos = self.site.shows.index(self)

      if pos && pos < self.site.shows.length-1
        self.site.shows[pos+1]
      else
        nil
      end
    end
    
    def previous
      pos = self.site.shows.index(self)
      if pos && pos > 0
        self.site.shows[pos-1]
      else
        nil
      end
    end
  end
end