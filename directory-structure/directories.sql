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
    IF(directory_extension = 1 OR directory_extension = 2) THEN 
        CALL CreateImage(@file_id, directory_image_height, directory_image_width)
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
    SET directories.name = directory_name, directories.updated_at = CURRENT_TIMESTAMP
    IF(extension is not NULL) THEN
        UPDATE files
        SET files.extension = extension, files.updated_at = CURRENT_TIMESTAMP
        WHERE files.directory_id = directory_id;
    END IF;
END; //

DELIMITER ;

-- to trash directory(file or folder) at any path
DELIMITER //

CREATE PROCEDURE TrashDirectory(
    directory_id int
)
BEGIN
    DECLARE finished INT;
    
    -- getting all child folders through cursor
    DECLARE curFolder 
		CURSOR FOR 
			Select directories.id as id from directories WHERE directories.parent_id = directory_id AND directories.type = 0;
	DECLARE CONTINUE HANDLER 
    FOR NOT FOUND SET finished = 1;

    SET @directory_type = (Select type from directories WHERE id = directory_id LIMIT 1);
    if(@directory_type == 1) THEN
        UPDATE directories
        SET directories.status = 1
        WHERE directory_id in directory_ids;
    ELSE
        -- recursing to delete all child folders
        FOR sub_folder IN curFolder
        LOOP
            CALL TrashDirectory(sub_folder.id);
        END LOOP;

        -- deleting all child files
        UPDATE directories
        SET directories.status = 1
        WHERE directories.parent_id = directory_id AND directories.type = 1;

        CLOSE curFolder;

        UPDATE directories
        SET directories.status = 1
        WHERE directories.id = directory_id;
    END IF;
END $$

DELIMITER //

CREATE PROCEDURE DeleteDirectory(
    directory_id int
)
BEGIN
    DECLARE finished INT;
    
    -- getting all child folders through cursor
    DECLARE curFolder 
		CURSOR FOR 
			Select directories.id as id from directories WHERE directories.parent_id = directory_id AND directories.type = 0;
	DECLARE CONTINUE HANDLER 
    FOR NOT FOUND SET finished = 1;

    SET @directory_type = (Select type from directories WHERE id = directory_id LIMIT 1);
    if(@directory_type == 1) THEN
        UPDATE directories
        SET directories.status = 1
        WHERE directory_id in directory_ids;
    ELSE
        -- recursing to delete all child folders
        FOR sub_folder IN curFolder
        LOOP
            CALL DeleteDirectory(sub_folder.id);
        END LOOP;

        -- deleting all child files
        DELETE directories
        WHERE directories.parent_id = directory_id AND directories.type = 1;

        CLOSE curFolder;
    END IF;
END $$

-- To get directory(file or folder size) at any path
CREATE FUNCTION DirectorySize( 
	directory_id INT, 
	size INT
) RETURNS INT
BEGIN
    DECLARE finished INT;
    
    -- getting all child folders through cursor
    DECLARE curFolder 
		CURSOR FOR 
			Select directories.id as id from directories WHERE directories.parent_id = directory_id;
	DECLARE CONTINUE HANDLER 
    FOR NOT FOUND SET finished = 1;
    
    SET @size = (SELECT COALESCE(size, 0));
    
    IF(finished == 0) THEN
        SET @directory_type = (Select type from directories WHERE id = directory_id LIMIT 1);
        if(@directory_type == 1) THEN
            @size = (SELECT files.size as size from files WHERE files.directoty_id = directory_id LIMIT);
        ELSE
            -- recursing to find size of all child folders
            FOR sub_folder IN curFolder
            LOOP
                @size = @size + CALL DirectorySize(sub_folder.id, size);
            END LOOP;

            CLOSE curFolder;
        END IF;
    END IF;
    size = @size;
    RETURN size;
	-- DECLARE directory_size INT;
    -- DECLARE directory_ids VARCHAR(10000);
	-- DECLARE finished INT;
    
    -- DECLARE curFolder 
	-- 	CURSOR FOR 
	-- 		Select directories.id as id from directories WHERE directories.parent_id = directory_id;
	-- DECLARE CONTINUE HANDLER 
    -- FOR NOT FOUND SET finished = 1;
    
    -- IF(finished <> 1) THEN
    -- 	SET finished = 0;
    -- END IF;

    -- SET directory_size = 0;
	-- SET directory_ids = "";
	
    -- OPEN curFolder;
    
    -- getFolder: LOOP
	-- 	FETCH curFolder INTO directory_ids;
	-- 	IF finished = 1 THEN 
	-- 		LEAVE getFolder;
	-- 	END IF;
		
	-- 	SET directory_size = 0;
	-- 	SET @directory_type = (Select type from directories WHERE id = directory_id LIMIT 1);
    --     SET @size = 0;
    --     IF(@directory_type = 1) THEN
    --         SET directory_size = (Select COALESCE(files.size, 0) as size from files WHERE files.directory_id = directory_id LIMIT 1);
	-- 	ELSE
    --         SET @files_size = (Select sum(COALESCE(files.file_size,0)) from files INNER JOIN directories d On d.id = files.directory_id  WHERE d.parent_id = files.directory_id GROUP BY d.parent_id);
	-- 	    SET directory_size = DirectorySize(directory_id, @size ) + @files_size + @size;
	-- 	END IF;
        	
	-- END LOOP getFolder;
	-- CLOSE curFolder;
    
	-- RETURN directory_size;
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
    	SELECT * from files INNER JOIN directories d on d.id = files.directory_id WHERE ((d.name LIKE CONCAT('%', name,'%')) AND (files.extention = extension)) ORDER BY files.created_at DESC;
    END IF;
END; //
DELIMITER ; 
