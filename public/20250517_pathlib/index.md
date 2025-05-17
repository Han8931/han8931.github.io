# Rediscovering Python's Pathlib


## From Type Hint to Power Tool:  Python's `Pathlib`


For a long time, I used `Path` from Python's `pathlib` module purely as a **type hint** - a way to make function signatures look more modern and semantically clear. Like this:

```python
from pathlib import Path

def process_file(file_path: Path):
    ...
```
It changed when I started building an application that handled user-uploaded documents. I had to create temporary folders, write intermediate files, manage output paths, and ensure directories existed before saving results. That's when `Path` went from *just a type hint* to a core part of my file management logic.

## Why `pathlib` is Worth More than a Hint

Here are the use cases where it transformed my workflow:

### **Ensuring Directories Exist**

Before:

```python
import os

if not os.path.exists("output"):
    os.makedirs("output")
```

Now:

```python
from pathlib import Path

Path("output").mkdir(parents=True, exist_ok=True)
```
- `parents=True`: Creates any missing parent directories.
- `exist_ok=True`: Prevents an error if the directory already exists.
This is equivalent to os.makedirs(), but more cleaner and readable!

---

### **Managing Directories**

While handling temporary files for a file-processing API, I needed to:

* Create a temp folder
* Ensure it exists
* Write intermediate files
* Clean up afterward

With `Path`, this became natural and structured:

```python
from pathlib import Path

temp_dir = Path("/tmp/myapp") / "job123"
temp_dir.mkdir(parents=True, exist_ok=True)

output_file = temp_dir / "translated.txt"
output_file.write_text("Translated content")

content = output_file.read_text()

```
- `write_text(data: str)`: Writes a string to a text file (overwrites if it exists).
- `read_text()`: Reads file content and returns a string.

To cleanup the (temporary) directories:
```python
# Cleanup later if needed
output_file.unlink()
temp_dir.rmdir()
```
- `unlink`: Deletes a file
- `rmdir`: Removes an empty directory

You can use `unlink` with a parameter `missing_ok`:
- `Without missing_ok=True`: raises `FileNotFoundError` if the file doesn't exist.
- `With missing_ok=True`: silently does nothing if the file is already gone.


You can also check path status to avoid runtime errors:

```python
p = Path("result.txt")

p.exists()    # True if file or directory exists
p.is_file()   # True if it's a regular file
p.is_dir()    # True if it's a directory
```

To list directory contents:
```python
p = Path("my_folder")

for item in p.iterdir():
    print(item)
```

### Path Arithmetic

Joining paths becomes expressive with `/`:

```python
base = Path("/data")
file = base / "user" / "output.txt"
```

Compared to:

```python
file = os.path.join("/data", "user", "output.txt")
```


You can also extract name, stem, suffix (file extension) and so on:
```python
p = Path("/home/user/project/file.txt")

p.name      # 'file.txt'
p.stem      # 'file'
p.suffix    # '.txt'
p.parent    # PosixPath('/home/user/project')
p.parts     # ('/', 'home', 'user', 'project', 'file.txt')
```


