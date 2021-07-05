CREATE TABLE directories(
    id int NOT NULL AUTO_INCREMENT,
    created_at datetime DEFAULT CURRENT_TIMESTAMP,
    updated_at datetime DEFAULT CURRENT_TIMESTAMP,
    name varchar(50) NOT NULL,
    type int NOT NULL,
    parent_id int DEFAULT NULL,
    status int DEFAULT 0,
    PRIMARY KEY(id),
    CONSTRAINT sr_fk_parent_directory FOREIGN KEY(parent_id) REFERENCES directories(id) ON DELETE CASCADE
)

CREATE TABLE files(
    id int NOT NULL AUTO_INCREMENT,
    directory_id int NOT NULL,
    extention int,
    file_path varchar(30) NOT NULL,
    file_size int NOT NULL,
    created_at datetime DEFAULT CURRENT_TIMESTAMP,
    updated_at datetime DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY(id),
    CONSTRAINT sr_fk_file_directory FOREIGN KEY(directory_id) REFERENCES directories(id) ON DELETE CASCADE
)

CREATE TABLE images(
    id int NOT NULL AUTO_INCREMENT,
    file_id int NOT NULL,
    width  int NOT NULL,
    height int NOT NULL,
    PRIMARY KEY(id),
    CONSTRAINT sr_fk_image_file FOREIGN KEY(file_id) REFERENCES files(id) ON DELETE CASCADE
)