$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "postlock/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "postlock"
  s.version     = Postlock::VERSION
  s.authors     = ["Postlock.com"]
  s.email       = ["contact@postlock.com"]
  s.homepage    = "http://www.postlock.com"
  s.summary     = "Deliver important documents to your employees and clients"
  s.description = "Learn more at http://www.postlock.com"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "oauth2", "~> 0.9.2"

  s.add_development_dependency "sqlite3"
end
