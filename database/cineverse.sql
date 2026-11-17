-- =====================================================================
-- Cineverse · Script de creación de la base de datos (MySQL 8 / MariaDB)
-- Uso:  mysql -u root -p < cineverse.sql      (o pegarlo en phpMyAdmin → SQL)
-- Nota: la API también crea estas tablas sola al iniciar (migrar.py);
--       este script sirve para crearlas a mano y como documentación.
-- =====================================================================

CREATE DATABASE IF NOT EXISTS cineverse
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE cineverse;

-- Usuarios (tip_usu: 1 = administrador, 2 = usuario general).
-- La contraseña NUNCA se guarda en claro: `pass` contiene el hash argon2.
CREATE TABLE IF NOT EXISTS usuario (
  id_usr   INT AUTO_INCREMENT PRIMARY KEY,
  nom_usr  VARCHAR(100) NOT NULL,
  mail     VARCHAR(150) NOT NULL UNIQUE,
  `pass`   VARCHAR(255) NOT NULL,
  dir_usr  VARCHAR(200) NULL,
  tip_usu  INT NOT NULL DEFAULT 2,
  INDEX idx_usuario_id (id_usr)
) ENGINE=InnoDB;

-- Publicaciones: reseñas de películas, series y artículos.
CREATE TABLE IF NOT EXISTS blog (
  id_blog    INT AUTO_INCREMENT PRIMARY KEY,
  titulo     VARCHAR(150) NOT NULL,
  `desc`     TEXT NULL,
  img        VARCHAR(500) NULL,
  tags       VARCHAR(255) NULL,
  tipo       VARCHAR(20)  NOT NULL DEFAULT 'articulo',  -- pelicula | serie | articulo
  genero     VARCHAR(60)  NULL,
  anio       INT NULL,
  usr_id     INT NULL,                                  -- autor
  fecha      DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  destacado  INT NOT NULL DEFAULT 0,
  INDEX idx_blog_id (id_blog)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS comentarios (
  id_com      INT AUTO_INCREMENT PRIMARY KEY,
  comentario  TEXT NOT NULL,
  fecha       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  estatus     INT NOT NULL DEFAULT 1,
  usr_id      INT NOT NULL,
  blog_id     INT NOT NULL,
  INDEX idx_com_id (id_com),
  CONSTRAINT fk_com_usuario FOREIGN KEY (usr_id)  REFERENCES usuario (id_usr),
  CONSTRAINT fk_com_blog    FOREIGN KEY (blog_id) REFERENCES blog (id_blog)
) ENGINE=InnoDB;

-- Valoración de 1 a 5 estrellas (una por usuario y publicación).
CREATE TABLE IF NOT EXISTS valoraciones (
  id       INT AUTO_INCREMENT PRIMARY KEY,
  blog_id  INT NOT NULL,
  usr_id   INT NOT NULL,
  puntos   INT NOT NULL,
  fecha    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_valoracion (blog_id, usr_id),
  INDEX idx_val_blog (blog_id),
  CONSTRAINT fk_val_blog    FOREIGN KEY (blog_id) REFERENCES blog (id_blog),
  CONSTRAINT fk_val_usuario FOREIGN KEY (usr_id)  REFERENCES usuario (id_usr)
) ENGINE=InnoDB;

-- Reacciones con emoji a comentarios (una por usuario y comentario).
CREATE TABLE IF NOT EXISTS reacciones (
  id      INT AUTO_INCREMENT PRIMARY KEY,
  com_id  INT NOT NULL,
  usr_id  INT NOT NULL,
  tipo    VARCHAR(20) NOT NULL,                         -- like | love | fire | wow | sad
  UNIQUE KEY uq_reaccion (com_id, usr_id),
  INDEX idx_reac_com (com_id),
  CONSTRAINT fk_reac_com     FOREIGN KEY (com_id) REFERENCES comentarios (id_com),
  CONSTRAINT fk_reac_usuario FOREIGN KEY (usr_id) REFERENCES usuario (id_usr)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS guardados (
  id       INT AUTO_INCREMENT PRIMARY KEY,
  blog_id  INT NOT NULL,
  usr_id   INT NOT NULL,
  UNIQUE KEY uq_guardado (blog_id, usr_id),
  INDEX idx_guard_blog (blog_id),
  CONSTRAINT fk_guard_blog    FOREIGN KEY (blog_id) REFERENCES blog (id_blog),
  CONSTRAINT fk_guard_usuario FOREIGN KEY (usr_id)  REFERENCES usuario (id_usr)
) ENGINE=InnoDB;

-- Avisos de la campana.
CREATE TABLE IF NOT EXISTS notificaciones (
  id        INT AUTO_INCREMENT PRIMARY KEY,
  usr_id    INT NOT NULL,                               -- quien la recibe
  actor_id  INT NULL,                                   -- quien la provocó
  tipo      VARCHAR(20)  NOT NULL,                      -- comentario | reaccion | valoracion
  blog_id   INT NULL,
  ref_id    INT NULL,
  texto     VARCHAR(300) NOT NULL,
  fecha     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  leida     INT NOT NULL DEFAULT 0,
  INDEX idx_notif_usr (usr_id),
  INDEX idx_notif_blog (blog_id)
) ENGINE=InnoDB;

-- Códigos para restablecer contraseña (se guarda el hash, nunca el código).
CREATE TABLE IF NOT EXISTS recuperaciones (
  id           INT AUTO_INCREMENT PRIMARY KEY,
  usr_id       INT NOT NULL,
  codigo_hash  VARCHAR(64) NOT NULL,
  expira       DATETIME NOT NULL,
  intentos     INT NOT NULL DEFAULT 0,
  INDEX idx_rec_usr (usr_id)
) ENGINE=InnoDB;

-- Primer administrador: regístrate en la app y luego ejecuta (con tu correo):
-- UPDATE usuario SET tip_usu = 1 WHERE mail = 'tu_correo@ejemplo.com';