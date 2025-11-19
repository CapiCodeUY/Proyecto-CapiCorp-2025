<?php
error_reporting(E_ERROR | E_PARSE);
ini_set('display_errors', 0);
ini_set('log_errors', 1);
ini_set('error_log', 'php_errors.log');

class Usuario
{
    private $conn;

    public function __construct($conn)
    {
        $this->conn = $conn;
    }

    public function getAllUsuarios()
    {
        $query = "SELECT * FROM persona";
        $result = mysqli_query($this->conn, $query);
        if ($result === false) {
            error_log("Error en getAllUsuarios: " . mysqli_error($this->conn));
            return [];
        }
        $usuarios = [];
        while ($row = mysqli_fetch_assoc($result)) {
            $usuarios[] = $row;
        }
        return $usuarios;
    }

    public function getUsuarioById($id)
    {
        $query = "SELECT * FROM persona WHERE id_persona = ?";
        $stmt = $this->conn->prepare($query);
        $stmt->bind_param("i", $id);
        $stmt->execute();
        $result = $stmt->get_result();
        $usuario = $result->fetch_assoc();
        return $usuario;
    }

    public function addUsuario($data)
    {
        if (!isset($data['usr_name']) || !isset($data['usr_email']) || !isset($data['usr_pass'])) {
            http_response_code(400);
            return json_encode(["error" => "Datos incompletos"]);
        }

        $usr_name = $data['usr_name'];
        $usr_email = $data['usr_email'];
        $usr_pass = password_hash($data['usr_pass'], PASSWORD_DEFAULT);

        $check_email = $this->conn->prepare("SELECT id_persona FROM persona WHERE email = ?");
        $check_email->bind_param("s", $usr_email);
        $check_email->execute();
        if ($check_email->get_result()->num_rows > 0) {
            http_response_code(400);
            return json_encode(["error" => "Usuario ya existe"]);
        }

        $query = "INSERT INTO persona (nombre_completo, email, contrasena) VALUES (?, ?, ?)";
        $stmt = $this->conn->prepare($query);
        $stmt->bind_param("sss", $usr_name, $usr_email, $usr_pass);
        $stmt->execute();
        $id = $this->conn->insert_id;

        $estado = 'pendiente';
        $query_usuario = "INSERT INTO Usuario (id_persona, estado_acceso) VALUES (?, ?)";
        $stmt = $this->conn->prepare($query_usuario);
        $stmt->bind_param("is", $id, $estado);
        $stmt->execute();

        http_response_code(201);
        return json_encode(["success" => true]);
    }

    public function loginUsuario($data)
    {
        if (!isset($data['usr_email']) || !isset($data['usr_pass'])) {
            http_response_code(400);
            return json_encode(["error" => "Datos incompletos"]);
        }

        $usr_email = $data['usr_email'];
        $usr_pass = $data['usr_pass'];
        $query = "SELECT * FROM persona WHERE email = ?";
        $stmt = $this->conn->prepare($query);
        $stmt->bind_param("s", $usr_email);
        $stmt->execute();
        $result = $stmt->get_result();
        if ($result->num_rows > 0) {
            $usuario = $result->fetch_assoc();
            if (password_verify($usr_pass, $usuario['contrasena'])) {
                $query_estado = "SELECT estado_acceso FROM Usuario WHERE id_persona = ?";
                $stmt = $this->conn->prepare($query_estado);
                $stmt->bind_param("i", $usuario['id_persona']);
                $stmt->execute();
                $result = $stmt->get_result();
                $estado = $result->fetch_assoc()['estado_acceso'];
                return json_encode(["success" => [$usuario['id_persona'], $usr_email, $usuario['nombre_completo']], "estado" => $estado]);
            } else {
                http_response_code(400);
                return json_encode(["error" => "Contraseña incorrecta"]);
            }
        } else {
            http_response_code(400);
            return json_encode(["error" => "Usuario no encontrado"]);
        }
    }

    public function logoutUsuario($data)
    {
        if (!isset($data['usr_key'])) {
            http_response_code(400);
            return json_encode(["error" => "Datos incompletos"]);
        }

        $key = $data['usr_key'];
        $query = "DELETE FROM access_token WHERE token = ?";
        $stmt = $this->conn->prepare($query);
        $stmt->bind_param("s", $key);
        $result = $stmt->execute();
        if ($result) {
            http_response_code(200);
            return json_encode(["success" => "Sesión cerrada correctamente"]);
        } else {
            http_response_code(500);
            return json_encode(["error" => "Error al cerrar sesión"]);
        }
    }

    public function updateUsuario($id, $data)
    {
        if (!isset($data['usr_name']) || !isset($data['usr_email']) || !isset($data['usr_pass'])) {
            return false;
        }

        $usr_name = $data['usr_name'];
        $usr_email = $data['usr_email'];
        $usr_pass = password_hash($data['usr_pass'], PASSWORD_DEFAULT);
        $query = "UPDATE persona SET nombre_completo = ?, email = ?, contrasena = ? WHERE id_persona = ?";
        $stmt = $this->conn->prepare($query);
        $stmt->bind_param("sssi", $usr_name, $usr_email, $usr_pass, $id);
        $result = $stmt->execute();
        return $result;
    }

    public function deleteUsuario($id)
    {
        $query = "DELETE FROM persona WHERE id_persona = ?";
        $stmt = $this->conn->prepare($query);
        $stmt->bind_param("i", $id);
        $result = $stmt->execute();
        return $result;
    }

    public function getPendientes()
    {
        $query = "SELECT p.id_persona, p.email FROM persona p JOIN Usuario u ON p.id_persona = u.id_persona WHERE u.estado_acceso = 'pendiente'";
        $result = mysqli_query($this->conn, $query);
        $pendientes = [];
        while ($row = mysqli_fetch_assoc($result)) {
            $pendientes[] = $row;
        }
        return $pendientes;
    }

    public function aprobarUsuario($id)
    {
        $query_puertas = "SELECT id_unidad FROM Unidad_habitacional WHERE estado_asignacion = 'disponible' LIMIT 1";
        $result = mysqli_query($this->conn, $query_puertas);
        if (mysqli_num_rows($result) == 0) {
            return json_encode(["error" => "No hay viviendas disponibles"]);
        }
        $row = mysqli_fetch_assoc($result);
        $assigned = $row['id_unidad'];

        $query_asigna = "INSERT INTO Se_asigna (id_unidad, id_persona) VALUES (?, ?)";
        $stmt = $this->conn->prepare($query_asigna);
        $stmt->bind_param("ii", $assigned, $id);
        $stmt->execute();

        $query_update = "UPDATE Unidad_habitacional SET estado_asignacion = 'ocupada' WHERE id_unidad = ?";
        $stmt = $this->conn->prepare($query_update);
        $stmt->bind_param("i", $assigned);
        $stmt->execute();

        $query_estado = "UPDATE Usuario SET estado_acceso = 'aprobado' WHERE id_persona = ?";
        $stmt = $this->conn->prepare($query_estado);
        $stmt->bind_param("i", $id);
        $stmt->execute();

        $query_email = "SELECT email FROM persona WHERE id_persona = ?";
        $stmt = $this->conn->prepare($query_email);
        $stmt->bind_param("i", $id);
        $stmt->execute();
        $result = $stmt->get_result();
        $email = $result->fetch_assoc()['email'];

        mail($email, 'Registro Aprobado', "Su registro ha sido aprobado. Número de puerta: $assigned", "From: no-reply@capicorp.com");

        return json_encode(["success" => true]);
    }

    public function rechazarUsuario($id, $motivo)
    {
        $query_estado = "UPDATE Usuario SET estado_acceso = 'rechazado' WHERE id_persona = ?";
        $stmt = $this->conn->prepare($query_estado);
        $stmt->bind_param("i", $id);
        $stmt->execute();

        $query_email = "SELECT email FROM persona WHERE id_persona = ?";
        $stmt = $this->conn->prepare($query_email);
        $stmt->bind_param("i", $id);
        $stmt->execute();
        $result = $stmt->get_result();
        $email = $result->fetch_assoc()['email'];

        mail($email, 'Registro Rechazado', "Motivo: $motivo", "From: no-reply@capicorp.com");

        return json_encode(["success" => true]);
    }

    public function isAdmin($id)
    {
        $query = "SELECT * FROM Administrador WHERE id_admin = ?";
        $stmt = $this->conn->prepare($query);
        $stmt->bind_param("i", $id);
        $stmt->execute();
        $result = $stmt->get_result();
        return json_encode(["success" => $result->num_rows > 0]);
    }

    public function updateDatos($data)
    {
        $query = "UPDATE persona SET telefono = ?, ci = ? WHERE id_persona = ?";
        $stmt = $this->conn->prepare($query);
        $stmt->bind_param("ssi", $data['tel'], $data['ci'], $data['id']);
        $result = $stmt->execute();
        return json_encode(["success" => $result]);
    }

    public function registrarHoras($data)
    {
        $query = "INSERT INTO Registro_horas (id_persona, horas_registradas, semana, motivo) VALUES (?, ?, CURDATE(), ?)";
        $stmt = $this->conn->prepare($query);
        $stmt->bind_param("iis", $data['id'], $data['horas'], $data['motivo']);
        $result = $stmt->execute();
        return json_encode(["success" => $result]);
    }

    public function subirPago($id, $file)
    {
        $target_dir = "uploads/";
        $target_file = $target_dir . basename($file["name"]);
        move_uploaded_file($file["tmp_name"], $target_file);
        $query = "INSERT INTO Pago (mes, monto, estado_aprobacion, archivo_comprobante, id_persona, inicial) VALUES (CURDATE(), 0, 'pendiente', ?, ?, 0)";
        $stmt = $this->conn->prepare($query);
        $stmt->bind_param("si", $target_file, $id);
        $result = $stmt->execute();
        return json_encode(["success" => $result]);
    }

    public function getStatusPagos($id)
    {
        $query = "SELECT estado_aprobacion FROM Pago WHERE id_persona = ? ORDER BY id_pago DESC LIMIT 1";
        $stmt = $this->conn->prepare($query);
        $stmt->bind_param("i", $id);
        $stmt->execute();
        $result = $stmt->get_result();
        $status = $result->num_rows > 0 ? $result->fetch_assoc()['estado_aprobacion'] : 'al día';
        return json_encode(["status" => $status]);
    }
}
?>