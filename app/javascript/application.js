import "@hotwired/turbo-rails"
import "controllers"

const input = document.getElementById('input')
const btn   = document.getElementById('send')
const box   = document.getElementById('chat-box')

function getConversationId() {
  return document.getElementById('conversation-id')?.value
}

function addMessage(text, type) {
  const div = document.createElement('div')
  div.classList.add('message', type)
  div.textContent = text
  box.appendChild(div)
  box.scrollTop = box.scrollHeight
}

function newConversation() {
  fetch('/new_conversation', {
    method: 'POST',
    headers: {
      'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
    }
  }).then(() => window.location.href = '/')
}

if (input && btn && box) {

  input.addEventListener('keydown', (e) => {
    if (e.key === 'Enter') btn.click()
  })

  btn.addEventListener('click', async () => {
    const text = input.value.trim()
    if (!text) return

    addMessage(text, 'user')
    input.value = ''
    btn.disabled = true

    addMessage('...', 'bot')

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
      box.lastChild.textContent = data.response

    } catch (err) {
      box.lastChild.textContent = "Erro ao responder 😢"
      console.error(err)
    }

    btn.disabled = false
  })

  document.addEventListener('DOMContentLoaded', () => {
    box.scrollTop = box.scrollHeight
  })
}