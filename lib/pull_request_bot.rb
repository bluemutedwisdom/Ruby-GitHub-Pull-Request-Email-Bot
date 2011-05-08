require 'trollop'
require 'yaml'
require 'httparty'

class PullRequestBot
  attr_accessor :opts, :config

  def initialize
    self.opts = Trollop::options do
      opt :config, "Specify config file to use", :type => :string, :default => './config.yaml'
    end

    read_config
    validate_config
  end

  def run
  end

  def repositories
    unless @repositories
      @repositories = self.config.reject {|k,v| k == "default"}

      @repositories.keys.each do |repository|
        @repositories[repository] = self.config['default'].merge(self.config[repository])
      end
    end

    @repositories
  end

  private

  def read_config
    self.config = YAML.load(File.read(self.opts[:config]))
  end

  def validate_config
    raise ArgumentError.new("In '#{self.opts[:config]}' there must be a 'default' section.") unless
      self.config && self.config.is_a?(Hash) && self.config['default']

    # Enumerate all of the 'globally required' default settings,
    # making sure that each one is there.
    %w{
     template_dir
     state_dir
     to_email_address
     from_email_address
     reply_to_email_address
     html_email
     group_pull_request_updates
     alert_on_close
     opened_subject
    }.each do |key|
      raise ArgumentError.new("In '#{self.opts[:config]}' the 'default' section must contain '#{key}'") unless
        self.config['default'].has_key?(key)
    end

    raise ArgumentError.new("In '#{self.opts[:config]}' the 'default' section must contain 'closed_subject' when 'alert_on_close' is true.") if
      self.config['default']['alert_on_close'] and not self.config['default'].has_key?('closed_subject')

    raise ArgumentError.new("There must be at least one repository configured (user-name/repository-name)") unless
      self.config.keys.count > 1

    self.config.keys.each do |section|
      next if section == "default"

      raise ArgumentError.new("Repositories must be of the form 'user-name/repository-name': #{section}") unless
        section.match /[a-z0-9_-]+\/[a-z0-9_-]+/i
    end
  end
end