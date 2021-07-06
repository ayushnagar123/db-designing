-- 1. (a) to insert a folder at root level
-- send name of folder,
-- parent folder id(NULL as to be added to root directory)
CALL CreateDirectoryFolder('folder in root', NULL); 

-- 1. (b) to insert a folder within a folder
-- send name of folder,
-- parent folder id(id of parent folder)
CALL CreateDirectoryFolder('sub folder', 1);

-- 1. (c) to insert a file at root level
-- send name of file, 
-- parent folder id(NULL as to be added to root directory), 
-- file size in bytes, file path(where file is stored in server), 
-- if image image width and height(here null as not image), 
-- extension of file(for txt 0 as text file) 
CALL CreateDirectoryFile('file in root', NULL, 2000, '/', NULL, NULL, 0);

-- 1. (d) to insert a file within a folder
-- send name of file, 
-- parent folder id(id of parent folder), 
-- file size in bytes, file path(where file is stored in server), 
-- if image image width and height(here null as not image), 
-- extension of file(for txt 0 as text file) 
CALL CreateDirectoryFile('file in sub folder', 1, 2000, '/sub folder', NULL, NULL, 0);

-- 1. (e) to insert a file within a folder
-- send name of file, 
-- parent folder id(id of parent folder), 
-- file size in bytes, file path(where file is stored in server), 
-- if image image width and height(in px), 
-- extension of file(for jpeg 1, for png 2) 
CALL CreateDirectoryFile('image in root', NULL, 2000, '/image in root.jpeg', 100, 200, 1);

-- 1. (f) to insert a file within a folder
-- send name of file, 
-- parent folder id(id of parent folder), 
-- file size in bytes, file path(where file is stored in server), 
-- if image image width and height(in px), 
-- extension of file(for txt 0 as text file) 
CALL CreateDirectoryFile('image in sub folder', 1, 2000, '/sub folder/image in sub folder.png', 100, 200, 2);


-- 2.(a) List all files and get in descending order of created at
SET @extension = NULL;
CALL ListFiles(@extension);

--2.(b) List all files and get in descending order of created at for perticular extension type
SET @extension = 1;
CALL ListFiles(@extension);

-- 3. delete any directory along with its child.
CALL TrashDirectories(1);

-- 7. update subfolder 2 to nested folder 2
-- directory id which is need to be renamed, new name of directory, extension of directory(null for folder, 0/1/2 in case of file)
CALL UpdateDirectoryName(2, 'nested folder 2', NULL);

-- Directory size
SET @size = 0; 
CALL DirectorySize(1, @size); 
SELECT @size;

-- Search all files and get in descending order of created at
SET @extension = NULL;
SET @name = 'd';  
CALL SearchFiles(@name, @extension);

-- Search all files and get in descending order of created at for perticular extension type
SET @extension = 1;
SET @name = 'd';  
CALL SearchFiles(@name, @extension);
