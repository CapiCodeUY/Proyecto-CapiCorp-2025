CREATE DATABASE cooperativa_capicorp;
USE cooperativa_capicorp;

CREATE TABLE Persona (
    id_persona INT PRIMARY KEY NOT NULL,
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
