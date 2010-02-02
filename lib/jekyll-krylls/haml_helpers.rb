require 'cgi'
 
module Jekyll
  module HamlHelpers
    
    def h(text)
      CGI.escapeHTML(text)
    end
    
    def link_to(text, url)
      %{<a href="#{h url}">#{text}</a>}
    end
    
  end
end
