# Aim
To create a schema where we can store files in directory structure format which can have folder, sub folder and files either as image or text.

# DB diagram
https://dbdiagram.io/d/60e030d00b1d8a6d396518df

There are 3 tables needed:-
1. Directories
2. Files
3. Images

Note:-
* If parent_id is **NULL** means the folder/file lies in root directory.
* type of all folder is 0 which represent folder in db and files is 1.
* Both files and folders are considered as directory

# How folders are saved?
Folder's data are only stored in directories table. 
* To create folder in root directory
```
CALL CreateDirectoryFolder(
  <folder name>,
  NULL  // id of parent folder NULL => in root directory
); 
```

* To create folder as sub directory
```
CALL CreateDirectoryFolder(
  <folder name>, 
  <parent directory id>
); 
```

# How text files are stored?
Text files details are stored such that parent directory id is stored in directories table and other size and details are stored in files table using join.
* To create text file in root directory
```
CALL CreateDirectoryFile(
  <file basename>, NULL, 
  <file size in kb>, 
  <file path where it is stored originaly>, 
  NULL, // this is width of image in px if file type is image
  NULL, // this is height of image in px if file type is image
  0 // 0=> .txt, 1=> .jpeg, 2=> .png
);
```

* To create text file as sub directory
```
CALL CreateDirectoryFile(
  <file basename>, 
  <parent directory id>, 
  <file size in kb>, 
  <file path where it is stored originaly>, 
  NULL, // this is width of image in px if file type is image
  NULL, // this is height of image in px if file type is image
  0 // 0=> .txt, 1=> .jpeg, 2=> .png
);
```
# How image files are stored?
Image files details are stored such that parent directory id is stored in directories table, size and details are stored in files table while width and height of the files are stored in images table.
* To create text file in root directory
```
CALL CreateDirectoryFile(
  <file basename>, 
  NULL, 
  <file size in kb>, 
  <file path where it is stored originaly>, 
  <file path where it is stored originaly>, 
  <image width in px>, 
  <image height in px>, 
  1
);
```

* To create text file as sub directory
```
CALL CreateDirectoryFile(
  <file basename>, 
  <parent directory id>, 
  <file size in kb>, 
  <file path where it is stored originaly>, 
  <image width>, 
  <image height>, 
  1
);
```

# Rename a Directory
* To rename a Folder
```
CALL UpdateDirectoryName(
  <directory id whose name is to be updated>, 
  <new directory name>, 
  NULL // NULL in case of folder
);
```
* To rename a File
```
CALL UpdateDirectoryName(
  <directory id whose name is to be updated>, 
  <new directory name>, 
  <extention id> // 0=> .txt, 1=> .jpeg, 2=> .png
);
```

# Get directory size
To get directory size(file/folder)
```
SELECT DirectorySize(
  <directory id>, 
  0 // initial size
); 
```

# List all files
Get all in descending order of created at
```
CALL ListFiles(
  <extention> // NULL => for all type of files, 0 => .txt, 1=> .jpeg, 2=> .png 
);
```

# Search file by name
Search file by name and extention
```
CALL ListFiles(
  <search string for filename>, 
  <extention> // NULL => for all type of files, 0 => .txt, 1=> .jpeg, 2=> .png
);
```
