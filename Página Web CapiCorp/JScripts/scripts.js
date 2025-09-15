document.addEventListener('DOMContentLoaded', () => {
  // Utilidades
  const $ = (s, r=document) => r.querySelector(s);
  const $$ = (s, r=document) => Array.from(r.querySelectorAll(s));

  const apiBase = '../APIs/api.php'; // En index.html será "APIs/api.php"
  const isHome   = !!document.body?.dataset?.home;
  const baseFor = (url) => {
    // Si estamos en /Páginas Adyacentes, mantener ../APIs/..., en home usar APIs/...
    return location.pathname.includes('P%C3%A1ginas%20Adyacentes') || location.pathname.includes('Páginas Adyacentes')
      ? `../APIs/${url}` : `APIs/${url}`;
  };

  // Mensajería
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

  // Fuerza de contraseña muy simple
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

  // Toggle de contraseña
  $$('.input-group .toggle').forEach(btn=>{
    btn.addEventListener('click', ()=>{
      const input = btn.closest('.input-group').querySelector('input[type="password"], input[type="text"]');
      if(!input) return;
      const isPwd = input.type === 'password';
      input.type = isPwd ? 'text' : 'password';
      btn.textContent = isPwd ? 'Ocultar' : 'Mostrar';
    });
  });

  // ===== Registro =====
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

      try{
        const res = await fetch(baseFor('funciones_usuario.php'), {
          method: 'POST',
          headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
          body: `nombre_completo=${encodeURIComponent(name)}&email=${encodeURIComponent(email)}&contrasena=${encodeURIComponent(pass)}`
        });
        const data = await res.json();
        if(data.success){
          showMsg(registerForm, data.message + ' ✅', 'ok');
          registerForm.reset();
          updateStrength(bar, '');
          setTimeout(()=> location.href = isHome ? 'Páginas Adyacentes/acceso-socios.html' : 'acceso-socios.html', 900);
        } else {
          showMsg(registerForm, 'Error: ' + data.message, 'err');
        }
      }catch(err){
        console.error(err);
        showMsg(registerForm, 'Error de red. Intentalo de nuevo.', 'err');
      }
    });
  }

  // ===== Login =====
  const loginForm = $('#login-form');
  if (loginForm) {
    loginForm.addEventListener('submit', async (e) => {
      e.preventDefault();
      const email = $('#login_email')?.value?.trim();
      const pass  = $('#login_pass')?.value ?? '';

      if(!email || !pass){
        showMsg(loginForm, 'Completá email y contraseña.', 'warn');
        return;
      }

      try{
        const res = await fetch(baseFor('api.php/login'), {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ usr_email: email, usr_pass: pass })
        });
        const data = await res.json();
        if(data?.success){
          showMsg(loginForm, 'Inicio de sesión exitoso 🎉', 'ok');
          console.log("id_persona", data.success[0]);
          console.log("email", data.success[1]);
          console.log("nombre_completo", data.success[2]);
          // Aquí podrías redirigir si corresponde
          // location.href = '../index.html';
        }else{
          showMsg(loginForm, data?.message || 'Credenciales inválidas.' + data.error);
        }
      }catch(err){
        console.error(err);
        showMsg(loginForm, 'Error de red. Probá nuevamente.', 'err');
      }
    });
  }
});
