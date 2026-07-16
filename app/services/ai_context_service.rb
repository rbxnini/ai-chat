require "yaml"
require "fileutils"

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

class AiContextService
  DEFAULT_MEMORY_FILE = Rails.root.join("config", "ai_memory.yml").to_s
  DEFAULT_PERSONALIZATION_FILE = Rails.root.join("config", "ai_personalization.yml").to_s

  def initialize(memory_file_path: DEFAULT_MEMORY_FILE, personalization_file_path: DEFAULT_PERSONALIZATION_FILE)
    @memory_file_path = memory_file_path
    @personalization_file_path = personalization_file_path
  end

  def memory_facts
    load_yaml(@memory_file_path, default: [])
  end

  def personalizations
    load_yaml(@personalization_file_path, default: [])
  end

  def save_memory_fact(fact)
    return if fact.to_s.strip.empty?

    facts = memory_facts
    facts << fact.strip unless facts.include?(fact.strip)
    write_yaml(@memory_file_path, facts)
  end

  def save_personalization(personalization)
    return if personalization.to_s.strip.empty?

    personalizations_list = personalizations
    personalizations_list << personalization.strip unless personalizations_list.include?(personalization.strip)
    write_yaml(@personalization_file_path, personalizations_list)
  end

  def build_context_prompt(user_message)
    facts = memory_facts
    prefs = personalizations

    sections = []
    sections << utf8_string("Você é um assistente pessoal e deve usar o contexto abaixo antes de responder.")
    sections << utf8_string("Regras:")
    sections << utf8_string("- Considere sempre as informações de memória do usuário antes de responder.")
    sections << utf8_string("- Se houver preferências ou fatos importantes salvos, use-os para personalizar a resposta.")
    sections << utf8_string("- Se o usuário mencionar algo relevante como saúde, rotina, preferências ou expectativas, registre isso como memória.")
    sections << utf8_string("- Nunca diga que você não tem memória ou que não sabe sobre o usuário se houver contexto salvo.")
    sections << utf8_string("- Sempre responda como se você conhecesse o usuário e estivesse usando esse contexto.")
    sections << utf8_string("- Quando houver contexto salvo, faça referência a ele de forma natural na resposta.")

    sections << utf8_string("Contexto do usuário:") if facts.any?
    facts.each { |fact| sections << utf8_string("- #{fact}") }

    sections << utf8_string("Personalizações da IA:") if prefs.any?
    prefs.each { |item| sections << utf8_string("- #{item}") }

    sections << utf8_string("Última mensagem do usuário: #{user_message}") if user_message.present?

    utf8_string(sections.join("\n"))
  end

  private

  def load_yaml(path, default:)
    return default unless File.exist?(path)

    data = YAML.safe_load(File.read(path, mode: "r:UTF-8"), aliases: true) || default
    data.is_a?(Array) ? data : default
  rescue Psych::Exception
    default
  end

  def write_yaml(path, data)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, YAML.dump(data), mode: "w:UTF-8")
  end

  def utf8_string(value)
    return nil if value.nil?

    string = value.to_s.dup
    string.force_encoding(Encoding::UTF_8)
    string = string.encode("UTF-8", invalid: :replace, undef: :replace) unless string.valid_encoding?
    string
  end
end
