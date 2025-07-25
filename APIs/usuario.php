<?php
/* Clase usuario para gestionar con API RESTful
 * Permite operaciones CRUD (Crear, Leer, Actualizar, Eliminar)
 * Requiere conexión a una base de datos MySQL
 */

// Configuracion del reporte de errores
error_reporting(E_ERROR | E_PARSE);
ini_set('display_errors', 0);

class Usuario
{
	private $conn;

	// Constructor que recibe la conexión a la base de datos
	public function __construct($conn)
	{
		$this->conn = $conn;
	}

	// Métodos para manejar usuarios
	// Obtener todos los usuarios
	public function getAllUsuarios()
	{
		$query = "SELECT * FROM usuario";
		$result = mysqli_query($this->conn, $query);
		$usuarios = [];
		while($row = mysqli_fetch_assoc($result)) {
			$usuarios[] = $row;
		}
		return $usuarios;
	}
	// Obtener un usuario por ID
	public function getUsuarioById($id)
	{
		$query = "SELECT * FROM usuario WHERE id = $id ";
		$result = mysqli_query($this->conn, $query);
		$usuario = mysqli_fetch_assoc($result);
		return $usuario;
	}
	// Agregar un nuevo usuario
	public function addUsuario($data)
	{
		if(!isset($data['usr_name']) || !isset($data['usr_email']) || !isset($data['usr_pass'])) {
			http_response_code(400);
			echo json_encode(["error" => "Datos incompletos"]);
		}else{
			$usr_name = $data['usr_name'];
			$usr_email = $data['usr_email'];
			$usr_pass = $data['usr_pass'];
			$query = "INSERT INTO persona (nombre, email, contrasena) 
				VALUES ('$usr_name', '$usr_email', '$usr_pass')";
			$result = mysqli_query($this->conn, $query);
			if($result){
				return true;
			} else {
				return false;
			}
		}
	}

	// Iniciar sesión de usuario
	public function loginUsuario($usr_email, $usr_pass)
	{
		//echo "email: $usr_email, pass: $usr_pass";
		$query = "SELECT * FROM persona WHERE email = '$usr_email'";
		$result = mysqli_query($this->conn, $query);
		if(mysqli_num_rows($result) > 0){
			$usuario = mysqli_fetch_assoc($result);
			if($usr_pass == $usuario['contrasena']){
				return $usuario; // Retorna el usuario si las credenciales son correctas
			} else {
				return false; // Contraseña incorrecta
			}
		} else {
			return false; // Usuario no encontrado
		}
	}

	// Actualizar un usuario por ID
	public function updateUsuario($id, $data)
	{
		$usr_name = $data['usr_name'];
		$usr_email = $data['usr_email'];
		$usr_pass = $data['usr_pass'];
		$query = "UPDATE usuario SET usr_name = '$usr_name', usr_email = '$usr_email', usr_pass = '$usr_pass' WHERE id = ".$id;
		$result = mysqli_query($this->conn, $query);
		if($result){
			return true;
		} else {
			return false;
		}
	}
	// Eliminar un usuario por ID
	public function deleteUsuario($id)
	{
		$query = "DELETE FROM usuario WHERE id = ".$id;
		$result = mysqli_query($this->conn, $query);
		if($result){
			return true;
		} else {
			return false;
		}
	}
}