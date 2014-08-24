class MFPScraper
  module Authentication
    extend ActiveSupport::Concern

    included do
      register_path :login, '/'

      attr_accessor :authenticated
      alias :authenticated? :authenticated
    end

    def authenticate!
      agent.get(url_for(:login)) do |page|
        login_result = page.form_with(action: /\/account\/login$/) do |login|
          login.username = @username
          login.password = @password
        end.submit

        if login_result.search("p.flash").text[/Incorrect username or password/]
          @authenticated = false
        else
          @authenticated = true
        end
      end

      return @authenticated
    end

    def fetch_username
      authenticate! unless authenticated?

      agent.get(url_for(:login)) do |page|
        return page.search('ul#navTop li.first a')[0].text.strip
      end
    end
  end
end
