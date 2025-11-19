document.addEventListener('DOMContentLoaded', () => {
  const $ = (s, r=document) => r.querySelector(s);
  const $$ = (s, r=document) => Array.from(r.querySelectorAll(s));

  const baseFor = (url) => {
    return location.pathname.includes('P%C3%A1ginas%20Adyacentes') || location.pathname.includes('Páginas Adyacentes')
      ? `../APIs/${url}` : `APIs/${url}`;
  };

  function showMsg(container, text, type='ok'){
    let el = container.querySelector('.mensaje');
    if(!el){
      el = document.createElement('p');
      el.className = 'mensaje';
      container.appendChild(el);
    }
    el.classList.remove('ok','warn','err');
    el.classList.add(type);
    el.textContent = text;
  }

  function strengthScore(v){
    let s = 0;
    if(v.length >= 8) s++;
    if(/[A-Z]/.test(v)) s++;
    if(/[a-z]/.test(v)) s++;
    if(/\d/.test(v)) s++;
    if(/[^A-Za-z0-9]/.test(v)) s++;
    return Math.min(s, 5);
  }
  function updateStrength(bar, val){
    if(!bar) return;
    const score = strengthScore(val);
    const pct = [0, 20, 40, 70, 85, 100][score];
    bar.style.width = pct + '%';
  }

  $$('.input-group .toggle').forEach(btn=>{
    btn.addEventListener('click', () => {
      const input = btn.closest('.input-group').querySelector('input[type="password"], input[type="text"]');
      if(!input) return;
      const isPwd = input.type === 'password';
      input.type = isPwd ? 'text' : 'password';
      btn.textContent = isPwd ? 'Ocultar' : 'Mostrar';
    });
  });

  const registerForm = $('#register-form');
  if (registerForm) {
    const pwd = $('#reg_pass');
    const bar = $('#pass_strength');

    pwd?.addEventListener('input', (e)=> updateStrength(bar, e.target.value));

    registerForm.addEventListener('submit', async (e) => {
      e.preventDefault();
      const name = $('#reg_name')?.value?.trim();
      const email = $('#reg_email')?.value?.trim();
      const pass = $('#reg_pass')?.value ?? '';

      if(!name || !email || !pass){
        showMsg(registerForm, 'Completá todos los campos.', 'warn');
        return;
      }
      if(!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)){
        showMsg(registerForm, 'Email inválido.', 'warn');
        return;
      }
      if(pass.length < 6){
        showMsg(registerForm, 'La contraseña debe tener al menos 6 caracteres.', 'warn');
        return;
      }

      try {
        const res = await fetch(baseFor('api.php/usuarios'), {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ usr_name: name, usr_email: email, usr_pass: pass })
        });
        if (!res.ok) throw new Error('Error en el registro');
        const data = await res.json();
        if (data?.success) {
          showMsg(registerForm, 'Registro enviado. Pendiente de aprobación.', 'ok');
          registerForm.reset();
          updateStrength(bar, '');
        } else {
          showMsg(registerForm, data.error, 'err');
        }
      } catch (err) {
        showMsg(registerForm, 'Error de red.', 'err');
      }
    });
  }

  const contactForm = $('#contact-form');
  if (contactForm) {
    contactForm.addEventListener('submit', async (e) => {
      e.preventDefault();
      const name = $('#c_name')?.value?.trim();
      const email = $('#c_email')?.value?.trim();
      const msg = $('#c_msg')?.value?.trim();

      if(!name || !email || !msg){
        showMsg(contactForm, 'Completá todos los campos.', 'warn');
        return;
      }
      if(!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)){
        showMsg(contactForm, 'Email inválido.', 'warn');
        return;
      }

      grecaptcha.ready(() => {
        grecaptcha.execute('TU_SITEKEY_AQUI', {action: 'submit'}).then(async (token) => {
          try {
            const res = await fetch(baseFor('contact.php'), {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({ name, email, message: msg, 'g-recaptcha-response': token })
            });
            if (!res.ok) throw new Error('Error en el envío');
            const data = await res.json();
            if (data.success) {
              showMsg(contactForm, '¡Mensaje enviado!', 'ok');
              contactForm.reset();
            } else {
              showMsg(contactForm, data.error, 'err');
            }
          } catch (err) {
            showMsg(contactForm, 'Error de red.', 'err');
          }
        });
      });
    });
  }
});