<?php
/* API RESTful para gestionar usuarios
 * Permite operaciones CRUD (Crear, Leer, Actualizar, Eliminar)
 * Requiere conexión a una base de datos MySQL
 */

// Importa las dependencias necesarias
require_once 'config.php';
require_once 'usuario.php';

// Configuración de logging
ini_set('log_errors', 1);
ini_set('error_log', 'php_errors.log');

// Establecer cabeceras CORS
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json');

// Verificar conexión a la base de datos
if (!$conn) {
    error_log("Error de conexión a la base de datos: " . mysqli_connect_error());
    http_response_code(500);
    echo json_encode(["error" => "Error de conexión a la base de datos"]);
    exit;
}

// Verificar y agregar la columna 'numero_puerta' si no existe
$check_column = "SHOW COLUMNS FROM persona LIKE 'numero_puerta'";
$result = mysqli_query($conn, $check_column);
if ($result === false) {
    error_log("Error al verificar columna numero_puerta: " . mysqli_error($conn));
    http_response_code(500);
    echo json_encode(["error" => "Error al verificar la estructura de la base de datos"]);
    exit;
}
if (mysqli_num_rows($result) == 0) {
    $alter_query = "ALTER TABLE persona ADD COLUMN numero_puerta VARCHAR(4) UNIQUE";
    if (!mysqli_query($conn, $alter_query)) {
        error_log("Error al agregar columna numero_puerta: " . mysqli_error($conn));
        http_response_code(500);
        echo json_encode(["error" => "Error al modificar la base de datos: " . mysqli_error($conn)]);
        exit;
    }
}

// Crea la instancia de la clase Usuario
$usuarioObj = new Usuario($conn);
// Obtiene el método de la solicitud HTTP
$method = $_SERVER['REQUEST_METHOD'];
// Obtiene el endpoint de la solicitud
$request_uri = isset($_SERVER['REQUEST_URI']) ? parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH) : '/';
$base_path = '/Página Web CapiCorp/APIs/api.php';
$endpoint = str_replace($base_path, '', $request_uri);
$endpoint = rtrim($endpoint, '/') ?: '/';
error_log("Método: $method, Endpoint: $endpoint, URI: " . $_SERVER['REQUEST_URI']);

// Procesa la solicitud según el método HTTP
switch ($method) {
    case 'GET':
        if ($endpoint === '/usuarios') {
            // Obtiene todos los usuarios
            $usuarios = $usuarioObj->getAllUsuarios();
            echo json_encode($usuarios);
        } elseif (preg_match('/^\/usuarios\/(\d+)$/', $endpoint, $matches)) {
            // Obtiene un usuario por ID
            $usuarioId = $matches[1];
            $usuario = $usuarioObj->getUsuarioById($usuarioId);
            echo json_encode($usuario);
        } else {
            error_log("GET Endpoint no encontrado: $endpoint");
            http_response_code(404);
            echo json_encode(["error" => "Endpoint no encontrado: $endpoint"]);
        }
        break;
    case 'POST':
        if ($endpoint === '/usuarios') {
            // Añade un nuevo usuario
            $data = json_decode(file_get_contents('php://input'), true);
            if (!$data) {
                error_log("Error: No se pudo decodificar el JSON de entrada");
                http_response_code(400);
                echo json_encode(["error" => "Datos JSON inválidos"]);
                exit;
            }

            // Obtener números de puerta usados
            $query = "SELECT numero_puerta FROM persona WHERE numero_puerta IS NOT NULL";
            $result = mysqli_query($conn, $query);
            if ($result === false) {
                error_log("Error al obtener números de puerta: " . mysqli_error($conn));
                http_response_code(500);
                echo json_encode(["error" => "Error al consultar números de puerta"]);
                exit;
            }
            $used = [];
            while ($row = mysqli_fetch_assoc($result)) {
                $used[] = $row['numero_puerta'];
            }

            // Encontrar el próximo número disponible
            $assigned = null;
            for ($floor = 1; $floor <= 10; $floor++) {
                $floor_str = ($floor < 10) ? strval($floor) : '10';
                for ($apt = 1; $apt <= 9; $apt++) {
                    $num = $floor_str . '0' . $apt;
                    if (!in_array($num, $used)) {
                        $assigned = $num;
                        break 2; // Salir de ambos bucles
                    }
                }
            }

            if ($assigned == null) {
                error_log("No hay viviendas disponibles");
                http_response_code(400);
                echo json_encode(["error" => "No hay viviendas disponibles"]);
                exit;
            }

            // Agregar el número de puerta a los datos
            $data['numero_puerta'] = $assigned;
            $result = $usuarioObj->addUsuario($data);
            $result_data = json_decode($result, true);
            if ($result_data && isset($result_data['success'])) {
                echo json_encode(["success" => true, "mensaje" => "Usuario registrado exitosamente", "numero_puerta" => $assigned]);
            } else {
                error_log("Error en addUsuario: " . $result);
                echo $result;
            }
        } elseif ($endpoint === '/login') {
            $data = json_decode(file_get_contents('php://input'), true);
            if (!$data) {
                error_log("Error: No se pudo decodificar el JSON de entrada para login");
                http_response_code(400);
                echo json_encode(["error" => "Datos JSON inválidos"]);
                exit;
            }
            $result = $usuarioObj->loginUsuario($data);
            echo $result;
        } elseif ($endpoint === '/logout') {
            $data = json_decode(file_get_contents('php://input'), true);
            if (!$data) {
                error_log("Error: No se pudo decodificar el JSON de entrada para logout");
                http_response_code(400);
                echo json_encode(["error" => "Datos JSON inválidos"]);
                exit;
            }
            $result = $usuarioObj->logoutUsuario($data);
            echo $result;
        } else {
            error_log("POST Endpoint no encontrado: $endpoint");
            http_response_code(404);
            echo json_encode(["error" => "Endpoint no encontrado: $endpoint"]);
        }
        break;
    case 'PUT':
        if (preg_match('/^\/usuarios\/(\d+)$/', $endpoint, $matches)) {
            $usuarioId = $matches[1];
            parse_str(file_get_contents('php://input'), $data);
            $result = $usuarioObj->updateUsuario($usuarioId, $data);
            echo json_encode(['success' => $result]);
        } else {
            error_log("PUT Endpoint no encontrado: $endpoint");
            http_response_code(404);
            echo json_encode(["error" => "Endpoint no encontrado: $endpoint"]);
        }
        break;
    case 'DELETE':
        if (preg_match('/^\/usuarios\/(\d+)$/', $endpoint, $matches)) {
            $usuarioId = $matches[1];
            $result = $usuarioObj->deleteUsuario($usuarioId);
            echo json_encode(['success' => $result]);
        } else {
            error_log("DELETE Endpoint no encontrado: $endpoint");
            http_response_code(404);
            echo json_encode(["error" => "Endpoint no encontrado: $endpoint"]);
        }
        break;
    default:
        error_log("Método no permitido: $method para endpoint: $endpoint");
        header('Allow: GET, POST, PUT, DELETE');
        http_response_code(405);
        echo json_encode(['error' => "Método no permitido: $method"]);
        break;
}
?>