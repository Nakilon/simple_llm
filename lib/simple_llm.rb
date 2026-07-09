require_relative "refinement_array"
using ::RefinementArray

module SimpleLLM
  require "nethttputils"

  Error = ::Class.new ::RuntimeError

  module Common

    require "skjvs"
    # @param cache_filename [String, nil, false] если передать `nil` или `false`, кеширования не будет
    def initialize cache_filename = "simple_llm_cache.jsonl", &cache_key_string_function
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
      @cache = ::SKJVS::OneFile.new cache_filename if cache_filename
    end

  end

  module Yandex

    class Sync
      require "json"
      require "digest"
      include Common
      # TODO: ассертить размер input-а при image_input как-то иначе
      # https://aistudio.yandex.ru/docs/ru/ai-studio/api/Responses/createResponse.html
      # @param project
      # @param api_key
      # @param input [Object] https://aistudio.yandex.ru/docs/ru/ai-studio/api/Responses/createResponse.html#entity-InputParam
      # @param max_output_tokens [Integer] "An upper bound for the number of tokens that can be generated for a response, including visible output tokens and reasoning tokens."
      # @param temperature [Integer] "What sampling temperature to use, between 0 and 2. Higher values like 0.8 will make the output more random, while lower values like 0.2 will make it more focused and deterministic."
      # @param model [String]
      # @param instructions
      # @param max_input_chars [Integer] предохранительный ассерт, чтобы метод не вызвали со слишком тяжелым большим input-ом
      # @param debug [true, false] печатать запросы и ответы
      # @return [String] текст из `["output"]["content"][0]["text"]`
      def call project, api_key, input, max_output_tokens = 500, temperature = 0, model: "yandexgpt/rc", instructions: nil, max_input_chars: 1000, debug: false
        raise ::ArgumentError, "max_input_chars assertion: #{input.to_s.size}" if input.to_s.size > max_input_chars
        request = lambda do
          ::NetHTTPUtils.request_data(
            "https://ai.api.cloud.yandex.net/v1/responses", :post, :json, header: {
              "OpenAI-Project" => project,
              "Authorization" => "Api-Key #{api_key}",
              "x-data-logging-enabled" => "false",  # https://aistudio.yandex.ru/docs/ru/ai-studio/operations/disable-logging.html
            }, form: {
              model: "gpt://#{project}/#{model}",
              instructions: instructions,
              input: input,
              temperature: temperature,
              max_output_tokens: max_output_tokens,
              # reasoning: {effort: "low"},
            }.compact.tap{ |_| ::STDERR.puts ::JSON.pretty_generate _ if debug }
          ).force_encoding("utf-8")
        end
        ::JSON.parse(
          if @cache
            @cache[ @cache_key_string_function.(
          self.class,
          ::Time.now,
          ::Digest::MD5.hexdigest(api_key),
          ::Process::pid,
          model,
          input,
          max_output_tokens,
          temperature,
          instructions,
            ) ] ||= request.call
          else
            request.call
          end
        ).tap{ |_| ::STDERR.puts ::JSON.pretty_generate _ if debug }["output"].select{ |_| "message" == _["type"] }.map do |message|
          message["content"].assert_one.fetch("text").strip
        end.assert_one_or_less or raise Error, "empty message assertion"
      end
    end

    # class Async

  end

end
