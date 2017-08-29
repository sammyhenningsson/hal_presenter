# -*- encoding: utf-8 -*-
Gem::Specification.new do |gem|
  gem.name        = 'hal_decorator'
  gem.version     = '0.3.0'
  gem.date        = '2017-08-29'
  gem.summary     = "HAL serializer"
  gem.description = <<~EOS
                    Serialize resources according to
                    HypertextApplicationLanguage.
                    EOS
  gem.authors     = ["Sammy Henningsson"]
  gem.email       = 'sammy.henningsson@gmail.com'
  gem.homepage    = "https://github.com/sammyhenningsson/hal_decorator"
  gem.license     = "MIT"

  gem.cert_chain  = ['certs/sammyhenningsson.pem']
  gem.signing_key = File.expand_path("~/.ssh/gem-private_key.pem") if $0 =~ /gem\z/

  gem.files         = `git ls-files lib`.split
  gem.require_paths = ["lib"]

  gem.add_development_dependency "rake", '~> 12.0', '>= 10.0'
  gem.add_development_dependency "activesupport", '~> 5.1', '>= 4.0'
  gem.add_development_dependency "minitest", '~> 5.10', '>= 5.0'
  gem.add_development_dependency "byebug", '~> 9.0', '>= 9.0'
end
