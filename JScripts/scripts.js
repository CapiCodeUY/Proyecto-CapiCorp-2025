document.addEventListener('DOMContentLoaded', () => {
    const forms = document.querySelectorAll('form');

    forms.forEach(form => {
        form.addEventListener('submit', function (e) {
            e.preventDefault();

            let mensaje = form.querySelector('.mensaje');
            const btn = form.querySelector('button');

            if (!mensaje) {
                mensaje = document.createElement('p');
                mensaje.classList.add('mensaje');
                mensaje.style.marginTop = '15px';
                form.appendChild(mensaje);
            }

            btn.textContent = 'Procesando...';

            setTimeout(() => {
                const formId = form.id;

                if (formId === 'registro-form') {
                    async function registro(event) {
                        const data = {
                            usr_name: form.nombre.value,
                            usr_email: form.correo.value,
                            usr_pass: form.password.value
                        };
                        console.log(JSON.stringify(data));
                        fetch('../API/api.php/usuarios', {
                            method: 'POST',
                            headers: {
                                'Content-Type': 'application/json'
                            },
                            body: JSON.stringify(data)
                        })
                            .then(response => response.json())
                            .then(data => {
                                 mensaje.textContent = '✓ Usuario registrado correctamente.';
                                mensaje.style.color = '#28a745';
                            })
                            .catch(error => {
                                alert('Error al registrar usuario');
                                console.error(error);
                            });
                    };

                   

                } else if (formId === 'contacto-form') {
                    mensaje.textContent = '✓ Tu mensaje ha sido enviado.';
                    mensaje.style.color = '#007bff';

                } else if (formId === 'login-form') {
                    const bienvenida = document.getElementById('bienvenida');
                    if (bienvenida) bienvenida.style.display = 'block';

                    mensaje.textContent = '✓ Sesión iniciada con éxito.';
                    mensaje.style.color = '#ff6f00';
                } else {
                    mensaje.textContent = '✓ Operación simulada correctamente.';
                    mensaje.style.color = '#ff6f00';
                }

                if (btn.textContent.includes('Registrarse') || formId === 'registro-form') {
                    btn.textContent = 'Registrarse →';
                } else if (formId === 'login-form') {
                    btn.textContent = 'Ingresar →';
                } else {
                    btn.textContent = 'Enviar →';
                }

                form.reset();

                setTimeout(() => {
                    mensaje.textContent = '';
                    if (formId === 'login-form') {
                        const bienvenida = document.getElementById('bienvenida');
                        if (bienvenida) bienvenida.style.display = 'none';
                    }
                }, 4000);

            }, 1500);
        });
    });
});
