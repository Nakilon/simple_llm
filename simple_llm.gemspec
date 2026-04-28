Gem::Specification.new do |spec|
  spec.name         = "simple_llm"
  spec.version      = "0.0.0"
  spec.summary      = "common wrapper for all LLM providers"

  spec.author       = "Victor Maslov aka Nakilon"
  spec.email        = "nakilon@gmail.com"
  spec.license      = "MIT"
  spec.metadata     = {"source_code_uri" => "https://github.com/nakilon/simple_llm"}

  spec.add_dependency "nethttputils"
  spec.add_dependency "skjvs"

  spec.files        = %w{ LICENSE simple_llm.gemspec lib/simple_llm.rb }
end
