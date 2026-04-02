import "@hotwired/turbo-rails"
import "controllers"

const input = document.getElementById('input')
const btn   = document.getElementById('send')
const box   = document.getElementById('chat-box')

function addMessage(text, type) {
  const div = document.createElement('div')
  div.classList.add('message', type)
  div.textContent = text
  box.appendChild(div)
  box.scrollTop = box.scrollHeight
}

input.addEventListener('keydown', (e) => {
  if (e.key === 'Enter') {
    btn.click()
  }
})

btn.addEventListener('click', async () => {
  const text = input.value.trim()
  if (!text) return

  addMessage(text, 'user')
  input.value = ''
  btn.disabled = true

  addMessage('...', 'bot')

  const res = await fetch('/chat', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
    },
    body: JSON.stringify({ message: text })
  })

  const data = await res.json()
  box.lastChild.textContent = data.response
  btn.disabled = false
})