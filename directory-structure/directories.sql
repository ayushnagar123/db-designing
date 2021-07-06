-- To create folder at any path
DELIMITER //
CREATE PROCEDURE CreateDirectoryFolder(
    directory_name varchar(50),
    directory_parent_id int
)
BEGIN
    INSERT INTO directories(name, type, parent_id) VALUES(directory_name, 0, directory_parent_id);
END; //

DELIMITER ;

-- to create file at any path
DELIMITER //
CREATE PROCEDURE CreateDirectoryFile(
    directory_name varchar(50),
    directory_parent_id int,
    directory_file_size int,
    directory_file_path varchar(100),
    directory_image_width int,
    directory_image_height int,
    directory_extention int
)
BEGIN
    INSERT INTO directories(name, type, parent_id) VALUES(directory_name, 1, directory_parent_id);
    SET @directory_id = @@IDENTITY;
    INSERT INTO files(directory_id, extention, file_path, file_size) VALUES(@directory_id, directory_extention, directory_file_path, directory_file_size);
    SET @file_id = @@IDENTITY;
    IF(directory_extention = 1 OR directory_extention = 2) THEN 
        CALL CreateImage(@file_id, directory_image_height, directory_image_width);
    END IF;
END; //

DELIMITER ;

-- to create image at any path
DELIMITER //
CREATE PROCEDURE CreateImage(
    image_file_id int,
    image_height int,
    image_width int
)
BEGIN
    INSERT INTO images(file_id, height, width) VALUES(image_file_id, image_height, image_width)
END; //

DELIMITER ;

-- to update directory name(file or folder) at any path
DELIMITER //
CREATE PROCEDURE UpdateDirectoryName(
    directory_id int,
    directory_name varchar(50),
    extention int
)
BEGIN
    UPDATE directories 
    SET directories.name = directory_name, directories.updated_at = CURRENT_TIMESTAMP;

    IF(extention is not NULL) THEN
        UPDATE files
        SET files.extention = extention, files.updated_at = CURRENT_TIMESTAMP
        WHERE files.directory_id = directory_id;
    END IF;
END; //

DELIMITER ;

-- to trash directory(file or folder) at any path
DELIMITER //

DELIMITER //

CREATE PROCEDURE TrashDirectory(
    directory_id int
)
BEGIN
    DECLARE finished INT;
    DECLARE sub_folder_id INT;
    
    -- getting all child folders through cursor
    DECLARE curFolder 
		CURSOR FOR 
			Select directories.id as id from directories WHERE directories.parent_id = directory_id AND directories.type = 0;
	DECLARE CONTINUE HANDLER 
    FOR NOT FOUND SET finished = 1;

    SET @directory_type = (Select type from directories WHERE id = directory_id LIMIT 1);
    if(@directory_type = 1) THEN
        UPDATE directories
        SET directories.status = 1
        WHERE directories.id = directory_id;
    ELSE
        -- recursing to delete all child folders
        OPEN curFolder;
        folder_loop: WHILE(finished = 0) DO 
            FETCH curFolder INTO sub_folder_id;
        	CALL TrashDirectory(sub_folder_id);
        	IF(finished = 1) THEN
        		LEAVE folder_loop;
        	END IF;
        END WHILE folder_loop;

        -- trash all child files
        UPDATE directories
        SET directories.status = 1
        WHERE directories.parent_id = directory_id AND directories.type = 1;

        CLOSE curFolder;

        UPDATE directories
        SET directories.status = 1
        WHERE directories.id = directory_id;
    END IF;
END; //

DELIMITER ;

DELIMITER //

CREATE PROCEDURE RemoveDirectoryPermanently(
    directory_id int
)
BEGIN
    SET @directory_type = (SELECT directories.type FROM directories WHERE directories.id = directory_id  LIMIT 1);
    IF(@direcory_type = 1) THEN
        SELECT x.extention, x.id INTO @extention, @file_id FROM (SELECT files.extention, id FROM files INNER JOIN directories d on d.id = files.director_id WHERE d.id = directory_id LIMIT 1)x;
    	IF(@extention = 1 OR @extention = 2) THEN
    		DELETE FROM images WHERE images.file_id = @file_id;
    	END IF;
    	DELETE FROM files WHERE files.id = @file_id;
    END IF;
    DELETE FROM directories WHERE directories.id = directory_id;
END //

DELIMITER ;

DELIMITER //

CREATE PROCEDURE DeleteDirectory(
    directory_id int
)
BEGIN
    DECLARE finished INT;
    DECLARE sub_folder_id INT;
    
    -- getting all child folders through cursor
    DECLARE curFolder 
		CURSOR FOR 
			Select directories.id as id from directories WHERE directories.parent_id = directory_id AND directories.type = 0;
	DECLARE CONTINUE HANDLER 
    FOR NOT FOUND SET finished = 1;

    SET @directory_type = (Select type from directories WHERE id = directory_id LIMIT 1);
    if(@directory_type = 1) THEN
        UPDATE directories
        SET directories.status = 1
        WHERE directories.id = directory_id;
    ELSE
        -- recursing to delete all child folders
        OPEN curFolder;
        folder_loop: WHILE(finished = 0) DO 
            FETCH curFolder INTO sub_folder_id;
        	CALL DeleteDirectory(sub_folder_id);
        	IF(finished = 1) THEN
        		LEAVE folder_loop;
        	END IF;
        END WHILE folder_loop;

        CLOSE curFolder;

        CALL RemoveDirectoryPermanently(directory_id);
    END IF;
END; //

DELIMITER ;

-- To get directory(file or folder size) at any path
DELIMITER //
CREATE DEFINER=`root`@`localhost` FUNCTION `DirectorySize`( 
	directory_id INT, 
	size INT
) RETURNS int(11)
BEGIN
    DECLARE finished INT;
    DECLARE sub_folder_id INT;
    
    -- getting all child folders through cursor
    DECLARE curFolder 
		CURSOR FOR 
			Select directories.id as id from directories WHERE directories.parent_id = directory_id;
	DECLARE CONTINUE HANDLER 
    FOR NOT FOUND SET finished = 1;
    
    SET @size = (SELECT COALESCE(size, 0));
    
    SET @directory_type = (Select directories.type from directories WHERE id = directory_id LIMIT 1);
    IF(@directory_type = 1) THEN
        SET @size = (SELECT files.file_size from files WHERE files.directory_id = directory_id LIMIT 1);
    ELSE
        -- recursing to delete all child folders
        OPEN curFolder;
        folder_loop: WHILE(finished = 0) DO 
            FETCH curFolder INTO sub_folder_id;
            SET @size_of_folder = (SELECT DirectorySize(sub_folder_id, 0));
            SET @size = (@size + @size_of_folder);
            IF(finished = 1) THEN
        		LEAVE folder_loop;
        	END IF;
        END WHILE folder_loop;

        CLOSE curFolder;
    END IF;


    SET size = @size;
    RETURN size;
END; //

DELIMITER ;


-- list files in latest created order(with or without perticular extention)
DELIMITER //

CREATE PROCEDURE ListFiles(
    extention int
)
BEGIN
    IF(extention IS NULL) THEN
    	SELECT * from files WHERE files.extention IN (0,1,2) ORDER BY files.created_at DESC;
    ELSE
    	SELECT * from files WHERE files.extention = extention ORDER BY files.created_at DESC;
    END IF;
END; //

DELIMITER ; 

-- Search files in latest created order(with or without perticular extention)
DELIMITER //

CREATE PROCEDURE SearchFiles(
    name varchar(100),
    extention int
)
BEGIN
    IF(extention IS NULL) THEN
    	SELECT * from files INNER JOIN directories d on d.id = files.directory_id WHERE ((d.name LIKE CONCAT('%', name,'%')) AND (files.extention IN (0,1,2))) ORDER BY files.created_at DESC;
    ELSE
    	SELECT * from files INNER JOIN directories d on d.id = files.directory_id WHERE ((d.name LIKE CONCAT('%', name,'%')) AND (files.extention = extention)) ORDER BY files.created_at DESC;
    END IF;
END; //
DELIMITER ; 
