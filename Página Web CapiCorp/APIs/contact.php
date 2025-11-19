<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

$data = json_decode(file_get_contents('php://input'), true);

if (!isset($data['name']) || !isset($data['email']) || !isset($data['message']) || !isset($data['g-recaptcha-response'])) {
    http_response_code(400);
    echo json_encode(['error' => 'Datos incompletos']);
    exit;
}

$name = $data['name'];
$email = $data['email'];
$message = $data['message'];
$token = $data['g-recaptcha-response'];

$secret = 'TU_SECRETKEY_AQUI';
$response = file_get_contents("https://www.google.com/recaptcha/api/siteverify?secret=$secret&response=$token");
$response = json_decode($response, true);
if (!$response['success'] || $response['score'] < 0.5) {
    http_response_code(400);
    echo json_encode(['error' => 'CAPTCHA inválido']);
    exit;
}

$toEmail = 'capicode2025@gmail.com';
$subject = 'Nuevo mensaje de contacto desde CapiCorp';
$body = "Nombre: $name\nEmail: $email\nMensaje: $message";
$headers = "From: $email";

if (mail($toEmail, $subject, $body, $headers)) {
    echo json_encode(['success' => true]);
} else {
    http_response_code(500);
    echo json_encode(['error' => 'Error al enviar el email']);
}
?>