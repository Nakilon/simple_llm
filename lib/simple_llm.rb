require "nethttputils"

require_relative "common_refinements"
using Common::RefinementArray

module SimpleLLM

  module Common
    Error = ::Class.new ::ArgumentError

    require "skjvs"
    def initialize cache_filename = "simple_llm_cache", &cache_key_string_function
      @cache_key_string_function = cache_key_string_function || lambda do |
        cls,
        time,
        auth,
        pid,
        model,
        input,
        max_output_tokens,
        temperature,
        instructions,
      |
        "#{instructions} #{input}"
      end
      @cache = ::SKJVS::OneFile.new cache_filename
    end

  end

  module Yandex

    class Sync
      require "json"
      require "digest"
      include Common
      def call project, api_key, input, model = "yandexgpt/rc", max_output_tokens = 500, temperature = 0, instructions: nil, max_input_chars: 1000
        raise Error if input.size > max_input_chars
        key = @cache_key_string_function.(
          self.class,
          ::Time.now,
          ::Digest::MD5.hexdigest(api_key),
          ::Process::pid,
          model,
          input,
          max_output_tokens,
          temperature,
          instructions,
        )
        ::JSON.parse(
          @cache[key] || (@cache[key] = ::NetHTTPUtils.request_data(
            "https://ai.api.cloud.yandex.net/v1/responses", :post, :json, header: {
              "OpenAI-Project" => project,
              "Authorization" => "Api-Key #{api_key}",
            }, form: {
              model: "gpt://#{project}/#{model}",
              instructions: instructions,
              input: input,
              temperature: temperature,
              max_output_tokens: max_output_tokens,
            }.compact
          ).force_encoding("utf-8") )
        )["output"].assert_one["content"].assert_one.fetch "text"
      end
    end

    # class Async

  end

end
