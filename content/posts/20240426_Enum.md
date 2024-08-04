---
weight: 1
title: Enumerate variables with Enum!
date: 2024-04-26
draft: false
author: Han
description: A tutorial for Enum 
tags: ["Python", "Enum"]
categories: ["Python"]
---

`Enum` is a way that Python enumerate variables. The `enum` module allows for the creation of enumerated constants—unique, immutable data types that are useful for representing a fixed set of values. These values, which are usually related by their context, are known as enumeration members.

Enum provides...
1. **Uniqueness** - Each member of an `Enum` is unique within its definition, meaning no two members can have the same value. Attempting to define two members with the same value will result in an error unless you explicitly allow aliases.
2. **Immutability** - Enum members are immutable. Once the `Enum` class is defined, you cannot change the members or their values.
3. **Iterability and Comparability** - Enum classes support iteration over their members and can be compared using identity and equality checks.
4. **Accessing Members** - You can access enumeration members by their names or values:
5. **Auto** - If you want to automatically assign values to enum members, you can use the `auto()` function from the same module:

```python
from enum import Enum

class State(Enum):
	PLAYING=0
	PAUSED=1
	GAME_OVER=2
```

If we just want to make sure them to be unique and automatically assigned, then use `auto()`
```python
from enum import Enum, auto

class State(Enum):
	PLAYING=auto()
	PAUSED=auto()
	GAME_OVER=auto()

print(State.PLAYING)
print(State.PLAYING.value)
```

Or simply, 

```python
from enum import Enum, auto

class State(Enum):
	PLAYING, PAUSED, GAME_OVER=range(3)

print(State.PLAYING)
print(State.PLAYING.value)
```
- However, this hard codes numbers, which can create an issue in the future.  

### Iterating over Enum Members

You can iterate over the members of an enum:

```python
for state in State:
    print(state)
```

### Comparison of Enum Members

Enum members are singleton objects, so comparison is possible by identity:

```python
if State.PLAYING is State.PLAYING:
    print("RED is indeed RED")
```

### Using Enum as a Type Hint

Enums can be used as type hints, enhancing code readability and correctness:
```python
def paint(color: Color):
    print(f"Painting with {color.name}")
```

### Extending Enums: IntEnum and StrEnum

For enums where the members are specifically integers or strings, you can inherit from `IntEnum` or `StrEnum` for additional benefits, like being able to compare members to integers or strings directly.

```python
from enum import IntEnum

class Priority(IntEnum):
    LOW = 1
    MEDIUM = 2
    HIGH = 3

# Direct comparison with integers
if Priority.LOW < Priority.HIGH:
    print("Low priority is less than high")
```

### Unique Constraint

To ensure that all enum values are unique, you can use the `@unique` decorator:

```python
from enum import Enum, unique

@unique
class StatusCode(Enum):
    OK = 200
    NOT_FOUND = 404
    ERROR = 500
```

Using `@unique` will raise a `ValueError` if any duplicate values are detected.

### Conclusion

Enums in Python are useful for defining sets of named constants that are related and have a fixed set of members. They improve code readability, prevent errors related to using incorrect literal values, and can simplify type checking and validation in your programs.
