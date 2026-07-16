import "@hotwired/turbo-rails"

function getConversationId() {
  return document.getElementById('conversation-id')?.value
}

function addMessage(text, type) {
  const box = document.getElementById('chat-box')
  if (!box) return null

  const div = document.createElement('div')
  div.classList.add('message', type)
  div.textContent = text
  box.appendChild(div)
  box.scrollTop = box.scrollHeight
  return div
}

window.newConversation = function () {
  fetch('/new_conversation', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
      'Accept': 'application/json'
    }
  })
    .then((res) => res.json())
    .then((data) => {
      if (data.id) {
        window.location.href = '/?conversation_id=' + data.id
      }
    })
    .catch((err) => console.error(err))
}

window.deleteConversation = function (conversationId) {
  fetch(`/conversations/${conversationId}`, {
    method: 'DELETE',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
      'Accept': 'application/json'
    }
  })
    .then((res) => res.json())
    .then(() => {
      window.location.href = '/'
    })
    .catch((err) => console.error(err))
}

window.sendMessage = async function () {
  const input = document.getElementById('input')
  const btn = document.getElementById('send')
  const text = input?.value?.trim()

  if (!text || !btn || !input) return

  addMessage(text, 'user')
  input.value = ''
  btn.disabled = true
  input.disabled = true

  const thinkingMessage = addMessage('Pensando...', 'bot')

  try {
    const res = await fetch('/chat', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({
        message: text,
        conversation_id: getConversationId()
      })
    })

    const data = await res.json()
    if (thinkingMessage) {
      thinkingMessage.textContent = data.response
    }
  } catch (err) {
    if (thinkingMessage) {
      thinkingMessage.textContent = 'Erro ao responder 😢'
    }
    console.error(err)
  }

  btn.disabled = false
  input.disabled = false
  input.focus()
}

function bindChat() {
  const input = document.getElementById('input')
  const btn = document.getElementById('send')
  const box = document.getElementById('chat-box')
  const newChatButton = document.getElementById('new-chat')

  if (!input || !btn || !box) return

  if (!input.dataset.bound) {
    input.addEventListener('keydown', (e) => {
      if (e.key === 'Enter') {
        e.preventDefault()
        window.sendMessage()
      }
    })
    input.dataset.bound = 'true'
  }

  if (!btn.dataset.bound) {
    btn.addEventListener('click', () => window.sendMessage())
    btn.dataset.bound = 'true'
  }

  if (newChatButton && !newChatButton.dataset.bound) {
    newChatButton.addEventListener('click', () => window.newConversation())
    newChatButton.dataset.bound = 'true'
  }

  document.querySelectorAll('.delete-chat').forEach((button) => {
    if (!button.dataset.bound) {
      button.addEventListener('click', () => window.deleteConversation(button.dataset.conversationId))
      button.dataset.bound = 'true'
    }
  })

  box.scrollTop = box.scrollHeight
}

document.addEventListener('DOMContentLoaded', bindChat)
document.addEventListener('turbo:load', bindChat)