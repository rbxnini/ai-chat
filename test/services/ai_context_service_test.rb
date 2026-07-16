require "test_helper"
require "tmpdir"

class AiContextServiceTest < ActiveSupport::TestCase
  test "persists memory facts and personalizations for context prompts" do
    Dir.mktmpdir do |dir|
      memory_file = File.join(dir, "memory.yml")
      personalization_file = File.join(dir, "personalization.yml")
      service = AiContextService.new(memory_file_path: memory_file, personalization_file_path: personalization_file)

      service.save_memory_fact("O usuário gosta de azul")
      service.save_memory_fact("O usuário gosta de pizza")
      service.save_personalization("Sempre seja acolhedor e curioso")

      prompt = service.build_context_prompt("Olá")

      assert_includes prompt, "O usuário gosta de azul"
      assert_includes prompt, "O usuário gosta de pizza"
      assert_includes prompt, "Sempre seja acolhedor e curioso"
    end
  end

  test "persists relevant facts from the user's message without an explicit save request" do
    Dir.mktmpdir do |dir|
      memory_file = File.join(dir, "memory.yml")
      personalization_file = File.join(dir, "personalization.yml")
      service = AiContextService.new(memory_file_path: memory_file, personalization_file_path: personalization_file)
      controller = HomeController.new

      controller.send(:memorize_if_requested, "Eu gosto de azul", "Entendido", service)

      assert service.memory_facts.any? { |fact| fact.include?("gosto") && fact.include?("azul") }
    end
  end

  test "persists explicit memory requests from the user" do
    Dir.mktmpdir do |dir|
      memory_file = File.join(dir, "memory.yml")
      personalization_file = File.join(dir, "personalization.yml")
      service = AiContextService.new(memory_file_path: memory_file, personalization_file_path: personalization_file)
      controller = HomeController.new

      controller.send(:memorize_if_requested, "Guarda na memória que eu acordei hoje com dor de cabeça", "Entendido, vou lembrar disso", service)

      assert service.memory_facts.any? { |fact| fact.include?("dor de cabeça") }
    end
  end
end
