<?php
/* API RESTful para gestionar usuarios
 * Permite operaciones CRUD (Crear, Leer, Actualizar, Eliminar)
 * Requiere conexión a una base de datos MySQL
 */

// Importa las dependencias necesarias
require_once 'config.php';
require_once 'usuario.php';

// Crea la instance de la clase Usuario
$usuarioObj = new Usuario($conn);
// Obtiene el método de la solicitud HTTP
$method = $_SERVER['REQUEST_METHOD'];
// Obtiene el endpoint de la solicitud
$endpoint = $_SERVER['PATH_INFO'];

// Establece el tipo de contenido de la respuesta
header('Content-Type: application/json; charset=utf-8');

// Maneja la solicitud según el método HTTP
switch ($method) {
	case 'GET':
		if($endpoint === '/usuarios'){
			// Obtiene todos los usuarios
			$usuarios = $usuarioObj->getAllUsuarios();
			echo json_encode($usuarios);
		} elseif (preg_match('/^\/usuarios\/(\d+)$/', $endpoint, $matches)) {
			// Obtiene un usuario por ID
			$usuarioId = $matches[1];
			$usuario = $usuarioObj->getUsuarioById($usuarioId);
			echo json_encode($usuario);
		} else {
			http_response_code(404);
			echo json_encode(['error' => 'Endpoint no encontrado']);
		}
		break;

	case 'POST':
		$input = file_get_contents('php://input');
		$data = json_decode($input, true);

		if($endpoint === '/usuarios'){
			if(isset($data['usr_name']) && isset($data['usr_email']) && isset($data['usr_pass'])){
				$result = $usuarioObj->createUsuario($data['usr_name'], $data['usr_email'], $data['usr_pass']);
				if($result){
					echo json_encode(['success' => true]);
				} else {
					echo json_encode(['success' => false]);
				}
			} else {
				echo json_encode(['error' => 'Datos incompletos o error al registrar usuario']);
			}
		}elseif ($endpoint === '/login') {
			$result = $usuarioObj->loginUsuario($data['usr_email'], $data['usr_pass']);
			if($result){
				echo json_encode(['success' => true, 'user' => $result]);
			} else {
				echo json_encode(['success' => false, 'message' => 'Credenciales inválidas']);
			}
		} else {
			http_response_code(404);
			echo json_encode(['error' => 'Endpoint no encontrado']);
		}
		break;

	case 'PUT':
		parse_str(file_get_contents('php://input'), $data);
		if (preg_match('/^\/usuarios\/(\d+)$/', $endpoint, $matches)) {
			$usuarioId = $matches[1];
			$result = $usuarioObj->updateUsuario($usuarioId, $data);
			echo json_encode(['success' => $result]);
		}
		break;

	case 'DELETE':
		if (preg_match('/^\/usuarios\/(\d+)$/', $endpoint, $matches)) {
			// Elimina un usuario por ID
			$usuarioId = $matches[1];
			$result = $usuarioObj->deleteUsuario($usuarioId);
			echo json_encode(['success' => $result]);
		}
		break;
	default:
		// Maneja métodos no permitidos
		header('Allow: GET, POST, PUT, DELETE');
		http_response_code(405);
		echo json_encode(['error' => 'Método no permitido']);
		break;
}
?>
