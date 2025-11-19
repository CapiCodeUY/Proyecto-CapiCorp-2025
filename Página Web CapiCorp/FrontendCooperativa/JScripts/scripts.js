document.addEventListener('DOMContentLoaded', () => {
  const $ = (s, r=document) => r.querySelector(s);
  const $$ = (s, r=document) => Array.from(r.querySelectorAll(s));

  const baseFor = (url) => `APIs/${url}`;

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

  const loginForm = $('#login-form');
  if (loginForm) {
    loginForm.addEventListener('submit', async (e) => {
      e.preventDefault();
      const email = $('#login_email')?.value?.trim();
      const pass = $('#login_pass')?.value ?? '';

      if (!email || !pass) {
        showMsg(loginForm, 'Completá email y contraseña.', 'warn');
        return;
      }

      try {
        const res = await fetch(baseFor('api.php/login'), {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ usr_email: email, usr_pass: pass })
        });
        if (!res.ok) throw new Error('Error');
        const data = await res.json();
        if (data?.success) {
          if (data.estado === 'pendiente') {
            showMsg(loginForm, 'Tu registro está pendiente de aprobación.', 'warn');
            return;
          } if (data.estado === 'rechazado') {
            showMsg(loginForm, 'Tu registro fue rechazado.', 'err');
            return;
          }
          showMsg(loginForm, 'Inicio de sesión exitoso.', 'ok');
          localStorage.setItem('userId', data.success[0]);
          const isAdmin = await fetch(baseFor('api.php/is_admin'), {
            method: 'POST',
            body: JSON.stringify({ id: data.success[0] })
          }).then(res => res.json());
          setTimeout(() => location.href = isAdmin.success ? 'admin.html' : 'usuario.html', 900);
        } else {
          showMsg(loginForm, data.error, 'err');
        }
      } catch (err) {
        showMsg(loginForm, 'Error de red.', 'err');
      }
    });
  }

  const pendientesList = $('#pendientes-list');
  if (pendientesList) {
    fetch(baseFor('api.php/pendientes')).then(res => res.json()).then(data => {
      data.forEach(user => {
        const li = document.createElement('li');
        li.textContent = user.email;
        const approveBtn = document.createElement('button');
        approveBtn.textContent = 'Aprobar';
        approveBtn.onclick = async () => {
          const res = await fetch(baseFor('api.php/aprobar'), {
            method: 'POST',
            body: JSON.stringify({ id: user.id_persona })
          }).then(res => res.json());
          if (res.success) li.remove();
        };
        const rejectBtn = document.createElement('button');
        rejectBtn.textContent = 'Rechazar';
        rejectBtn.onclick = async () => {
          const motivo = prompt('Motivo del rechazo');
          if (motivo) {
            const res = await fetch(baseFor('api.php/rechazar'), {
              method: 'POST',
              body: JSON.stringify({ id: user.id_persona, motivo })
            }).then(res => res.json());
            if (res.success) li.remove();
          }
        };
        li.append(approveBtn, rejectBtn);
        pendientesList.append(li);
      });
    });
  }

  const datosForm = $('#datos-form');
  if (datosForm) {
    datosForm.addEventListener('submit', async (e) => {
      e.preventDefault();
      const tel = $('#tel').value;
      const ci = $('#ci').value;
      const id = localStorage.getItem('userId');
      const res = await fetch(baseFor('api.php/update_datos'), {
        method: 'POST',
        body: JSON.stringify({ id, tel, ci })
      }).then(res => res.json());
      showMsg(datosForm, res.success ? 'Datos guardados.' : res.error, res.success ? 'ok' : 'err');
    });
  }

  const horasForm = $('#horas-form');
  if (horasForm) {
    const horasInput = $('#horas');
    const motivoField = $('#motivo-field');
    horasInput.addEventListener('input', () => {
      motivoField.style.display = parseInt(horasInput.value) < 21 ? 'block' : 'none';
    });
    horasForm.addEventListener('submit', async (e) => {
      e.preventDefault();
      const horas = parseInt($('#horas').value);
      const motivo = $('#motivo').value;
      if (horas < 21 && !motivo) {
        showMsg(horasForm, 'Motivo requerido si <21 hs.', 'warn');
        return;
      }
      const id = localStorage.getItem('userId');
      const res = await fetch(baseFor('api.php/registrar_horas'), {
        method: 'POST',
        body: JSON.stringify({ id, horas, motivo })
      }).then(res => res.json());
      showMsg(horasForm, res.success ? 'Horas registradas.' : res.error, res.success ? 'ok' : 'err');
    });
  }

  const pagosForm = $('#pagos-form');
  if (pagosForm) {
    pagosForm.addEventListener('submit', async (e) => {
      e.preventDefault();
      const formData = new FormData();
      formData.append('comprobante', $('#comprobante').files[0]);
      formData.append('id', localStorage.getItem('userId'));
      const res = await fetch(baseFor('api.php/subir_pago'), {
        method: 'POST',
        body: formData
      }).then(res => res.json());
      showMsg(pagosForm, res.success ? 'Comprobante subido.' : res.error, res.success ? 'ok' : 'err');
      const statusRes = await fetch(baseFor('api.php/status_pagos'), {
        method: 'POST',
        body: JSON.stringify({ id: localStorage.getItem('userId') })
      }).then(res => res.json());
      $('#status').textContent = `Status: ${statusRes.status}`;
    });
  }

  function logout() {
    localStorage.clear();
    location.href = 'acceso-socios.html';
  }
});