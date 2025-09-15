CREATE DATABASE cooperativa_capicorp;
USE cooperativa_capicorp;

CREATE TABLE Persona (
    id_persona INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
    contrasena VARCHAR(255) NOT NULL,
    nombre_completo VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL
);

CREATE TABLE Usuario (
    id_persona INT PRIMARY KEY NOT NULL,
    estado_acceso VARCHAR(255) NOT NULL,
    FOREIGN KEY (id_persona) REFERENCES Persona(id_persona)
);

CREATE TABLE Unidad_habitacional (
    id_unidad INT PRIMARY KEY NOT NULL,
    direccion VARCHAR(255) NOT NULL,
    estado_asignacion VARCHAR(255) NOT NULL
);

CREATE TABLE Registro_horas (
    id_registro INT PRIMARY KEY NOT NULL,
    id_persona INT NOT NULL,
    horas_registradas INT NOT NULL,
    semana VARCHAR(255) NOT NULL,
    FOREIGN KEY (id_persona) REFERENCES Usuario(id_persona)
);

CREATE TABLE Pago (
    id_pago INT PRIMARY KEY NOT NULL,
    mes VARCHAR(255) NOT NULL,
    monto DECIMAL(10, 2) NOT NULL,
    estado_aprobacion VARCHAR(255) NOT NULL,
    archivo_comprobante VARCHAR(255) NOT NULL,
    id_persona INT NOT NULL,
    inicial INT NOT NULL,
    FOREIGN KEY (id_persona) REFERENCES Usuario(id_persona)
);

CREATE TABLE Administrador (
    id_admin INT PRIMARY KEY NOT NULL,
    nombre VARCHAR(255) NOT NULL,
    apellidos VARCHAR(255) NOT NULL,
    rol VARCHAR(255) NOT NULL,
    contraseña VARCHAR(255) NOT NULL,
    correo_electronico VARCHAR(255) NOT NULL
);

CREATE TABLE Pago_Compensatorio (
    id_pago_compensatorio INT PRIMARY KEY NOT NULL,
    id_persona INT NOT NULL,
    monto DECIMAL(10, 2) NOT NULL,
    semana VARCHAR(255) NOT NULL,
    archivo_comprobante VARCHAR(255) NOT NULL,
    FOREIGN KEY (id_persona) REFERENCES Usuario(id_persona)
);

CREATE TABLE Se_asigna (
    id_unidad INT PRIMARY KEY NOT NULL,
    id_persona INT UNIQUE NOT NULL,
    FOREIGN KEY (id_unidad) REFERENCES Unidad_habitacional(id_unidad),
    FOREIGN KEY (id_persona) REFERENCES Usuario(id_persona)
);

INSERT INTO Unidad_habitacional (id_unidad, direccion, estado_asignacion) VALUES
(101, 'Puerta 101', 'disponible'),
(102, 'Puerta 102', 'disponible'),
(103, 'Puerta 103', 'disponible'),
(104, 'Puerta 104', 'disponible'),
(105, 'Puerta 105', 'disponible'),
(106, 'Puerta 106', 'disponible'),
(107, 'Puerta 107', 'disponible'),
(108, 'Puerta 108', 'disponible'),
(109, 'Puerta 109', 'disponible'),
(201, 'Puerta 201', 'disponible'),
(202, 'Puerta 202', 'disponible'),
(203, 'Puerta 203', 'disponible'),
(204, 'Puerta 204', 'disponible'),
(205, 'Puerta 205', 'disponible'),
(206, 'Puerta 206', 'disponible'),
(207, 'Puerta 207', 'disponible'),
(208, 'Puerta 208', 'disponible'),
(209, 'Puerta 209', 'disponible'),
(301, 'Puerta 301', 'disponible'),
(302, 'Puerta 302', 'disponible'),
(303, 'Puerta 303', 'disponible'),
(304, 'Puerta 304', 'disponible'),
(305, 'Puerta 305', 'disponible'),
(306, 'Puerta 306', 'disponible'),
(307, 'Puerta 307', 'disponible'),
(308, 'Puerta 308', 'disponible'),
(309, 'Puerta 309', 'disponible'),
(401, 'Puerta 401', 'disponible'),
(402, 'Puerta 402', 'disponible'),
(403, 'Puerta 403', 'disponible'),
(404, 'Puerta 404', 'disponible'),
(405, 'Puerta 405', 'disponible'),
(406, 'Puerta 406', 'disponible'),
(407, 'Puerta 407', 'disponible'),
(408, 'Puerta 408', 'disponible'),
(409, 'Puerta 409', 'disponible'),
(501, 'Puerta 501', 'disponible'),
(502, 'Puerta 502', 'disponible'),
(503, 'Puerta 503', 'disponible'),
(504, 'Puerta 504', 'disponible'),
(505, 'Puerta 505', 'disponible'),
(506, 'Puerta 506', 'disponible'),
(507, 'Puerta 507', 'disponible'),
(508, 'Puerta 508', 'disponible'),
(509, 'Puerta 509', 'disponible'),
(601, 'Puerta 601', 'disponible'),
(602, 'Puerta 602', 'disponible'),
(603, 'Puerta 603', 'disponible'),
(604, 'Puerta 604', 'disponible'),
(605, 'Puerta 605', 'disponible'),
(606, 'Puerta 606', 'disponible'),
(607, 'Puerta 607', 'disponible'),
(608, 'Puerta 608', 'disponible'),
(609, 'Puerta 609', 'disponible'),
(701, 'Puerta 701', 'disponible'),
(702, 'Puerta 702', 'disponible'),
(703, 'Puerta 703', 'disponible'),
(704, 'Puerta 704', 'disponible'),
(705, 'Puerta 705', 'disponible'),
(706, 'Puerta 706', 'disponible'),
(707, 'Puerta 707', 'disponible'),
(708, 'Puerta 708', 'disponible'),
(709, 'Puerta 709', 'disponible'),
(801, 'Puerta 801', 'disponible'),
(802, 'Puerta 802', 'disponible'),
(803, 'Puerta 803', 'disponible'),
(804, 'Puerta 804', 'disponible'),
(805, 'Puerta 805', 'disponible'),
(806, 'Puerta 806', 'disponible'),
(807, 'Puerta 807', 'disponible'),
(808, 'Puerta 808', 'disponible'),
(809, 'Puerta 809', 'disponible'),
(901, 'Puerta 901', 'disponible'),
(902, 'Puerta 902', 'disponible'),
(903, 'Puerta 903', 'disponible'),
(904, 'Puerta 904', 'disponible'),
(905, 'Puerta 905', 'disponible'),
(906, 'Puerta 906', 'disponible'),
(907, 'Puerta 907', 'disponible'),
(908, 'Puerta 908', 'disponible'),
(909, 'Puerta 909', 'disponible'),
(1001, 'Puerta 1001', 'disponible'),
(1002, 'Puerta 1002', 'disponible'),
(1003, 'Puerta 1003', 'disponible'),
(1004, 'Puerta 1004', 'disponible'),
(1005, 'Puerta 1005', 'disponible'),
(1006, 'Puerta 1006', 'disponible'),
(1007, 'Puerta 1007', 'disponible'),
(1008, 'Puerta 1008', 'disponible'),
(1009, 'Puerta 1009', 'disponible');