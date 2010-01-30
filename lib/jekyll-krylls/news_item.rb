module Jekyll

  class NewsItem
    include Comparable
    include Convertible

    class << self
      attr_accessor :lsi
    end

    MATCHER = /^(.+\/)*(\d+-\d+-\d+)-(.*)(\.[^.]+)$/

    # News name validator. News filenames must be like:
    #   2008-11-05-my-awesome-news.textile
    #
    # Returns <Bool>
    def self.valid?(name)
      name =~ MATCHER
    end

    attr_accessor :site
    attr_accessor :data, :content, :output, :ext
    attr_accessor :date, :slug, :published, :tags, :categories

    # Initialize this Post instance.
    #   +site+ is the Site
    #   +base+ is the String path to the dir containing the news item file
    #   +name+ is the String filename of the news item file
    #   +categories+ is an Array of Strings for the categories for this new item
    #
    # Returns <News>
    def initialize(site, source, dir, name)
      @site = site
      @base = File.join(source, dir, '_news')
      @name = name

      self.categories = dir.split('/').reject { |x| x.empty? }
      self.process(name)
      self.read_yaml(@base, name)

      #If we've added a date and time to the yaml, use that instead of the filename date
      #Means we'll sort correctly.
      if self.data.has_key?('date')
        # ensure Time via to_s and reparse
        self.date = Time.parse(self.data["date"].to_s)
      end

      if self.data.has_key?('published') && self.data['published'] == false
        self.published = false
      else
        self.published = true
      end

      self.tags = self.data.pluralized_array("tag", "tags")

      if self.categories.empty?
        self.categories = self.data.pluralized_array('category', 'categories')
      end
    end

    # Spaceship is based on Post#date, slug
    #
    # Returns -1, 0, 1
    def <=>(other)
      cmp = self.date <=> other.date
      if 0 == cmp
       cmp = self.slug <=> other.slug
      end
      return cmp
    end

    # Extract information from the news item filename
    #   +name+ is the String filename of the news item file
    #
    # Returns nothing
    def process(name)
      m, cats, date, slug, ext = *name.match(MATCHER)
      self.date = Time.parse(date)
      self.slug = slug
      self.ext = ext
    end

    # The generated directory into which the news item will be placed
    # upon generation. This is derived from the permalink or, if
    # permalink is absent, set to the default date
    # e.g. "/2008/11/05/" if the permalink style is :date, otherwise nothing
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
        "/news/:categories/:year/:month/:day/:title/"
      when :none
        "/news/:categories/:title.html"
      when :date
        "/news/:categories/:year/:month/:day/:title.html"
      else
        self.site.permalink_style.to_s
      end
    end

    # The generated relative url of this news item
    # e.g. /2008/11/05/my-awesome-news.html
    #
    # Returns <String>
    def url
      return permalink if permalink

      @url ||= {
        "year"       => date.strftime("%Y"),
        "month"      => date.strftime("%m"),
        "day"        => date.strftime("%d"),
        "title"      => CGI.escape(slug),
        "categories" => categories.join('/')
      }.inject(template) { |result, token|
        result.gsub(/:#{token.first}/, token.last)
      }.gsub(/\/\//, "/")
    end

    # The UID for this news item (useful in feeds)
    # e.g. /2008/11/05/my-awesome-news
    #
    # Returns <String>
    def id
      File.join(self.dir, self.slug)
    end

    # Calculate related news.
    #
    # Returns [<NewsItem>]
    def related_news(news)
      return [] unless news.size > 1

      if self.site.lsi
        self.class.lsi ||= begin
          puts "Running the classifier... this could take a while."
          lsi = Classifier::LSI.new
          news.each { |x| $stdout.print(".");$stdout.flush;lsi.add_item(x) }
          puts ""
          lsi
        end

        related = self.class.lsi.find_related(self.content, 11)
        related - [self]
      else
        (news - [self])[0..9]
      end
    end

    # Add any necessary layouts to this news item
    #   +layouts+ is a Hash of {"name" => "layout"}
    #   +site_payload+ is the site payload hash
    #
    # Returns nothing
    def render(layouts, site_payload)
      # construct payload
      payload =
      {
        "site" => { "related_news" => related_news(site_payload["site"]["news"]) },
        "page" => self.to_liquid
      }
      payload = payload.deep_merge(site_payload)

      do_layout(payload, layouts)
    end

    # Write the generated news item file to the destination directory.
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

    # Convert this news item into a Hash for use in Liquid templates.
    #
    # Returns <Hash>
    def to_liquid
      { "title"      => self.data["title"] || self.slug.split('-').select {|w| w.capitalize! || w }.join(' '),
        "url"        => self.url,
        "date"       => self.date,
        "id"         => self.id,
        "categories" => self.categories,
        "next"       => self.next,
        "previous"   => self.previous,
        "tags"       => self.tags,
        "content"    => self.content }.deep_merge(self.data)
    end

    def inspect
      "<NewsItem: #{self.id}>"
    end

    def next
      pos = self.site.news.index(self)

      if pos && pos < self.site.news.length-1
        self.site.news[pos+1]
      else
        nil
      end
    end

    def previous
      pos = self.site.news.index(self)
      if pos && pos > 0
        self.site.news[pos-1]
      else
        nil
      end
    end
  end

end