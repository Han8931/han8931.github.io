# Data validation with Pydantic!


Python's dynamic typing system is indeed convenient, allowing you to create variables without explicitly declaring their types. While this flexibility can streamline development, it can also introduce unexpected behavior, particularly when handling data from external sources like APIs or user input.

Consider the following scenario:
```python
employee = Employee("Han", 30) # Correct
employee = Employee("Moon", "30") # Correct
```
- Here, the second argument is intended to represent an age, typically an integer. However, in the second example, it's a string, potentially leading to errors or unexpected behavior down the line.

To address such issues, Pydantic offers a solution through data validation. Pydantic is a library specifically designed for this purpose, ensuring that the data conforms to pre-defined schemas.

The primary method of defining schemas in Pydantic is through models. Models are essentially classes that inherit from `pydantic.BaseModel` and define fields with annotated attributes. You can think of models as similar to structs in languages like C.

While Pydantic models share similarities with Python's dataclasses, they are preferred when data validation is essential. Pydantic models guarantee that the fields of an instance will adhere to specified types, providing both runtime validation and serving as type hints during development.

Let's illustrate this with a simple example:
```python
from pydantic import BaseModel

class User(BaseModel):
	id: int
	name: str = "John Doe"
```
- `User` model has two fields: `id` integer and `name` string, which has a default value. 
-  You can create an instance, `user = User(id="123")`

You can also define models that include other models, allowing for complex data structures:
```python
from typing import List  

class Item(BaseModel):     
	name: str     
	price: float  

class Order(BaseModel):     
	items: List[Item]     
	total_price: float  
	order = Order(items=[{"name": "Burger", "price": 5.99}, {"name": "Fries", "price": 2.99}], total_price=8.98)  
	print(order)
```

## Validators

Pydantic provides a versatile decorator called `validator`, which enables you to impose custom validation rules on model fields. These validators extend beyond simple type validation and allow you to enforce additional checks. Here's how you can define and utilize a custom validator:
```python
from pydantic import BaseModel, validator

class Person(BaseModel):
    name: str
    age: int

    @validator('age')
    def check_age(cls, value):
        if value < 18:
            raise ValueError('Age must be at least 18')
        return value

# This will raise an error because the age is below 18
try:
    Person(name="Charlie", age=17)
except Exception as e:
    print(e)
```
In this example, the custom validator ensures that the age provided is at least 18 years. Custom validators can target individual fields, multiple fields, or the entire model, making them invaluable for enforcing complex validation logic or cross-field constraints.

### Built-in Validators

Pydantic models leverage Python type annotations to enforce data types. Alongside the fundamental types like `str`, `int`, `float`, `bool`, Pydantic supports complex data types such as `List`, `Dict`, `Union`, and `Optional`, among others. These annotations are the first level of validation:
```python
from pydantic import BaseModel
from typing import List, Optional

class User(BaseModel):
    name: str
    age: int
    tags: Optional[List[str]] = None
```

In this example, `name` must be a string, `age` an integer, and `tags` is an optional list of strings.

### Field Validation

For more detailed validation, Pydantic's `Field` function can be used to specify additional constraints:
```python
from pydantic import BaseModel, Field

class User(BaseModel):
    id: int
    name: str
    email: str = Field(..., description="The email address of the user")
    age: int = Field(..., gt=0, description="The age of the user")

# Usage
user_data = {"id": 1, "name": "John", "email": "john@example.com", "age": 30}
user = User(**user_data)

```

In this example:
- `id`, `name`, `email`, and `age` represents fields in the `User` model.
- `id` and `name` are required fields because they don't have a default value.
- `email` and `age` have default values specified using the `Field` class. For `email`, `...` indicates that it's required, and a description is provided. For `age`, `...` indicates that it's required, and it must be greater than zero (`gt=0`).

By using `Field`, you can define additional constraints such as minimum and maximum values, regular expressions for string fields, custom validation functions, etc., to ensure that your data meets specific criteria.
```python
age: int = Field(..., gt=0, description="The age of the user")
```
For instance, you can specifies that the age must be greater than 0.

### Root Validators

For validation that involves multiple fields, you can use root validators. These are applied to the whole model instead of individual fields:

```python
from pydantic import BaseModel, root_validator

class Account(BaseModel):
    username: str
    password1: str
    password2: str

    @root_validator
    def passwords_match(cls, values):
        password1, password2 = values.get('password1'), values.get('password2')
        if password1 and password2 and password1 != password2:
            raise ValueError('Passwords do not match')
        return values
```

Root validators have access to all field values of the model, making them ideal for validations that depend on multiple fields.

### Pre-Validators and Post-Validators

#### Pre-validators:
A pre-validator in Pydantic is used to preprocess or transform the data before it undergoes the main validation process. This is particularly useful when you need to adjust or prepare the incoming data so it can be successfully validated. For instance, you might want to strip whitespace from a string, convert data types, or decompose compound fields into simpler components before validation.

```python
from pydantic import BaseModel, validator

class TrimmedStringModel(BaseModel):
    text: str

    @validator('text', pre=True)
    def strip_whitespace(cls, value):
        return value.strip()
```

#### Post-validator
Post-validators are used to validate or transform data after the main validation process. They are useful when certain validations depend on multiple fields or when you need to enforce complex constraints that are not covered by basic type annotations. Post-validators are also defined using the `@validator` decorator but without specifying `pre=True`.

## Json Serialization

It is really simple to convert Pydantic models to or from JSON. For example, 
```python
user_json = user.json()
```
- You can convert your model instance to JSON file as above.
- Or you can make a dictionary by `user.dict()`

Conversely, 
```python
json_str = '{"name": "Han", "account": 1234}'
User.parse_raw(json_str)
```

## Pydantic for Config

Pydantic can also be used for settings management by loading configuration from environment variables:

```python
from pydantic_settings import BaseSettings
from pydantic.types import SecretStr

class DatabaseSettings(BaseSettings):
    api_key: str
    database_password: str

my_database_settings = DatabaseSettings(_env_file=".env")
print(my_database_settings.api_key)
```

This feature is particularly useful for 12-factor apps that require configuration through the environment for different deployment environments.

Pydantic provides a powerful system for data validation, allowing you to enforce type constraints and custom validation rules on your data models. This capability ensures that the data your application works with is correct and consistent, reducing runtime errors and simplifying data handling. Let's explore more about validation in Pydantic, including built-in validators and how to write custom validation functions.

### Pydantic SecretStr

Pydantic's `SecretStr` is a special data type designed to handle sensitive information, such as passwords or secret tokens, in a more secure manner. This type is part of Pydantic's data types that provide tools for sensitive data, ensuring that such information isn't accidentally printed or logged, which could lead to security vulnerabilities.

```python
from pydantic import BaseModel, SecretStr

class User(BaseModel):
    username: str
    password: SecretStr

# Usage
user_data = {"username": "john_doe", "password": "secretpassword"}
user = User(**user_data)

print(user)  # Output: User username='john_doe' password=SecretStr('********')
```

```python
from pydantic import BaseModel, SecretBytes

class EncryptedData(BaseModel):
    data: SecretBytes

# Usage
encrypted_data = {"data": b"encrypted binary data"}
data_object = EncryptedData(**encrypted_data)

print(data_object)  # Output: EncryptedData data=SecretBytes('********')
```

```python
from pydantic_settings import BaseSettings
from pydantic.types import SecretStr

class DatabaseSettings(BaseSettings):
    api_key: SecretStr
    database_password: SecretStr

my_database_settings = DatabaseSettings(_env_file=".env")
print(my_database_settings.api_key)
```


