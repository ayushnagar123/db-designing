DELIMITER //
CREATE PROCEDURE CreateDirectoryFolder(
    directory_name varchar(50),
    directory_parent_id int
)
BEGIN
    INSERT INTO directories(name, type, parent_id) VALUES(directory_name, 0, directory_parent_id);
END; //

DELIMITER ;

DELIMITER //
CREATE PROCEDURE CreateDirectoryFile(
    directory_name varchar(50),
    directory_parent_id int,
    directory_file_size int,
    directory_file_path int,
    directory_image_width int,
    directory_image_height int,
    directory_extenstion int
)
BEGIN
    INSERT INTO directories(name, type, parent_id) VALUES(directory_name, 1, directory_parent_id);
    SET @directory_id = @@IDENTITY;
    INSERT INTO files(directory_id, extension, file_path, file_size) VALUES(@directory_id, directory_extension, directory_file_path, directory_file_size)
    SET @file_id = @@IDENTITY;
    CASE
        WHEN directory_extension = 1 OR directory_extension = 2 
            THEN 
            CALL CreateImage(@file_id, directory_image_height, directory_image_width)
        END
    END
END; //

DELIMITER ;

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

DELIMITER //
CREATE PROCEDURE UpdateDirectoryName(
    directory_id int,
    directory_name varchar(50),
    extention int
)
BEGIN
    UPDATE directories 
    SET directories.name = directory_name, directories.updated_at = CURRENT_TIMESTAMP
    if(extension is not NULL)
    BEGIN
        UPDATE files
        SET files.extension = extension, files.updated_at = CURRENT_TIMESTAMP
        WHERE files.directory_id = directory_id;
    END
END; //

DELIMITER ;

DELIMITER //

CREATE PROCEDURE DeleteDirectories(
    directory_ids int
)
BEGIN
    UPDATE directories 
    SET directories.status = 1, directories.updated_at = CURRENT_TIMESTAMP
    WHERE directory_id in directory_ids;
    SET @directory_ids = (SELECT id from directories WHERE parent_id = 1);
    CALL DeleteDirectories(@directory_ids);
END $$

DELIMITER //

CREATE FUNCTION DirectorySize( 
	directory_id INT, 
	size INT
) RETURNS INT
BEGIN
	DECLARE directory_size INT;
    DECLARE directory_ids VARCHAR(10000);
	DECLARE finished INT;
    
    DECLARE curFolder 
		CURSOR FOR 
			Select directories.id as id from directories WHERE directories.parent_id = directory_id;
	DECLARE CONTINUE HANDLER 
    FOR NOT FOUND SET finished = 1;
    
    IF(finished <> 1) THEN
    	SET finished = 0;
    END IF;
    SET directory_size = 0;
	SET directory_ids = "";
	
    OPEN curFolder;
    
    getFolder: LOOP
		FETCH curFolder INTO directory_ids;
		IF finished = 1 THEN 
			LEAVE getFolder;
		END IF;
		
		SET directory_size = 0;
		SET @directory_type = (Select type from directories WHERE id = directory_id LIMIT 1);
        SET @size = 0;
        IF(@directory_type = 1) THEN
            SET directory_size = (Select COALESCE(files.size, 0) as size from files WHERE files.directory_id = directory_id LIMIT 1);
		ELSE
            SET @files_size = (Select sum(COALESCE(files.file_size,0)) from files INNER JOIN directories d On d.id = files.directory_id  WHERE d.parent_id = files.directory_id GROUP BY d.parent_id);
		    SET directory_size = DirectorySize(directory_id, @size ) + @files_size + @size;
		END IF;
        	
	END LOOP getFolder;
	CLOSE curFolder;
    
	RETURN directory_size;
END; //

DELIMITER ; 


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


DELIMITER //

CREATE PROCEDURE SearchFiles(
    name varchar(100),
    extention int
)
BEGIN
    IF(extention IS NULL) THEN
    	SELECT * from files INNER JOIN directories d on d.id = files.directory_id WHERE ((d.name LIKE CONCAT('%', name,'%')) AND (files.extention IN (0,1,2))) ORDER BY files.created_at DESC;
    ELSE
    	SELECT * from files INNER JOIN directories d on d.id = files.directory_id WHERE ((d.name LIKE CONCAT('%', name,'%')) AND (files.extention = extension)) ORDER BY files.created_at DESC;
    END IF;
END; //
DELIMITER ; 
