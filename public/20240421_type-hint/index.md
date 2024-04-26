# Type hint in Python



Type hinting is _not mandatory_, but it can make your code easier to understand and debug by 
1. Improved readability
2. Better IDE support: IDEs and linters can use type hints to check your code for potential errors before runtime. 

While type hints can be simple classes like [`float`](https://docs.python.org/3/library/functions.html#float "float") or [`str`](https://docs.python.org/3/library/stdtypes.html#str "str"), they can also be more complex. The [`typing`](https://docs.python.org/3/library/typing.html#module-typing "typing: Support for type hints (see :pep:`484`).") module provides a vocabulary of more advanced type hints.


### Basics

```python
# This is how you declare the type of a variable
age: int = 1

# You don't need to initialize a variable to annotate it
a: int  # Ok (no value at runtime until assigned)

# Doing so can be useful in conditional branches
child: bool
if age < 18:
    child = True
else:
    child = False
```

```python
x: int = 1
x: float = 1.0
x: bool = True
x: str = "test"
x: bytes = b"test"

# For collections on Python 3.9+, the type of the collection item is in brackets
x: list[int] = [1]
x: set[int] = {6, 7}

# For mappings, we need the types of both keys and values
x: dict[str, float] = {"field": 2.0}  # Python 3.9+

# For tuples of fixed size, we specify the types of all the elements
x: tuple[int, str, float] = (3, "yes", 7.5)  # Python 3.9+

# For tuples of variable size, we use one type and ellipsis
x: tuple[int, ...] = (1, 2, 3)  # Python 3.9+
```


```python
# On Python 3.8 and earlier, the name of the collection type is
# capitalized, and the type is imported from the 'typing' module
from typing import List, Set, Dict, Tuple
x: List[int] = [1]
x: Set[int] = {6, 7}
x: Dict[str, float] = {"field": 2.0}
x: Tuple[int, str, float] = (3, "yes", 7.5)
x: Tuple[int, ...] = (1, 2, 3)

```

### Union 

`Union` is for multiple types
```python
def process_message(msg: Union[str, bytes, None]) -> str:
	...

# On Python 3.10+, use the | operator when something could be one of a few types
x: list[int | str] = [3, 5, "test", "fun"]  # Python 3.10+
# On earlier versions, use Union
x: list[Union[int, str]] = [3, 5, "test", "fun"]
```
### Optional 
```python
# food can be either str or None.
def eat_food(food: Optional[str]) -> None:
	...

# Use Optional[X] for a value that could be None
# Optional[X] is the same as X | None or Union[X, None]
x: Optional[str] = "something" if some_condition() else None
if x is not None:
    # Mypy understands x won't be None here because of the if-statement
    print(x.upper())
# If you know a value can never be None due to some logic that mypy doesn't
# understand, use an assert
assert x is not None
print(x.upper())
```

### Any
- `Any` is a special type hint in Python that indicates that a variable can be of any type. It essentially _disables static type checking for that variable_.
- It's typically used when you want to explicitly indicate that a certain variable can have any type, or when dealing with dynamically typed code where the type of the variable cannot be easily inferred.
- While `Any` provides flexibility, it also sacrifices the benefits of static type checking, as type errors related to variables annotated as `Any` won't be caught by type checkers.

### Functions: Callable Types

Callable type hint can define types for callable functions.
```python
from typing import Callable
Callable[[Parameter types, ...], return_types] 
```
- Callable objects are functions, classes, and so on. 
- Type `[input types]` and return types

```python
def on_some_event_happened(callback: Callable[[int, str, str], int]) -> None:
    ...

def do_this(a: int, b: str, c:str) -> int:
    ...

on_some_event_happened(do_this)

# This is how you annotate a callable (function) value
x: Callable[[int, float], float] = f
def register(callback: Callable[[str], int]) -> None: 
	...

# A generator function that yields ints is secretly just a function that
# returns an iterator of ints, so that's how we annotate it
def gen(n: int) -> Iterator[int]:
    i = 0
    while i < n:
        yield i
        i += 1

# You can of course split a function annotation over multiple lines
def send_email(address: Union[str, list[str]],
               sender: str,
               cc: Optional[list[str]],
               bcc: Optional[list[str]],
               subject: str = '',
               body: Optional[list[str]] = None
               ) -> bool:
    ...
```

### Classes

```python
class BankAccount:
    # The "__init__" method doesn't return anything, so it gets return
    # type "None" just like any other method that doesn't return anything
    def __init__(self, account_name: str, initial_balance: int = 0) -> None:
        # mypy will infer the correct types for these instance variables
        # based on the types of the parameters.
        self.account_name = account_name
        self.balance = initial_balance

    # For instance methods, omit type for "self"
    def deposit(self, amount: int) -> None:
        self.balance += amount

    def withdraw(self, amount: int) -> None:
        self.balance -= amount

# User-defined classes are valid as types in annotations
account: BankAccount = BankAccount("Alice", 400)
def transfer(src: BankAccount, dst: BankAccount, amount: int) -> None:
    src.withdraw(amount)
    dst.deposit(amount)
```
### Annotated

`Annotated` in python allows developers to declare type of a reference and and also to provide additional information related to it.

```python
name = Annotated[str, "first letter is capital"]
```

This tells that `name` is of type `str` and that `name[0]` is a capital letter.

On its own `Annotated` does not do anything other than assigning extra information (metadata) to a reference. It is up to another code, which can be a library, framework or your own code, to interpret the metadata and make use of it.

For example FastAPI uses Annotated for data validation:
```python
def read_items(q: Annotated[str, Query(max_length=50)])
```
- Here the parameter `q` is of type `str` with a maximum length of 50. 
- This information was communicated to FastAPI (or any other underlying library) using the Annotated keyword.

`Annotated[<type>, <metadata>]`

Here is an example of how you might use `Annotated` to add metadata to type annotations if you were doing range analysis:

```python
@dataclass
class ValueRange:
    lo: int
    hi: int
	
T1 = Annotated[int, ValueRange(-10, 5)]
T2 = Annotated[T1, ValueRange(-20, 3)]
```

## TypeVar

This is a special type for generic types. 

```python
from typing import Sequence, TypeVar, Iterable

T = TypeVar("T")  # `T` is typically used to represent a generic type variable

def batch_iter(data: Sequence[T], size: int) -> Iterable[Sequence[T]]:
    for i in range(0, len(data), size):
        yield data[i:i + size]
```

Since the generic type is used, `batch_iter` function can take any type of `Sequence` type `data`. For instance, `Sequence[int]`, `Sequence[str]`, `Sequence[Person]`

If we use `bound`, then we can restrict the generic type. For example, 
```python
from typing import Sequence, TypeVar, Iterable, Union

T = TypeVar("T", bound=Union[int, str, bytes])

def batch_iter(data: Sequence[T], size: int) -> Iterable[Sequence[T]]:
    for i in range(0, len(data), size):
        yield data[i:i + size]
```

Thus, the following code will show an error as it takes a list of float numbers:
```python
batch_iter([1.1, 1.3, 2.5, 4.2, 5.5], 2)
```

Note that in Python 3.12, generic type hint has been changed

## Reference
- ArjanCodes
- [Type hint cheat sheet](https://mypy.readthedocs.io/en/stable/cheat_sheet_py3.html)

