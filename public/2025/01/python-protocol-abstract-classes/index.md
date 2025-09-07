# Abstract Classes or Protocols


# Introduction 

When it comes to writing clean, maintainable, and scalable Python code, design matters. As your projects grow, you'll often find yourself needing to enforce structure, ensure consistency, and promote reusability. This is where Python's [Abstract Base Classes (ABCs)](https://docs.python.org/3/library/abc.html) and [Protocols](https://www.python.org/dev/peps/pep-0544/) come into play—two powerful features that help you design better software. 

Abstract classes act as **blueprints for other classes, allowing you to define methods that must be implemented by any subclass**. They're typically used for creating a shared foundation while enforcing a specific structure. Protocols, on the other hand, take a more flexible approach. Instead of relying on inheritance, they **let you define interfaces based on behavior**, making them ideal for *duck typing* (or *structural subtyping*) and runtime flexibility.

However, when should you use abstract classes, and when are protocols the better choice? How do these concepts differ, and what problems do they solve? In this blog post, we'll explore these questions in detail. Through clear explanations and practical examples, you'll learn how to leverage abstract classes and protocols to write more elegant and maintainable Python code. Whether you're designing a small script or a large-scale application, these tools will help you take your Python skills to the next level. Let’s dive in!

# What are Abstract Base Classes

An abstract class in Python is a class that cannot be instantiated on its own and is designed to be a blueprint for other classes. It allows you to define methods that must be created within any child classes built from the abstract class. Abstract classes are used primarily in situations where a base class is required to define a common interface for a set of derived classes.

- **Consistency**: Ensures that all subclasses implement certain methods, providing a consistent interface.
- **Documentation**: Serves as a form of documentation by clearly specifying which methods need to be implemented.
- **Design**: Helps in designing a robust architecture by defining a template for subclasses.

## Pure ABCs (ABC as Interface)

The simplest way to use an ABC is as a pure ABC, for example:

```python
from abc import ABC, abstractmethod

class Animal(ABC):
    @abstractmethod
    def walk(self) -> None:
        pass

    @abstractmethod
    def speak(self) -> None:
        pass
```

Here we have defined an ABC `Animal` with two methods: `walk` and `speak`. Note that the way to do this is to subclass `ABC` and to decorate the methods that must be implemented (i.e. part of the "_interface_") with the `@abstractmethod` decorator.

Now we can implement this "**interface**" to create a `Dog`

```python
class Dog(Animal):
    def walk(self) -> None:
        print("This is a dog walking")

    def speak(self) -> None:
        print("Woof!")
```

This works as expected. However, if we forget to implement the `speak` method, Python will raise an error when we try to instantiate the class:
```python
>>> dog = Dog()
TypeError: Can't instantiate abstract class Dog with abstract method speak
```
We can see that we get an error because we haven't implemented the abstract method `speak`. This ensures that all subclasses implement the correct "interface".

## ABCs as a tool for code reuse

Another, and probably more common, use case for **ABCs is for code reuse**. Below is a slightly more realistic example of a base class for a statistical or Machine Learning regression model

```python
from abc import ABC, abstractmethod
from typing import List, TypeVar

import numpy as np

T = TypeVar("T", bound="Model")

class Model(ABC):
    def __init__(self):
        self._is_fitted = False

    def fit(self: T, data: np.ndarray, target: np.ndarray) -> T:
        fitted_model = self._fit(data, target)
        self._is_fitted = True
        return fitted_model

    def predict(self, data: np.ndarray) -> List[float]:
        if not self._is_fitted:
            raise ValueError(f"{self.__class__.__name__} must be fit before calling predict")
        return self._predict(data)

    @property
    def is_fitted(self) -> bool:
        return self._is_fitted

    @abstractmethod
    def _fit(self: T, data: np.ndarray, target: np.ndarray) -> T:
        pass

    @abstractmethod
    def _predict(self, data: np.ndarray) -> List[float]:
        pass
```
In this example, the `Model` class provides a reusable structure for fitting and predicting data, while leaving the implementation of `_fit` and `_predict` to subclasses.

# Protocols

## Dynamic v.s. Static Typing

To better understand protocols, it's important to first grasp the concept of typing in Python. Python is a *dynamically typed language*. What does that mean? In Python, type declarations are not required. For example, you can define a function without specifying the types of its arguments or its return type:
```python
def simple_function(a, b):
    return a + b
```

Types are handled and checked at runtime. You can call `simple_function` with integers, floats, or a mix of both, and the return type will depend on the input:
```python
result = simple_function(2, 8)
# type(result) -> int

result = simple_function(1.4, 9)
# type(result) -> float
```
Compare this to a statically typed language like C, where type declarations are mandatory:
```c
int simple_function(int a, int b) { return a + b; }
```

In C, providing any other type would result in a compilation error. For example, the following code would not compile:
```c
int result = simple_function(2.2, 9); 
```
This highlights a key benefit of statically typed languages: types are checked at compile time, so you're less likely to encounter type-related issues at runtime. In Python, however, you might run into type-related errors at runtime, which could have been caught earlier in a statically typed language.

On the flip side, dynamically typed languages like Python offer greater flexibility when it comes to the types they accept. They also eliminate the need for explicit type declarations, which can be a boon for productivity.

## Duck Typing

Dynamic typing is often referred to as *duck typing*, a concept captured by the saying:

> _If it walks like a duck and it quacks like a duck, then it must be a duck._

In programming terms, this means that if an object behaves like a certain type (i.e., it has the required methods and attributes), it can be treated as that type. Protocols embrace this concept, allowing you to define interfaces based on behavior rather than explicit inheritance.

```python
from typing import Protocol

class Flyer(Protocol):
    def fly(self) -> None:
        ...

def let_it_fly(entity: Flyer) -> None:
    entity.fly()

class Bird:
    def fly(self) -> None:
        print("Bird is flying")

class Airplane:
    def fly(self) -> None:
        print("Airplane is flying")

bird = Bird()
airplane = Airplane()

# Both Bird and Airplane instances can be passed to let_it_fly, thanks to Duck Typing
let_it_fly(bird)      # Output: Bird is flying
let_it_fly(airplane)  # Output: Airplane is flying
```
In this example, both `Bird` and `Airplane` implement the `flay` method, so they can be treated as instances of the `Flyer` protocol. This flexibility is one of the key strengths of duck typing and protocols in Python.

## So ABCs or Protocols?

In summary, here are the best practices for choosing between ABCs and Protocols:
- When to use abstract classes:
    - When you need to **share common implementation code**.
    - When you want to **enforce a strict class hierarchy**.
- When to use protocols:
    - When you **care about behavior, not implementation**.
    - When you want to **avoid tight coupling between classes**.
- Avoid overusing inheritance; prefer composition where possible.


