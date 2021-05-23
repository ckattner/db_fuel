# frozen_string_literal: true

require './lib/db_fuel/version'

Gem::Specification.new do |s|
  s.name        = 'db_fuel'
  s.version     = DbFuel::VERSION
  s.summary     = 'Dbee and ActiveRecord jobs for Burner'

  s.description = <<-DESCRIPTION
    This library adds database-centric jobs to the Burner library.  Burner does not ship with database jobs out of the box.
  DESCRIPTION

  s.authors     = ['Matthew Ruggio', 'John Bosko']
  s.email       = ['mruggio@bluemarblepayroll.com', 'jbosko@bluemarblepayroll.com']
  s.files       = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  s.bindir      = 'exe'
  s.executables = %w[]
  s.homepage    = 'https://github.com/bluemarblepayroll/db_fuel'
  s.license     = 'MIT'
  s.metadata    = {
    'bug_tracker_uri' => 'https://github.com/bluemarblepayroll/db_fuel/issues',
    'changelog_uri' => 'https://github.com/bluemarblepayroll/db_fuel/blob/master/CHANGELOG.md',
    'documentation_uri' => 'https://www.rubydoc.info/gems/db_fuel',
    'homepage_uri' => s.homepage,
    'source_code_uri' => s.homepage
  }

  s.required_ruby_version = '>= 2.5'

  ar_version = ENV['AR_VERSION'] || ''

  activerecord_version =
    case ar_version
    when '6'
      ['>=6.0.0', '<7']
    when '5'
      ['>=5.2.1', '<6']
    else
      ['>=5.2.1', '<7']
    end

  s.add_dependency('activerecord', activerecord_version)
  s.add_dependency('acts_as_hashable', '~>1.2')
  s.add_dependency('burner', '~>1.7')
  s.add_dependency('dbee', '~>3.0')
  s.add_dependency('dbee-active_record', '~>2.2')
  s.add_dependency('objectable', '~>1.0')

  s.add_development_dependency('guard-rspec', '~>4.7')
  s.add_development_dependency('pry', '~>0')
  s.add_development_dependency('rake', '~> 13')
  s.add_development_dependency('rspec', '~> 3.8')
  s.add_development_dependency('rubocop', '~>1.7.0')
  s.add_development_dependency('simplecov', '~>0.18.5')
  s.add_development_dependency('simplecov-console', '~>0.7.0')
  s.add_development_dependency('sqlite3', '~>1')
end
