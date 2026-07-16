class HomeController < ApplicationController
  def index
    @conversations = Conversation.order(updated_at: :desc)
    @current_conversation = Conversation.find_by(id: params[:conversation_id]) || Conversation.last || Conversation.create(title: "Chat 1")
    @messages = @current_conversation.messages.order(:created_at)
  end

  def new_conversation
    conversation = Conversation.create(title: "Chat #{Conversation.count + 1}")

    respond_to do |format|
      format.html { redirect_to root_path(conversation_id: conversation.id) }
      format.json { render json: { id: conversation.id } }
    end
  end

  def destroy_conversation
    conversation = Conversation.find_by(id: params[:id])

    if conversation
      conversation.messages.destroy_all
      conversation.destroy
    end

    respond_to do |format|
      format.html { redirect_to root_path, notice: "Chat removido" }
      format.json { render json: { success: true } }
    end
  end

  def chat
    message = params[:message]
    conversation_id = params[:conversation_id]

    conversation = Conversation.find_by(id: conversation_id)

    conversation ||= Conversation.create(title: message.truncate(30))

    Message.create(role: "user", content: message, conversation: conversation)

    context_service = AiContextService.new
    context_prompt = context_service.build_context_prompt(message)

    messages = conversation.messages.order(:created_at).map do |msg|
      {
        role: msg.role == "bot" ? "assistant" : "user",
        content: msg.content
      }
    end

    prompt_messages = []
    prompt_messages << { role: "system", content: context_prompt } if context_prompt.present?
    prompt_messages << { role: "system", content: "Lembre-se: use o contexto de memória e personalizações sempre que isso ajudar a responder melhor." }
    prompt_messages.concat(messages)

    response = OllamaService.chat(prompt_messages)

    if response.present?
      memorize_if_requested(message, response, context_service)
    end

    Message.create(role: "bot", content: response, conversation: conversation)

    render json: { response: response }
  end

  private

  def memorize_if_requested(user_message, response, context_service)
    return if user_message.blank?

    candidate_sentences = split_sentences(user_message)
    candidate_sentences.concat(split_sentences(response)) if explicit_memory_request?(user_message) && response.present?

    facts = candidate_sentences.filter_map do |sentence|
      cleaned = normalize_sentence(sentence)
      next if cleaned.blank?
      next unless should_store_memory?(cleaned)

      cleaned
    end

    facts.uniq.each { |fact| context_service.save_memory_fact(fact) }
  end

  def split_sentences(text)
    text.to_s.split(/[.?!]/).map(&:strip).reject(&:blank?)
  end

  def explicit_memory_request?(text)
    text.to_s.match?(/(?:memor|lembr|guardar|salvar|anotar|registrar)/i)
  end

  def should_store_memory?(sentence)
    return false if sentence.blank?
    return true if explicit_memory_request?(sentence)

    sentence.match?(/(?:gosto|gosta|adoro|prefiro|detesto|odeio|amo|costumo|sempre|normalmente|prefere|tenho|tive|estou|estava|quero|preciso|necessito|dor|febre|cansaço|ansiedade|estresse|resfriado|doença|medicação|tratamento|alergia|coração|pressão|hoje|ontem|agora|amanhã|meu|minha|meus|minhas|nome|chamo|chama|moro|trabalho|estudo)/i)
  end

  def normalize_sentence(sentence)
    cleaned = sentence.to_s.strip
    cleaned = cleaned.gsub(/\b(?:guarda|guardar|salvar|salva|anotar|anota|lembrar|lembrar|registrar|registra|memorizar|memoriza|entendido|ok|okay|vou|vou lembrar|vou guardar)\b/i, "").strip
    cleaned = cleaned.gsub(/^(?:na memória|na memoria|que|que\s+)/i, "").strip
    cleaned = cleaned.gsub(/^(?:eu|a?i|ele|ela|o usuário|o user|eu gostaria|gostaria|por favor|por favor,|sua|seu|meu|minha|meus|minhas)\s+/i, "").strip
    cleaned = cleaned.gsub(/\s+/, " ").strip
    cleaned
  end
end
