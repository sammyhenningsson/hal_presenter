# -*- encoding: utf-8 -*-
Gem::Specification.new do |gem|
  gem.name        = 'hal_decorator'
  gem.version     = '0.2.0'
  gem.date        = '2017-07-27'
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

  gem.add_development_dependency "rake"
  gem.add_development_dependency "activesupport"
  gem.add_development_dependency "minitest"
  gem.add_development_dependency "byebug"
end
