module Redmine
  module Info
    class << self
      def app_name; 'eScience' end
      def url; 'http://eScience.htwk-leipzig.de/' end
      def help_url; 'http://www.redmine.org/guide' end
      def versioned_name; "#{app_name} #{Redmine::VERSION}" end
    end
  end
end
