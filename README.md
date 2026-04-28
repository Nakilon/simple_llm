```ruby
require "simple_llm"
project_id, key_id, key = File.read("secret").split
llm = SimpleLLM::Yandex::Sync.new
pp llm.call project_id, key, "привет", instructions: "отвечай на китайском"

# => "你好！"
```
