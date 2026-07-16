require "net/http"
require "json"

class OllamaService
  MODELS = [ "gemma3:1b", "gemma3:4b", "llama3.2", "qwen2.5:3b" ].freeze

  def self.chat(messages)
    uri = URI("http://localhost:11434/api/chat")

    MODELS.each do |model_name|
      body = {
        model: model_name,
        messages: messages,
        stream: false
      }

      begin
        res = Net::HTTP.post(uri, body.to_json, "Content-Type" => "application/json")
        parsed = JSON.parse(res.body)
        response = parsed.dig("message", "content")
        return response if response.present?
      rescue StandardError => e
        Rails.logger.warn("OllamaService fallback for #{model_name}: #{e.message}")
      end
    end

    "Desculpe, não consegui responder no momento."
  end
end

# Para iniciar o server do Ollama rode o comando:
# ollama serve
