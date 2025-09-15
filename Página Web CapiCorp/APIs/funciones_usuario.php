<?php
header('Content-Type: application/json');  // Para que el JS lo lea como JSON
include 'config.php';

$response = ['success' => false, 'message' => ''];

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $nombre = trim($_POST['nombre_completo'] ?? '');
    $email = trim($_POST['email'] ?? '');
    $contrasena_raw = $_POST['contrasena'] ?? '';
    
    if (empty($nombre) || empty($email) || empty($contrasena_raw)) {
        $response['message'] = 'Faltan datos obligatorios.';
        echo json_encode($response);
        exit;
    }
    
    $contrasena = password_hash($contrasena_raw, PASSWORD_DEFAULT);

    // Verificar si email ya existe
    $check_email = $conn->prepare("SELECT id_persona FROM Persona WHERE email = ?");
    $check_email->bind_param("s", $email);
    $check_email->execute();
    if ($check_email->get_result()->num_rows > 0) {
        $response['message'] = 'El email ya está registrado.';
        echo json_encode($response);
        exit;
    }

    // Generar id_persona manualmente
    $sql_max = "SELECT MAX(id_persona) AS max_id FROM Persona";
    $result_max = $conn->query($sql_max);
    $row_max = $result_max->fetch_assoc();
    $id_persona = ($row_max['max_id'] ? (int)$row_max['max_id'] + 1 : 1);

    // Insertar en Persona
    $stmt_persona = $conn->prepare("INSERT INTO Persona (id_persona, contrasena, nombre_completo, email) VALUES (?, ?, ?, ?)");
    $stmt_persona->bind_param("isss", $id_persona, $contrasena, $nombre, $email);
    if ($stmt_persona->execute()) {
        // Insertar en Usuario
        $estado_acceso = 'activo';
        $stmt_usuario = $conn->prepare("INSERT INTO Usuario (id_persona, estado_acceso) VALUES (?, ?)");
        $stmt_usuario->bind_param("is", $id_persona, $estado_acceso);
        if ($stmt_usuario->execute()) {
            // Buscar unidad disponible siguiendo el orden específico (101-109, 201-209, etc.)
            $sql_unidad = "SELECT id_unidad FROM Unidad_habitacional WHERE estado_asignacion = 'disponible' ORDER BY id_unidad ASC LIMIT 1";
            $result_unidad = $conn->query($sql_unidad);
            
            if ($result_unidad->num_rows > 0) {
                $row_unidad = $result_unidad->fetch_assoc();
                $id_unidad = (int)$row_unidad['id_unidad'];

                // Verificar que la unidad esté en el rango válido (101-1009)
                if ($id_unidad >= 101 && $id_unidad <= 1009) {
                    // Insertar en Se_asigna
                    $stmt_asigna = $conn->prepare("INSERT INTO Se_asigna (id_unidad, id_persona) VALUES (?, ?)");
                    $stmt_asigna->bind_param("ii", $id_unidad, $id_persona);
                    if ($stmt_asigna->execute()) {
                        // Actualizar estado de la unidad
                        $stmt_update = $conn->prepare("UPDATE Unidad_habitacional SET estado_asignacion = 'ocupada' WHERE id_unidad = ?");
                        $stmt_update->bind_param("i", $id_unidad);
                        if ($stmt_update->execute()) {
                            $response['success'] = true;
                            $response['message'] = "Usuario registrado exitosamente. Se te ha asignado la vivienda con número de puerta $id_unidad.";
                            $response['unidad'] = $id_unidad;
                            $response['persona_id'] = $id_persona;
                        } else {
                            // Rollback en caso de error
                            $conn->query("DELETE FROM Se_asigna WHERE id_persona = $id_persona");
                            $conn->query("DELETE FROM Usuario WHERE id_persona = $id_persona");
                            $conn->query("DELETE FROM Persona WHERE id_persona = $id_persona");
                            $response['message'] = 'Error al actualizar estado de unidad: ' . $conn->error;
                        }
                    } else {
                        // Rollback en caso de error
                        $conn->query("DELETE FROM Usuario WHERE id_persona = $id_persona");
                        $conn->query("DELETE FROM Persona WHERE id_persona = $id_persona");
                        $response['message'] = 'Error al asignar unidad: ' . $conn->error;
                    }
                } else {
                    // Rollback - unidad fuera de rango
                    $conn->query("DELETE FROM Usuario WHERE id_persona = $id_persona");
                    $conn->query("DELETE FROM Persona WHERE id_persona = $id_persona");
                    $response['message'] = 'Error: Unidad fuera del rango permitido (101-1009).';
                }
            } else {
                // Rollback - no hay unidades disponibles
                $conn->query("DELETE FROM Usuario WHERE id_persona = $id_persona");
                $conn->query("DELETE FROM Persona WHERE id_persona = $id_persona");
                $response['message'] = 'Lo sentimos, no hay viviendas disponibles en este momento. Todas las unidades (101-1009) están ocupadas.';
            }
        } else {
            // Rollback en caso de error al crear usuario
            $conn->query("DELETE FROM Persona WHERE id_persona = $id_persona");
            $response['message'] = 'Error al crear usuario: ' . $conn->error;
        }
    } else {
        $response['message'] = 'Error al crear persona: ' . $conn->error;
    }
} else {
    $response['message'] = 'Método no permitido.';
}

echo json_encode($response);
$conn->close();
?>